import json
from collections import defaultdict

import yaml
from pathlib import Path
from datetime import date, datetime
from typing import Union

from PySide6.QtCore import QLocale
from PySide6.QtWidgets import QApplication
from loguru import logger

from class_widgets_2 import __SCHEDULE_SCHEMA_VERSION__, __CSES_SCHEMA_VERSION__
from class_widgets_2.core.schedule.model import (
    ScheduleData,
    MetaInfo,
    Subject,
    Timeline,
    Entry,
    EntryType, WeekType,
)
from class_widgets_2.core.utils import generate_id


class ScheduleConverter:
    """
    Universal timetable converter (with validation)
    """

    def __init__(self, data: dict, source_format: str):
        self.data = data
        self.source_format = source_format  # 'cses' or 'cw2'
        self.schedule: ScheduleData | None = None

        self._validate()  # run validation

        if source_format == "cw2":
            self.schedule = ScheduleData.model_validate(data)

    @staticmethod
    def _convert_weeks_to_cses(weeks) -> str:
        if isinstance(weeks, WeekType):
            return weeks.value
        elif isinstance(weeks, int):
            if weeks % 2 == 1:
                return "odd"
            elif weeks % 2 == 0:
                return "even"
            else:
                return "all"
        else:
            return "all"

    @staticmethod
    def get_localized_day_name(dow: int) -> str:
        locale = QLocale()
        return locale.dayName(dow, QLocale.FormatType.LongFormat)

    @staticmethod
    def get_localized_week_label(week_str: str) -> str:
        if week_str == "all":
            return QApplication.translate("Schedule", "All Weeks")
        elif week_str == "odd":
            return QApplication.translate("Schedule", "Odd Weeks")
        elif week_str == "even":
            return QApplication.translate("Schedule", "Even Weeks")
        else:
            return week_str

    # Factory Methods
    @classmethod
    def from_cses(cls, path: Union[str, Path]) -> "ScheduleConverter":
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
            return cls(data, "cses")
        except FileNotFoundError:
            logger.error(f"CSES file not found: {path}")
            raise
        except yaml.YAMLError as e:
            logger.error(f"Failed to parse CSES YAML file: {path}\n{e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error loading CSES: {e}")
            raise

    @classmethod
    def from_cw2(cls, path: Union[str, Path]) -> "ScheduleConverter":
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return cls(data, "cw2")
        except FileNotFoundError:
            logger.error(f"CW2 file not found: {path}")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse CW2 JSON file: {path}\n{e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error loading CW2: {e}")
            raise


    # ---------------------------
    # Validation
    # ---------------------------
    def _validate(self):
        if self.source_format == "cses":
            required_keys = {"version", "subjects", "schedules"}
            missing = required_keys - self.data.keys()
            if missing:
                raise ValueError(f"CSES data is missing required keys: {missing}")
            if self.data.get("version") != __CSES_SCHEMA_VERSION__:
                raise ValueError(f"CSES schema version not supported: {self.data.get('version')}")
        elif self.source_format == "cw2":
            if "meta" not in self.data or "version" not in self.data["meta"]:
                raise ValueError("CW2 data missing 'meta' or 'version'")
            if self.data["meta"].get("version") != __SCHEDULE_SCHEMA_VERSION__:
                raise ValueError(f"CW2 schema version not supported: {self.data['meta'].get('version')}")

    @staticmethod
    def _to_cses_time(time_str: str) -> str:
        """统一时间为字符串，避免 YAML 解析问题"""
        if not time_str:
            raise ValueError(f'Get error type of time: {type(time_str)}; value: {time_str}')

        return str(time_str + ":00")

    @staticmethod
    def _to_cw_time(time: Union[str, int]) -> str:
        """统一时间为字符串，避免 YAML 解析问题"""
        # parse
        if isinstance(time, str):
            dt_time = datetime.strptime(str(time), '%H:%M:%S')
        elif isinstance(time, int):
            dt_time = datetime.strptime(f'{int(time / 60 / 60)}:{int(time / 60 % 60)}:{time % 60}', '%H:%M:%S')
        else:
            raise ValueError(f'Get error type of time: {type(time)}; value: {time}')

        return dt_time.strftime("%H:%M")

    # CSES → CW2
    def _convert_cses_to_cw2(self) -> ScheduleData:
        cses = self.data

        meta = MetaInfo(
            id=generate_id("meta"),
            version=__SCHEDULE_SCHEMA_VERSION__,
            maxWeekCycle=2,
            startDate=str(date.today())
        )

        subjects = []
        subj_id_map = {}
        for subj in cses.get("subjects", []):
            subj_id = generate_id("subj")
            subj_id_map[subj["name"]] = subj_id  # 建立 name→id 映射
            subjects.append(Subject(
                id=subj_id,
                icon="ic_fluent_book_20_regular",
                name=subj.get("name", "Unknown"),
                simplifiedName=subj.get("simplified_name"),
                teacher=subj.get("teacher"),
                location=subj.get("room")
            ))

        days = []
        for sch in cses.get("schedules", []):
            day_id = generate_id("day")
            entries = []
            for cls in sch.get("classes", []):
                subj_id = subj_id_map.get(cls.get("subject"))
                if not subj_id:
                    logger.warning(f"No matching subject for '{cls.get('subject')}', creating temporary subject.")
                    subj_id = generate_id("subj_temp")
                    subjects.append(Subject(id=subj_id, name=cls.get("subject") or "Unknown Subject"))
                entry_id = generate_id("entry")

                entries.append(Entry(
                    id=entry_id,
                    type=EntryType.CLASS,
                    subjectId=subj_id,
                    startTime=self._to_cw_time(cls.get("start_time")),
                    endTime=self._to_cw_time(cls.get("end_time")),
                ))

            match sch.get("weeks"):
                case "odd":
                    weeks = 1
                case "even":
                    weeks = 2
                case _:
                    weeks = WeekType.ALL

            days.append(Timeline(
                id=day_id,
                entries=entries,
                dayOfWeek=[sch.get("enable_day")] if sch.get("enable_day") else None,
                weeks=weeks
            ))

        return ScheduleData(
            meta=meta,
            subjects=subjects,
            days=days,
            overrides=[]
        )

    # CW2 → CSES
    def _convert_cw2_to_cses(self) -> dict:
        cw2: ScheduleData = self.schedule
        subjects_map = {s.id: s for s in cw2.subjects}

        # build override map keyed by (dow, week_str)
        def _ov_weeks_to_keys(ov_weeks):
            if ov_weeks is None:
                return ["all"]
            if isinstance(ov_weeks, WeekType):
                return [ov_weeks.value]
            if isinstance(ov_weeks, int):
                return ["odd"] if ov_weeks % 2 == 1 else ["even"]
            if isinstance(ov_weeks, list):
                if all((w % 2 == 1) for w in ov_weeks):
                    return ["odd"]
                if all((w % 2 == 0) for w in ov_weeks):
                    return ["even"]
                return ["all"]
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
            day_weeks_str = self._convert_weeks_to_cses(day.weeks)

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
                        "entry_id": entry.id
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

                    # build final classes array
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
                        "classes": classes_out
                    })

        # subjects
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
            "schedules": schedules
        }

    # Export
    def to_cw2(self, output: Union[str, Path]) -> Path:
        if self.source_format != "cses":
            raise ValueError("Current data is not in CSES format, cannot export to CW2.")
        output = Path(output)
        try:
            schedule = self._convert_cses_to_cw2()
            with open(output, "w", encoding="utf-8") as f:
                json.dump(schedule.model_dump(), f, ensure_ascii=False, indent=2)
            logger.info(f"Converted to CW2 JSON: {output}")
            return output
        except Exception as e:
            logger.error(f"Failed to export to CW2: {e}")
            raise

    def to_cses(self, output: Union[str, Path]) -> Path:
        if self.source_format != "cw2":
            raise ValueError("Current data is not in CW2 format, cannot export to CSES.")
        output = Path(output)
        try:
            cses = self._convert_cw2_to_cses()
            with open(output, "w", encoding="utf-8") as f:
                yaml.safe_dump(cses, f, allow_unicode=True, sort_keys=False)
            logger.info(f"Converted to CSES YAML: {output}")
            return output
        except Exception as e:
            logger.error(f"Failed to export to CSES: {e}")
            raise


if __name__ == "__main__":
    from class_widgets_2.core.directories import SCHEDULES_PATH
    ScheduleConverter.from_cw2(Path(SCHEDULES_PATH / "default.json")).to_cses(Path(SCHEDULES_PATH / "New Schedule 1.yaml"))
    # ScheduleConverter.from_cses(Path(SCHEDULES_PATH / "New Schedule 1.yaml")).to_cw2(Path(SCHEDULES_PATH / "New Schedule 1w.json"))

