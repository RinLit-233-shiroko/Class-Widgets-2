from collections import defaultdict

from pydantic import BaseModel, ConfigDict, Field
from PySide6.QtCore import QLocale
from PySide6.QtWidgets import QApplication

from src import __CSES_SCHEMA_VERSION__
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

from .common import build_meta, fill_short_breaks, to_cw_time


class CSESClass(BaseModel):
    subject: str | None = None
    start_time: str
    end_time: str

    model_config = ConfigDict(extra="allow")


class CSESSchedule(BaseModel):
    name: str = ""
    enable_day: int | None = None
    weeks: str = "all"
    classes: list[CSESClass] = Field(default_factory=list)

    model_config = ConfigDict(extra="allow")


class CSESSubject(BaseModel):
    name: str = "Unknown"
    simplified_name: str | None = None
    teacher: str | None = None
    room: str | None = None

    model_config = ConfigDict(extra="allow")


class CSESDocument(BaseModel):
    version: int
    subjects: list[CSESSubject] = Field(default_factory=list)
    schedules: list[CSESSchedule] = Field(default_factory=list)

    model_config = ConfigDict(extra="allow")


def to_schedule(document: CSESDocument) -> ScheduleData:
    if document.version != __CSES_SCHEMA_VERSION__:
        raise ValueError(f"CSES schema version not supported: {document.version}")

    subjects: list[Subject] = []
    subject_id_map: dict[str, str] = {}
    for item in document.subjects:
        subject_id = generate_id("subj")
        subject_id_map[item.name] = subject_id
        subjects.append(
            Subject(
                id=subject_id,
                icon="ic_fluent_book_20_regular",
                color=get_random_subject_color(),
                name=item.name,
                simplifiedName=item.simplified_name,
                teacher=item.teacher,
                location=item.room,
            )
        )

    days: list[Timeline] = []
    overrides: list[Timetable] = []
    for schedule in document.schedules:
        if not schedule.enable_day:
            continue
        entries: list[Entry] = []
        for item in schedule.classes:
            subject_name = (item.subject or "").strip()
            subject_id = subject_id_map.get(subject_name)

            entries.append(
                Entry(
                    id=generate_id("entry"),
                    type=EntryType.CLASS,
                    subjectId=subject_id,
                    title=None if subject_id else subject_name or None,
                    startTime=to_cw_time(item.start_time),
                    endTime=to_cw_time(item.end_time),
                )
            )

        entries = fill_short_breaks(entries)

        match schedule.weeks:
            case "odd":
                weeks = WeekType.ODD
            case "even":
                weeks = WeekType.EVEN
            case _:
                weeks = WeekType.ALL

        if weeks == WeekType.ALL:
            skeleton = [entry.model_copy(deep=True) for entry in entries]
            slot_ids = {}
            for entry in skeleton:
                if entry.type == EntryType.CLASS:
                    slot_ids[(entry.startTime, entry.endTime)] = entry.id
                    entry.subjectId = None
                    entry.title = None
            days.append(
                Timeline(
                    id=generate_id("day"), entries=skeleton,
                    dayOfWeek=[schedule.enable_day], weeks=WeekType.ALL,
                )
            )
            for entry in entries:
                if entry.type != EntryType.CLASS:
                    continue
                overrides.append(
                    Timetable(
                        id=generate_id("override"),
                        entryId=slot_ids[(entry.startTime, entry.endTime)],
                        dayOfWeek=[schedule.enable_day],
                        weeks=WeekType.ALL,
                        subjectId=entry.subjectId,
                        title=entry.title,
                    )
                )
        else:
            days.append(
                Timeline(
                    id=generate_id("day"), entries=entries,
                    dayOfWeek=[schedule.enable_day], weeks=weeks,
                )
            )

    # Fold odd/even classes into an all-week skeleton when they use the same
    # slot.  A slot that exists only in one parity remains a direct entry in
    # its parity-specific Timeline, avoiding an empty placeholder every week.
    all_days = {
        day.dayOfWeek[0]: day for day in days
        if day.weeks == WeekType.ALL and day.dayOfWeek
    }
    retained: list[Timeline] = []
    for day in days:
        if day.weeks not in (WeekType.ODD, WeekType.EVEN) or not day.dayOfWeek:
            retained.append(day)
            continue
        base = all_days.get(day.dayOfWeek[0])
        if not base:
            retained.append(day)
            continue
        slots = {
            (entry.startTime, entry.endTime): entry.id
            for entry in base.entries if entry.type == EntryType.CLASS
        }
        remaining = []
        for entry in day.entries:
            slot = (entry.startTime, entry.endTime)
            if entry.type != EntryType.CLASS or slot not in slots:
                remaining.append(entry)
                continue
            overrides.append(
                Timetable(
                    id=generate_id("override"), entryId=slots[slot],
                    dayOfWeek=day.dayOfWeek, weeks=day.weeks,
                    subjectId=entry.subjectId, title=entry.title,
                )
            )
        if any(entry.type == EntryType.CLASS for entry in remaining):
            day.entries = remaining
            retained.append(day)
    days = retained

    return ScheduleData(
        meta=build_meta(),
        subjects=subjects,
        days=days,
        overrides=overrides,
    )


