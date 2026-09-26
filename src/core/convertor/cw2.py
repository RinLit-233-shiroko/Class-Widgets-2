from src import __SCHEDULE_SCHEMA_VERSION__
from src.core.schedule.model import ScheduleData

MODEL = ScheduleData
SERIALIZER = "json"


def to_schedule(document: ScheduleData) -> ScheduleData:
    if document.meta.version != __SCHEDULE_SCHEMA_VERSION__:
        raise ValueError(
            f"CW2 schema version not supported: {document.meta.version}"
        )
    return document


TO_SCHEDULE = to_schedule
