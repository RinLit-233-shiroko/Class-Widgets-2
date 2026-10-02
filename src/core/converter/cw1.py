from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from src.core.schedule.model import (
    Entry,
    EntryType,
    ScheduleData,
    Subject,
    Timeline,
    Timetable,
    WeekType,
)
from src.core.utils import generate_id, get_random_subject_color

from .common import build_meta, fill_short_breaks, minutes_to_hhmm


class CW1Document(BaseModel):
    part: dict[str, Any]
    part_name: dict[str, Any]
    timeline: dict[str, Any]
    schedule: dict[str, list[str]]
    timeline_even: dict[str, Any] = Field(default_factory=dict)
    schedule_even: dict[str, list[str]] = Field(default_factory=dict)

    model_config = ConfigDict(extra="allow")


def _parse_cw1_part_start(part_unit) -> int:
    if not isinstance(part_unit, (list, tuple)) or len(part_unit) < 2:
        raise ValueError(f"Invalid CW1 part definition: {part_unit}")
    return int(part_unit[0]) * 60 + int(part_unit[1])


def _sort_cw1_legacy_timeline_key(item: tuple[str, object]):
    item_name = item[0]
    prefix = item_name[0]
    if len(item_name) > 1:
        try:
            part_num = int(item_name[1])
            class_num = int(item_name[2:]) if len(item_name) > 2 else 0
            return part_num, class_num, 0 if prefix == "a" else 1
        except ValueError:
            return item_name
    return item_name


def _normalize_cw1_timeline_map(
    timeline_map: dict,
) -> dict[str, list[tuple[int, str, int, int]]]:
    normalized: dict[str, list[tuple[int, str, int, int]]] = {}
    for key, value in timeline_map.items():
        if isinstance(value, dict):
            sorted_items = sorted(value.items(), key=_sort_cw1_legacy_timeline_key)
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


def _is_meaningful_subject_name(subject_name) -> bool:
    if not subject_name:
        return False
    return str(subject_name).strip() not in {"", "未添加"}


def _build_subjects(cw1: dict) -> tuple[list[Subject], dict[str, str]]:
    subject_names: list[str] = []
    seen: set[str] = set()

    for schedule_map_name in ("schedule", "schedule_even"):
        schedule_map = cw1.get(schedule_map_name, {})
        for classes in schedule_map.values():
            if not isinstance(classes, list):
                continue
            for subject_name in classes:
                if not _is_meaningful_subject_name(subject_name):
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
                color=get_random_subject_color(),
                name=subject_name,
            )
        )
    return subjects, subject_id_map


def _build_entries(
    timeline_units: list,
    schedule_names: list[str],
    part_map: dict,
) -> list[Entry]:
    entries: list[Entry] = []
    subject_index = 0
    current_minutes_by_part: dict[str, int] = {}

    for unit in timeline_units:
        if not isinstance(unit, (list, tuple)) or len(unit) != 4:
            raise ValueError(f"Invalid CW1 timeline unit: {unit}")

        unit_type, part_key, _class_index, duration = unit
        part_key = str(part_key)
        duration = int(duration)

        if part_key not in current_minutes_by_part:
            if part_key not in part_map:
                raise ValueError(f"Unknown CW1 part key in timeline: {part_key}")
            current_minutes_by_part[part_key] = _parse_cw1_part_start(
                part_map[part_key]
            )

        start_minutes = current_minutes_by_part[part_key]
        end_minutes = start_minutes + duration
        current_minutes_by_part[part_key] = end_minutes

        entry_type = EntryType.CLASS if int(unit_type) == 0 else EntryType.BREAK
        entry = Entry(
            id=generate_id("entry"),
            type=entry_type,
            startTime=minutes_to_hhmm(start_minutes),
            endTime=minutes_to_hhmm(end_minutes),
        )

        if entry_type == EntryType.CLASS:
            if subject_index < len(schedule_names):
                subject_name = schedule_names[subject_index]
                if _is_meaningful_subject_name(subject_name):
                    entry.title = str(subject_name)
            subject_index += 1

        entries.append(entry)

    return fill_short_breaks(entries)


