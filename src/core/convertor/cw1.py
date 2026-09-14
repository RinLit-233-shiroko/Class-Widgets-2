import json
from pathlib import Path

from loguru import logger

from src.core.schedule.model import (
    Entry,
    EntryType,
    ScheduleData,
    Subject,
    Timeline,
    WeekType,
)
from src.core.utils import generate_id

from .base import BaseConverter


class CW1Converter(BaseConverter):
    """Class Widgets 1 format converter."""

    def __init__(self, data: dict) -> None:
        self.data = data
        self._validate()

    @classmethod
    def from_cw1(cls, path: str | Path) -> "CW1Converter":
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return cls(data)
        except FileNotFoundError:
            logger.error(f"CW1 file not found: {path}")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse CW1 JSON file: {path}\n{e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error loading CW1: {e}")
            raise

    def _validate(self) -> None:
        required_keys = {"part", "part_name", "timeline", "schedule"}
        missing = required_keys - self.data.keys()
        if missing:
            raise ValueError(f"CW1 data is missing required keys: {missing}")

    # ---------------------------
    # CW1-specific helpers
    # ---------------------------

    @staticmethod
    def _parse_cw1_part_start(part_unit) -> int:
        if not isinstance(part_unit, (list, tuple)) or len(part_unit) < 2:
            raise ValueError(f"Invalid CW1 part definition: {part_unit}")
        return int(part_unit[0]) * 60 + int(part_unit[1])

    @staticmethod
    def _sort_cw1_legacy_timeline_key(item: tuple[str, object]):
        item_name = item[0]
        prefix = item_name[0]
        if len(item_name) > 1:
            try:
                part_num = int(item_name[1])
                class_num = 0
                if len(item_name) > 2:
                    class_num = int(item_name[2:])
                if prefix == "a":
                    return part_num, class_num, 0
                return part_num, class_num, 1
            except ValueError:
                return item_name
        return item_name

    def _normalize_cw1_timeline_map(self, timeline_map: dict) -> dict[str, list[tuple[int, str, int, int]]]:
        normalized: dict[str, list[tuple[int, str, int, int]]] = {}
        for key, value in timeline_map.items():
            if isinstance(value, dict):
                sorted_items = sorted(value.items(), key=self._sort_cw1_legacy_timeline_key)
                normalized[key] = [
                    (
                        1 if item_name[0] == "f" else 0,
                        str(item_name[1]),
                        int(item_name[2:]) if len(item_name) > 2 else 0,
                        int(item_time),
                    )
                    for item_name, item_time in sorted_items
                ]
            elif isinstance(value, list):
                normalized[key] = [
                    (
                        int(unit[0]),
                        str(unit[1]),
                        int(unit[2]),
                        int(unit[3]),
                    )
                    for unit in value
                ]
            else:
                raise ValueError(f"invalid CW1 timeline format: {key}: {value}")
        return normalized

    def _build_cw1_subjects(self, cw1: dict) -> tuple[list[Subject], dict[str, str]]:
        subject_names: list[str] = []
        seen: set[str] = set()

        for schedule_map_name in ("schedule", "schedule_even"):
            schedule_map = cw1.get(schedule_map_name, {})
            for classes in schedule_map.values():
                if not isinstance(classes, list):
                    continue
                for subject_name in classes:
                    if not self._is_meaningful_cw1_subject_name(subject_name):
                        continue
                    if subject_name in seen:
                        continue
                    seen.add(subject_name)
                    subject_names.append(str(subject_name))

        subjects: list[Subject] = []
        subject_id_map: dict[str, str] = {}
        for subject_name in subject_names:
            subject_id = generate_id("subj")
            subject_id_map[subject_name] = subject_id
            subjects.append(
                Subject(
                    id=subject_id,
                    icon="ic_fluent_book_20_regular",
                    name=subject_name,
                )
            )
        return subjects, subject_id_map

    @staticmethod
    def _is_meaningful_cw1_subject_name(subject_name) -> bool:
        if not subject_name:
            return False
        value = str(subject_name).strip()
        return value not in {"", "未添加"}

    def _build_cw1_entries(self, timeline_units: list, schedule_names: list[str], part_map: dict) -> list[Entry]:
        entries: list[Entry] = []
        subject_index = 0
        current_minutes_by_part: dict[str, int] = {}

        for unit in timeline_units:
            if not isinstance(unit, (list, tuple)) or len(unit) != 4:
                raise ValueError(f"Invalid CW1 timeline unit: {unit}")

            unit_type, part_key, class_index, duration = unit
            part_key = str(part_key)
            duration = int(duration)

            if part_key not in current_minutes_by_part:
                if part_key not in part_map:
                    raise ValueError(f"Unknown CW1 part key in timeline: {part_key}")
                current_minutes_by_part[part_key] = self._parse_cw1_part_start(part_map[part_key])

            start_minutes = current_minutes_by_part[part_key]
            end_minutes = start_minutes + duration
            current_minutes_by_part[part_key] = end_minutes

            entry_type = EntryType.CLASS if int(unit_type) == 0 else EntryType.BREAK
            entry = Entry(
                id=generate_id("entry"),
                type=entry_type,
                startTime=self._minutes_to_hhmm(start_minutes),
                endTime=self._minutes_to_hhmm(end_minutes),
            )

            if entry_type == EntryType.CLASS:
                if subject_index < len(schedule_names):
                    subject_name = schedule_names[subject_index]
                    if self._is_meaningful_cw1_subject_name(subject_name):
                        entry.title = str(subject_name)
                subject_index += 1

            entries.append(entry)

        return entries

    def _append_cw1_timeline_days(
        self,
        days: list[Timeline],
        cw1: dict,
        subject_id_map: dict[str, str],
        timeline_key: str,
        schedule_key: str,
        weeks,
    ) -> None:
        part_map = cw1.get("part", {})
        timeline_map = cw1.get(timeline_key, {})
        schedule_map = cw1.get(schedule_key, {})
        default_timeline = timeline_map.get("default", [])

        for cw1_day in range(7):
            day_key = str(cw1_day)
            timeline_units = timeline_map.get(day_key) or default_timeline
            schedule_names = schedule_map.get(day_key, [])

            if not any(self._is_meaningful_cw1_subject_name(name) for name in schedule_names):
                continue

            entries = self._build_cw1_entries(timeline_units, schedule_names, part_map)
            if not any(entry.type == EntryType.CLASS and entry.title for entry in entries):
                continue

            for entry in entries:
                if entry.type == EntryType.CLASS and entry.title:
                    subject_id = subject_id_map.get(entry.title)
                    if subject_id:
                        entry.subjectId = subject_id
                        entry.title = None

            days.append(
                Timeline(
                    id=generate_id("day"),
                    entries=entries,
                    dayOfWeek=[cw1_day + 1],
                    weeks=weeks,
                )
            )

    def _convert_to_cw2(self) -> ScheduleData:
        cw1 = {
            **self.data,
            "timeline": self._normalize_cw1_timeline_map(self.data.get("timeline", {})),
            "timeline_even": self._normalize_cw1_timeline_map(self.data.get("timeline_even", {})),
        }

        meta = self._build_meta()

        subjects, subject_id_map = self._build_cw1_subjects(cw1)
        days: list[Timeline] = []

        self._append_cw1_timeline_days(days, cw1, subject_id_map, "timeline", "schedule", WeekType.ALL)

        even_timeline_map = cw1.get("timeline_even", {})
        even_schedule_map = cw1.get("schedule_even", {})
        has_even_timeline = any(
            even_timeline_map.get(key)
            for key in ["default", "0", "1", "2", "3", "4", "5", "6"]
        )
        has_even_schedule = any(
            any(self._is_meaningful_cw1_subject_name(name) for name in even_schedule_map.get(str(day), []))
            for day in range(7)
        )
        if has_even_timeline or has_even_schedule:
            self._append_cw1_timeline_days(days, cw1, subject_id_map, "timeline_even", "schedule_even", WeekType.EVEN)

        return ScheduleData(
            meta=meta,
            subjects=subjects,
            days=days,
            overrides=[],
        )

    def to_cw2(self, output: str | Path) -> Path:
        schedule = self._convert_to_cw2()
        return self._save_cw2_json(schedule, output)
