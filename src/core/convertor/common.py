import json
from datetime import date, datetime
from itertools import pairwise
from pathlib import Path
from typing import Any

import yaml
from pydantic import BaseModel

from src import __SCHEDULE_SCHEMA_VERSION__
from src.core.schedule.model import Entry, EntryType, MetaInfo
from src.core.utils import generate_id


def load_json(path: str | Path) -> Any:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def dump_json(document: Any, output: str | Path) -> Path:
    output = Path(output)
    with open(output, "w", encoding="utf-8") as f:
        json.dump(document, f, ensure_ascii=False, indent=2)
    return output


def load_yaml(path: str | Path) -> Any:
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


def dump_yaml(document: Any, output: str | Path) -> Path:
    output = Path(output)
    with open(output, "w", encoding="utf-8") as f:
        yaml.safe_dump(document, f, allow_unicode=True, sort_keys=False)
    return output


LOADERS = {
    "json": load_json,
    "yaml": load_yaml,
}

DUMPERS = {
    "json": dump_json,
    "yaml": dump_yaml,
}


def auto_map(source: Any, target_model: type[BaseModel]) -> BaseModel:
    """Convert between structurally compatible Pydantic models."""
    if isinstance(source, target_model):
        return source
    data = source.model_dump(mode="json") if isinstance(source, BaseModel) else source
    return target_model.model_validate(data)


def build_meta(
    start_date: str | date | datetime | None = None,
    max_week_cycle: int = 2,
) -> MetaInfo:
    """Build the common CW2 metadata block for imported schedules."""
    if start_date is None:
        resolved_start = date.today()
    elif isinstance(start_date, datetime):
        resolved_start = start_date.date()
    elif isinstance(start_date, date):
        resolved_start = start_date
    else:
        resolved_start = datetime.strptime(start_date, "%Y-%m-%d").date()

    return MetaInfo(
        id=generate_id("meta"),
        version=__SCHEDULE_SCHEMA_VERSION__,
        maxWeekCycle=max_week_cycle,
        startDate=resolved_start.isoformat(),
    )


def to_cw_time(time: str | int) -> str:
    """Normalize supported source time values to CW2 HH:MM."""
    if isinstance(time, str):
        parsed = datetime.strptime(time, "%H:%M:%S")
    elif isinstance(time, int):
        hours = time // 3600
        minutes = time // 60 % 60
        seconds = time % 60
        parsed = datetime.strptime(f"{hours}:{minutes}:{seconds}", "%H:%M:%S")
    else:
        raise ValueError(f"Get error type of time: {type(time)}; value: {time}")
    return parsed.strftime("%H:%M")


def minutes_to_hhmm(total_minutes: int) -> str:
    hours = total_minutes // 60
    minutes = total_minutes % 60
    return f"{hours:02d}:{minutes:02d}"


def _time_to_minutes(value: str) -> int:
    parsed = datetime.strptime(value, "%H:%M")
    return parsed.hour * 60 + parsed.minute


def fill_short_breaks(entries: list[Entry], max_gap_minutes: int = 30) -> list[Entry]:
    """Insert break entries for positive class gaps up to the given duration."""
    class_entries = sorted(
        (entry for entry in entries if entry.type == EntryType.CLASS),
        key=lambda entry: entry.startTime,
    )
    blocking_entries = [
        entry for entry in entries if entry.type != EntryType.CLASS
    ]
    result = list(entries)

    for previous, current in pairwise(class_entries):
        gap_start = _time_to_minutes(previous.endTime)
        gap_end = _time_to_minutes(current.startTime)
        gap_minutes = gap_end - gap_start

        if gap_minutes <= 0 or gap_minutes > max_gap_minutes:
            continue

        has_blocker = any(
            _time_to_minutes(entry.startTime) < gap_end
            and _time_to_minutes(entry.endTime) > gap_start
            for entry in blocking_entries
        )
        if has_blocker:
            continue

        result.append(
            Entry(
                id=generate_id("entry"),
                type=EntryType.BREAK,
                startTime=minutes_to_hhmm(gap_start),
                endTime=minutes_to_hhmm(gap_end),
            )
        )

    return sorted(result, key=lambda entry: entry.startTime)

