from pydantic import BaseModel
from typing import Optional, List, Union
from enum import Enum

from class_widgets_2 import __SCHEDULE_SCHEMA_VERSION__


class EntryType(str, Enum):
    CLASS = "class"
    BREAK = "break"
    ACTIVITY = "activity"
    FREE = "free"
    PREPARATION = "preparation"


class WeekType(str, Enum):
    ALL = "all"


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
    entries: List[Entry]
    dayOfWeek: Optional[List[int]] = None  # 1~7
    weeks: Union[WeekType, List[int], int, None] = None  # all, custom, round
    date: Optional[str] = None


class MetaInfo(BaseModel):
    id: str
    version: int = __SCHEDULE_SCHEMA_VERSION__
    maxWeekCycle: int
    startDate: str  # yyyy-mm-dd


class Timetable(BaseModel):  # 覆盖Entry信息以方便设置课表
    id: str
    entryId: str
    dayOfWeek: Optional[List[int]] = None  # 1~7
    weeks: Union[WeekType, List[int], int, None] = None  # all, custom, round
    subjectId: Optional[str] = None
    title: Optional[str] = None


class ScheduleData(BaseModel):
    meta: MetaInfo
    subjects: List[Subject] = []
    days: List[Timeline] = []
    overrides: List[Timetable] = []