def _append_timeline_days(  # noqa: PLR0917
    days: list[Timeline],
    overrides: list[dict],
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

        if not any(_is_meaningful_subject_name(name) for name in schedule_names):
            continue

        entries = _build_entries(timeline_units, schedule_names, part_map)
        if not any(entry.type == EntryType.CLASS and entry.title for entry in entries):
            continue

        # CW1 stores course names alongside its time layout.  Convert the
        # layout into a reusable skeleton and put the names in overrides so
        # CW1's even-week variant can share the same slots safely.
        day_of_week = cw1_day + 1
        if weeks == WeekType.ALL:
            skeleton_entries = [entry.model_copy(deep=True) for entry in entries]
            for entry in skeleton_entries:
                if entry.type == EntryType.CLASS:
                    entry.subjectId = None
                    entry.title = None
            days.append(
                Timeline(
                    id=generate_id("day"),
                    entries=skeleton_entries,
                    dayOfWeek=[day_of_week],
                    weeks=WeekType.ALL,
                )
            )
            slots = {
                (entry.startTime, entry.endTime): entry.id
                for entry in skeleton_entries
                if entry.type == EntryType.CLASS
            }
            for source in entries:
                if source.type != EntryType.CLASS or not source.title:
                    continue
                overrides.append(
                    {
                        "entryId": slots[(source.startTime, source.endTime)],
                        "dayOfWeek": [day_of_week],
                        "weeks": WeekType.ALL,
                        "subjectId": subject_id_map.get(source.title),
                        "title": None if subject_id_map.get(source.title) else source.title,
                    }
                )
        else:
            for entry in entries:
                if entry.type != EntryType.CLASS or not entry.title:
                    continue
                entry.subjectId = subject_id_map.get(entry.title)
                if entry.subjectId:
                    entry.title = None
            days.append(
                Timeline(
                    id=generate_id("day"),
                    entries=entries,
                    dayOfWeek=[day_of_week],
                    weeks=weeks,
                )
            )


def to_schedule(document: CW1Document) -> ScheduleData:
    cw1_data = document.model_dump()
    cw1 = {
        **cw1_data,
        "timeline": _normalize_cw1_timeline_map(cw1_data.get("timeline", {})),
        "timeline_even": _normalize_cw1_timeline_map(
            cw1_data.get("timeline_even", {})
        ),
    }

    subjects, subject_id_map = _build_subjects(cw1)
    days: list[Timeline] = []
    overrides = []

    _append_timeline_days(
        days,
        overrides,
        cw1,
        subject_id_map,
        "timeline",
        "schedule",
        WeekType.ALL,
    )

    even_timeline_map = cw1.get("timeline_even", {})
    even_schedule_map = cw1.get("schedule_even", {})
    has_even_timeline = any(
        even_timeline_map.get(key)
        for key in ["default", "0", "1", "2", "3", "4", "5", "6"]
    )
    has_even_schedule = any(
        any(
            _is_meaningful_subject_name(name)
            for name in even_schedule_map.get(str(day), [])
        )
        for day in range(7)
    )
    if has_even_timeline or has_even_schedule:
        _append_timeline_days(
            days,
            overrides,
            cw1,
            subject_id_map,
            "timeline_even",
            "schedule_even",
            WeekType.EVEN,
        )

    # The legacy format has a separate even-week table.  Reuse an all-week
    # slot when its time range is identical; only genuinely new even-week
    # slots remain as an independent Timeline.
    all_days = {
        day.dayOfWeek[0]: day
        for day in days
        if day.weeks == WeekType.ALL and day.dayOfWeek
    }
    retained_days = []
    for day in days:
        if day.weeks != WeekType.EVEN or not day.dayOfWeek:
            retained_days.append(day)
            continue
        base = all_days.get(day.dayOfWeek[0])
        if not base:
            retained_days.append(day)
            continue
        base_slots = {
            (entry.startTime, entry.endTime): entry.id
            for entry in base.entries
            if entry.type == EntryType.CLASS
        }
        remaining = []
        for entry in day.entries:
            slot = (entry.startTime, entry.endTime)
            if entry.type != EntryType.CLASS or slot not in base_slots:
                remaining.append(entry)
                continue
            overrides.append(
                {
                    "entryId": base_slots[slot],
                    "dayOfWeek": day.dayOfWeek,
                    "weeks": WeekType.EVEN,
                    "subjectId": entry.subjectId,
                    "title": entry.title,
                }
            )
        if any(entry.type == EntryType.CLASS for entry in remaining):
            day.entries = remaining
            retained_days.append(day)
    days = retained_days

    return ScheduleData(
        meta=build_meta(),
        subjects=subjects,
        days=days,
        overrides=[Timetable(id=generate_id("override"), **item) for item in overrides],
    )


MODEL = CW1Document
SERIALIZER = "json"
TO_SCHEDULE = to_schedule