def _convert_weeks_to_cses(weeks, max_week_cycle: int | None = None) -> str:
    if isinstance(weeks, WeekType):
        return weeks.value
    if isinstance(weeks, int) and max_week_cycle == 2:
        if weeks == 1:
            return "odd"
        if weeks == 2:
            return "even"
    return "all"


def _to_cses_time(time_str: str) -> str:
    if not time_str:
        raise ValueError(f"Get error type of time: {type(time_str)}; value: {time_str}")
    return f"{time_str}:00"


def _get_localized_day_name(dow: int) -> str:
    locale = QLocale()
    return locale.dayName(dow, QLocale.FormatType.LongFormat)


def _get_localized_week_label(week_str: str) -> str:
    if week_str == "all":
        return QApplication.translate("Schedule", "All Weeks")
    if week_str == "odd":
        return QApplication.translate("Schedule", "Odd Weeks")
    if week_str == "even":
        return QApplication.translate("Schedule", "Even Weeks")
    return week_str


def _ov_weeks_to_keys(ov_weeks, max_week_cycle: int) -> list[str]:
    if ov_weeks is None:
        return ["all"]
    if isinstance(ov_weeks, WeekType):
        return [ov_weeks.value]
    if isinstance(ov_weeks, int) and max_week_cycle == 2:
        return ["odd"] if ov_weeks == 1 else ["even"]
    return ["all"]


def from_schedule(schedule: ScheduleData) -> CSESDocument:
    subjects_map = {subject.id: subject for subject in schedule.subjects}
    override_map = defaultdict(list)

    for override in schedule.overrides:
        dows = override.dayOfWeek or [0]
        keys = _ov_weeks_to_keys(override.weeks, schedule.meta.maxWeekCycle)
        for dow in dows:
            for key in keys:
                override_map[(dow, key)].append(override)

    output_schedules: list[CSESSchedule] = []
    for day in schedule.days:
        day_dows = day.dayOfWeek or [0]
        day_weeks_str = _convert_weeks_to_cses(
            day.weeks, schedule.meta.maxWeekCycle
        )

        for dow in day_dows:
            base_classes = []
            for entry in day.entries:
                if entry.type != EntryType.CLASS:
                    continue
                subject_name = (
                    subjects_map.get(entry.subjectId).name
                    if entry.subjectId and entry.subjectId in subjects_map
                    else entry.title or ""
                )
                base_classes.append(
                    {
                        "subject": subject_name,
                        "start_time": _to_cses_time(entry.startTime),
                        "end_time": _to_cses_time(entry.endTime),
                        "entry_id": entry.id,
                    }
                )

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
                final_classes = [item.copy() for item in base_classes]

                for item in final_classes:
                    best_override = None
                    best_priority = -1

                    for week_key in (week_str, "all"):
                        for override in override_map.get((dow, week_key), []):
                            if not (
                                item["entry_id"] == override.entryId
                                and (
                                    (override.subjectId and override.subjectId in subjects_map)
                                    or override.title
                                )
                            ):
                                continue
                            priority = 1 if week_key == week_str else 0
                            if priority > best_priority:
                                best_override = override
                                best_priority = priority

                    if best_override:
                        if best_override.subjectId in subjects_map:
                            item["subject"] = subjects_map[best_override.subjectId].name
                        elif best_override.title:
                            item["subject"] = best_override.title
                        if best_override.startTime and best_override.endTime:
                            item["start_time"] = _to_cses_time(best_override.startTime)
                            item["end_time"] = _to_cses_time(best_override.endTime)

                classes = [
                    CSESClass(
                        subject=item["subject"],
                        start_time=item["start_time"],
                        end_time=item["end_time"],
                    )
                    for item in final_classes
                ]
                name_label = _get_localized_week_label(week_str)
                output_schedules.append(
                    CSESSchedule(
                        name=f"{_get_localized_day_name(dow)} - {name_label}",
                        enable_day=dow,
                        weeks=week_str,
                        classes=classes,
                    )
                )

    output_subjects = [
        CSESSubject(
            name=subject.name,
            simplified_name=subject.simplifiedName,
            teacher=subject.teacher,
            room=subject.location,
        )
        for subject in schedule.subjects
    ]

    return CSESDocument(
        version=__CSES_SCHEMA_VERSION__,
        subjects=output_subjects,
        schedules=output_schedules,
    )


MODEL = CSESDocument
SERIALIZER = "yaml"
TO_SCHEDULE = to_schedule
FROM_SCHEDULE = from_schedule
