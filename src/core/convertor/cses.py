from pathlib import Path
from typing import Optional

import yaml
from loguru import logger

from src import __CSES_SCHEMA_VERSION__
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


class CSESConverter(BaseConverter):
    """CSES (Common Schedule Exchange Standard) format converter."""

    def __init__(self, data: dict) -> None:
        self.data = data
        self._validate()

    @classmethod
    def from_cses(cls, path: str | Path) -> "CSESConverter":
        try:
            with open(path, "r", encoding="utf-8") as f:
                data = yaml.safe_load(f)
            return cls(data)
        except FileNotFoundError:
            logger.error(f"CSES file not found: {path}")
            raise
        except yaml.YAMLError as e:
            logger.error(f"Failed to parse CSES YAML file: {path}\n{e}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error loading CSES: {e}")
            raise

    def _validate(self) -> None:
        required_keys = {"version", "subjects", "schedules"}
        missing = required_keys - self.data.keys()
        if missing:
            raise ValueError(f"CSES data is missing required keys: {missing}")
        if self.data.get("version") != __CSES_SCHEMA_VERSION__:
            raise ValueError(f"CSES schema version not supported: {self.data.get('version')}")

    def _convert_to_cw2(self) -> ScheduleData:
        cses = self.data

        meta = self._build_meta()

        subjects: list[Subject] = []
        subj_id_map: dict[str, str] = {}
        for subj in cses.get("subjects", []):
            subj_id = generate_id("subj")
            subj_id_map[subj["name"]] = subj_id
            subjects.append(Subject(
                id=subj_id,
                icon="ic_fluent_book_20_regular",
                name=subj.get("name", "Unknown"),
                simplifiedName=subj.get("simplified_name"),
                teacher=subj.get("teacher"),
                location=subj.get("room"),
            ))

        days: list[Timeline] = []
        for sch in cses.get("schedules", []):
            entries: list[Entry] = []
            for cls in sch.get("classes", []):
                subj_id = subj_id_map.get(cls.get("subject"))
                if not subj_id:
                    logger.warning(f"No matching subject for '{cls.get('subject')}', creating temporary subject.")
                    subj_id = generate_id("subj_temp")
                    subjects.append(Subject(id=subj_id, name=cls.get("subject") or "Unknown Subject"))

                entries.append(Entry(
                    id=generate_id("entry"),
                    type=EntryType.CLASS,
                    subjectId=subj_id,
                    startTime=self._to_cw_time(cls.get("start_time")),
                    endTime=self._to_cw_time(cls.get("end_time")),
                ))

            match sch.get("weeks"):
                case "odd":
                    weeks = WeekType.ODD
                case "even":
                    weeks = WeekType.EVEN
                case _:
                    weeks = WeekType.ALL


            days.append(Timeline(
                id=generate_id("day"),
                entries=entries,
                dayOfWeek=[sch.get("enable_day")] if sch.get("enable_day") else None,
                weeks=weeks,
            ))

        return ScheduleData(
            meta=meta,
            subjects=subjects,
            days=days,
            overrides=[],
        )

    def to_cw2(self, output: str | Path) -> Path:
        schedule = self._convert_to_cw2()
        return self._save_cw2_json(schedule, output)
