import json
from pydantic import BaseModel, field_validator
from typing import Optional
from enum import Enum

from src import __SCHEDULE_SCHEMA_VERSION__


class EntryType(str, Enum):
    CLASS = "class"
    BREAK = "break"
    ACTIVITY = "activity"
    FREE = "free"
    PREPARATION = "preparation"


class WeekType(str, Enum):
    ALL = "all"
    ODD = "odd"
    EVEN = "even"


WeekRule = WeekType | list[int] | int


def _week_list(values) -> list[int]:
    result: list[int] = []
    for item in values:
        if isinstance(item, bool):
            continue
        try:
            number = int(item)
        except (TypeError, ValueError):
            continue
        if number >= 1 and number not in result:
            result.append(number)
    result.sort()
    return result


def normalize_week_rule(value) -> Optional[WeekRule]:
    """Normalize the four supported week-rule forms.

    ``all`` / ``odd`` / ``even`` are explicit enum rules, an integer means the
    numbered week inside ``meta.maxWeekCycle``, and a list means absolute week
    numbers from the semester start.
    """
    if value is None:
        return None
    if isinstance(value, WeekType):
        return value
    if isinstance(value, bool):
        return None
    if isinstance(value, int):
        return value if value >= 1 else None
    if isinstance(value, float):
        if value.is_integer() and value >= 1:
            return int(value)
        return None
    if isinstance(value, str):
        text = value.strip().lower()
        if text in {item.value for item in WeekType}:
            return WeekType(text)
        # A list that travelled through a QML string conversion arrives as
        # "1,4" rather than "[1,4]"; accept both so the rule survives.
        if text.startswith("["):
            try:
                parsed = json.loads(text)
            except ValueError:
                return None
            return _week_list(parsed) if isinstance(parsed, list) else None
        if "," in text:
            parts = [item.strip() for item in text.split(",")]
            weeks = _week_list(parts)
            if len(weeks) == len(parts):
                return weeks
        try:
            number = int(text)
        except ValueError:
            return None
        return number if number >= 1 else None
    if isinstance(value, (list, tuple)):
        return _week_list(value)
    return None


def week_rules_equal(left, right) -> bool:
    """Compare two week rules semantically.

    ``None`` and ``WeekType.ALL`` both mean "no restriction", so they must be
    interchangeable when looking up an existing record. Lists compare as sorted
    sets of absolute weeks, and any other form compares by value.
    """
    first = normalize_week_rule(left)
    second = normalize_week_rule(right)
    if first is None:
        first = WeekType.ALL
    if second is None:
        second = WeekType.ALL
    if isinstance(first, list) or isinstance(second, list):
        return (
            isinstance(first, list)
            and isinstance(second, list)
            and first == second
        )
    return first == second


def week_rule_kind(weeks) -> str:
    """Classify a week rule.

    Returns ``"all"``, ``"odd"``, ``"even"``, ``"cycle"`` (a position inside
    ``meta.maxWeekCycle``), ``"specific"`` (absolute semester weeks) or
    ``"invalid"`` for a present-but-unusable value.

    ``None`` means "no restriction at all", which is exactly ``"all"``: that is
    how :func:`week_rule_matches` and the editor read it, so it is not reported
    as a separate state. An empty specific list is still ``"specific"``: it
    matches no week and must never be mistaken for "every week".

    ``WeekRule.js`` in the editor mirrors this classification for QML bindings.
    """
    if weeks is None:
        return "all"
    rule = normalize_week_rule(weeks)
    if rule is None:
        return "invalid"
    if rule == WeekType.ALL:
        return "all"
    if rule == WeekType.ODD:
        return "odd"
    if rule == WeekType.EVEN:
        return "even"
    return "specific" if isinstance(rule, list) else "cycle"


def cycle_week_for(absolute_week: int, max_week_cycle: int) -> int:
    """Return the 1-based cycle position for an absolute semester week."""
    cycle = max(1, int(max_week_cycle))
    if absolute_week >= 1:
        return ((absolute_week - 1) % cycle) + 1
    return (absolute_week % cycle) + 1


def week_rule_matches(weeks, absolute_week: int, max_week_cycle: int = 1) -> bool:
    """Return whether a week rule contains an absolute semester week.

    Integer rules refer to the cycle position; list rules refer to absolute
    semester weeks. Odd/even rules always use the absolute week parity so they
    remain unambiguous when the configured cycle is not 2.
    """
    if weeks is None:
        return True

    rule = normalize_week_rule(weeks)
    if rule is None:
        return False
    if rule == WeekType.ALL:
        return True
    if rule == WeekType.ODD:
        return absolute_week % 2 == 1
    if rule == WeekType.EVEN:
        return absolute_week % 2 == 0
    if isinstance(rule, int):
        return cycle_week_for(absolute_week, max_week_cycle) == rule
    if isinstance(rule, list):
        return absolute_week in rule
    return False


class Subject(BaseModel):
    id: str
    name: str
    simplifiedName: Optional[str] = None
    teacher: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    location: Optional[str] = None
    isLocalClassroom: bool = True


class Entry(BaseModel):
    id: str
    type: EntryType
    startTime: str
    endTime: str
    subjectId: Optional[str] = None
    title: Optional[str] = None


class Timeline(BaseModel):
    id: str
    entries: list[Entry]
    dayOfWeek: Optional[list[int]] = None  # 1~7
    weeks: Optional[WeekRule] = None  # all/odd/even, cycle number, or absolute weeks
    date: Optional[str] = None

    @field_validator("weeks", mode="before")
    @classmethod
    def _normalize_weeks(cls, value):
        return normalize_week_rule(value)


class MetaInfo(BaseModel):
    id: str
    version: int = __SCHEDULE_SCHEMA_VERSION__
    maxWeekCycle: int
    startDate: str  # yyyy-mm-dd


class Timetable(BaseModel):  # 覆盖Entry信息以方便设置课表
    id: str
    entryId: str
    dayOfWeek: Optional[list[int]] = None  # 1~7
    weeks: Optional[WeekRule] = None  # all/odd/even, cycle number, or absolute weeks
    subjectId: Optional[str] = None
    title: Optional[str] = None
    startTime: Optional[str] = None
    endTime: Optional[str] = None

    @field_validator("weeks", mode="before")
    @classmethod
    def _normalize_weeks(cls, value):
        return normalize_week_rule(value)


class ScheduleData(BaseModel):
    meta: MetaInfo
    subjects: list[Subject] = []
    days: list[Timeline] = []
    overrides: list[Timetable] = []
