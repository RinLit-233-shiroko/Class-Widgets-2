import json
from collections import defaultdict
from pathlib import Path
from typing import Optional

from PySide6.QtWidgets import QApplication
from loguru import logger

from src import __CSES_SCHEMA_VERSION__, __SCHEDULE_SCHEMA_VERSION__
from src.core.schedule.model import (
    EntryType,
    ScheduleData,
    Subject,
    WeekType,
)

from .base import BaseConverter


class CW2Converter(BaseConverter):
    """Class Widgets 2 native format converter (CW2 <-> CSES)."""

    def __init__(self, data: dict) -> None:
        self.data = data
        self.schedule: Optional[ScheduleData] = None
        self._validate()
        self.schedule = ScheduleData.model_validate(data)

    @classmethod
    def from_cw2(cls, path: str | Path) -> "CW2Converter":
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return cls(data)
        except FileNotFoundError:
            logger.error(f"CW2 file not found: {path}")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse CW2 JSON file: {path}\n{e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error loading CW2: {e}")
            raise

    def _validate(self) -> None:
        if "meta" not in self.data or "version" not in self.data["meta"]:
            raise ValueError("CW2 data missing 'meta' or 'version'")
        if self.data["meta"].get("version") != __SCHEDULE_SCHEMA_VERSION__:
            raise ValueError(f"CW2 schema version not supported: {self.data['meta'].get('version')}")

    def _convert_to_cses(self) -> dict:
        cw2: ScheduleData = self.schedule
        subjects_map = {s.id: s for s in cw2.subjects}

        def _ov_weeks_to_keys(ov_weeks):
            if ov_weeks is None:
                return ["all"]
            if isinstance(ov_weeks, WeekType):
                return [ov_weeks.value]
            if isinstance(ov_weeks, int) and cw2.meta.maxWeekCycle == 2:
                return ["odd"] if ov_weeks == 1 else ["even"]
            return ["all"]


        override_map = defaultdict(list)
        for o in cw2.overrides:
            dows = o.dayOfWeek or [0]
            keys = _ov_weeks_to_keys(o.weeks)
            for dow in dows:
                for k in keys:
                    override_map[(dow, k)].append(o)
        schedules = []

        for day in cw2.days:
            day_dows = day.dayOfWeek or [0]
            day_weeks_str = self._convert_weeks_to_cses(day.weeks, cw2.meta.maxWeekCycle)

            for dow in day_dows:
                base_classes = []
                for entry in day.entries:
                    if entry.type != EntryType.CLASS:
                        continue
                    subj_name = (
                        subjects_map.get(entry.subjectId).name
                        if entry.subjectId and entry.subjectId in subjects_map
                        else QApplication.translate("ScheduleConverter", "Class")
                    )
                    base_classes.append({
                        "subject": subj_name,
                        "start_time": self._to_cses_time(entry.startTime),
                        "end_time": self._to_cses_time(entry.endTime),
                        "entry_id": entry.id,
                    })

                has_per_week_override = bool(
                    ((dow, "odd") in override_map) or ((dow, "even") in override_map)
                )
                if day_weeks_str in ("odd", "even"):
                    week_candidates = [day_weeks_str]
                elif day_weeks_str == "all" and has_per_week_override:
                    week_candidates = ["odd", "even"]
                else:
                    week_candidates = ["all"]

                for week_str in week_candidates:
                    final_classes = [c.copy() for c in base_classes]

                    for cls in final_classes:
                        best_override = None
                        best_priority = -1

                        for week_key in (week_str, "all"):
                            for o in override_map.get((dow, week_key), []):
                                if not (cls["entry_id"] == o.entryId and o.subjectId and o.subjectId in subjects_map):
                                    continue

                                priority = 1 if week_key == week_str else 0
                                if priority > best_priority:
                                    best_override = o
                                    best_priority = priority

                        if best_override:
                            cls["subject"] = subjects_map[best_override.subjectId].name

                    classes_out = [
                        {"subject": c["subject"], "start_time": c["start_time"], "end_time": c["end_time"]}
                        for c in final_classes
                    ]

                    name_label = self.get_localized_week_label(week_str)
                    day_name = f"{self.get_localized_day_name(dow)} - {name_label}"

                    schedules.append({
                        "name": day_name,
                        "enable_day": dow,
                        "weeks": week_str,
                        "classes": classes_out,
                    })

        subjects = []
        for s in cw2.subjects:
            subj_dict = {"name": s.name}
            if s.simplifiedName:
                subj_dict["simplified_name"] = s.simplifiedName
            if s.teacher:
                subj_dict["teacher"] = s.teacher
            if s.location:
                subj_dict["room"] = s.location
            subjects.append(subj_dict)

        return {
            "version": __CSES_SCHEMA_VERSION__,
            "subjects": subjects,
            "schedules": schedules,
        }

    def to_cses(self, output: str | Path) -> Path:
        cses = self._convert_to_cses()
        return self._save_cses_yaml(cses, output)
