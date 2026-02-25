import json
from pathlib import Path
from typing import Union, Optional

from class_widgets_2.core.schedule.model import ScheduleData
from class_widgets_2.core.utils.json_loader import JsonLoader
from class_widgets_2 import __SCHEDULE_SCHEMA_VERSION__


class ScheduleParser:
    def __init__(self, path: Union[Path, str]):
        self.path = path
        self.loader = JsonLoader(self.path)
        self.schedule: Optional[ScheduleData] = None
        self.schedule_dict: Optional[dict] = None

    @staticmethod
    def validate(data: dict) -> bool:
        return (
            isinstance(data, dict)
            and "meta" in data
            and isinstance(data["meta"], dict)
            and "version" in data["meta"]
            and "startDate" in data["meta"]
        )

    def load(self) -> ScheduleData:
        try:
            data = self.loader.load()
        except FileNotFoundError:
            raise FileNotFoundError("Schedule File not found")
        except json.decoder.JSONDecodeError as e:
            raise json.decoder.JSONDecodeError(f"JSON Decode Error: {e}", e.doc, e.pos)
        except Exception as e:
            raise ValueError(f"Unexpected error: {e}")

        if not self.validate(data):
            raise ValueError("Invalid Schedule File")

        schedule = ScheduleData.model_validate(data)

        if schedule.meta.version != __SCHEDULE_SCHEMA_VERSION__:
            raise ValueError(f"Unsupported schema version: {schedule.meta.version}")

        self.schedule = schedule
        self.schedule_dict = schedule.model_dump()
        return self.schedule
