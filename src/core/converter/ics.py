from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from math import lcm
from pathlib import Path
from typing import Any

import icalendar
import recurring_ical_events
from loguru import logger

from src.core.schedule.model import (
    Entry,
    EntryType,
    ScheduleData,
    Subject,
    Timeline,
    Timetable,
    WeekRule,
    WeekType,
)
from src.core.utils import generate_id, get_random_subject_color

from .common import build_meta, fill_short_breaks

_BYDAY = {
    "MO": 1,
    "TU": 2,
    "WE": 3,
    "TH": 4,
    "FR": 5,
    "SA": 6,
    "SU": 7,
}


@dataclass(frozen=True)
class Occurrence:
    date: date
    start: datetime
    end: datetime
    summary: str
    location: str
    uid: str = ""
    recurring: bool = False  # 是否来自带 RRULE 的有限重复序列


@dataclass(frozen=True)
class InfiniteSpec:
    uid: str
    summary: str
    location: str
    start: datetime
    end: datetime
    interval: int
    weekdays: tuple[int, ...]
    first_date: date
    exdates: frozenset[date]
    rdates: tuple[date | datetime, ...]

    def positions(self, start_date: date, max_week_cycle: int) -> tuple[int, ...]:
        first_week = _week_index(self.first_date, start_date)
        phase = ((first_week - 1) % max_week_cycle) + 1
        result: list[int] = []
        position = phase
        while position not in result:
            result.append(position)
            position = ((position - 1 + self.interval) % max_week_cycle) + 1
        return tuple(sorted(result))

    def matches_pattern(self, value: date, start_date: date, max_week_cycle: int) -> bool:
        if value.isoweekday() not in self.weekdays:
            return False
        cycle_week = ((_week_index(value, start_date) - 1) % max_week_cycle) + 1
        return cycle_week in self.positions(start_date, max_week_cycle)

    def matches_date(self, value: date, start_date: date, max_week_cycle: int) -> bool:
        return (
            value >= self.first_date
            and value not in self.exdates
            and self.matches_pattern(value, start_date, max_week_cycle)
        )


def _first(value: Any) -> Any:
    if isinstance(value, (list, tuple)) and value:
        return value[0]
    return value


def _as_date(value: date | datetime) -> date:
    return value.date() if isinstance(value, datetime) else value


def _week_index(value: date, start_date: date) -> int:
    return (value - start_date).days // 7 + 1


def _local_datetime(value: datetime) -> datetime:
    return value.astimezone() if value.tzinfo is not None else value


def _component_time(component: Any, name: str) -> datetime | None:
    prop = component.get(name)
    if prop is None or not hasattr(prop, "dt"):
        return None
    value = prop.dt
    return value if isinstance(value, datetime) else None


def _component_times(component: Any) -> tuple[datetime, datetime] | None:
    start = _component_time(component, "DTSTART")
    if start is None:
        return None

    end = _component_time(component, "DTEND")
    if end is None:
        duration_prop = component.get("DURATION")
        duration = getattr(duration_prop, "dt", None)
        if not isinstance(duration, timedelta):
            return None
        end = start + duration

    start = _local_datetime(start)
    end = _local_datetime(end)
    if end <= start or start.date() != end.date():
        return None
    return start, end


def _component_text(component: Any, name: str) -> str:
    value = component.get(name)
    return str(value).strip() if value is not None else ""


def _rrule(component: Any) -> tuple[Any, str, int] | None:
    rule = component.get("RRULE")
    if rule is None:
        return None
    frequency = str(_first(rule.get("FREQ")) or "").upper()
    if not frequency:
        return None
    interval = int(_first(rule.get("INTERVAL")) or 1)
    return rule, frequency, interval


def _has_end_limit(rule: Any) -> bool:
    return bool(rule.get("UNTIL") or rule.get("COUNT"))


def _is_infinite_weekly(component: Any) -> bool:
    data = _rrule(component)
    return bool(data and data[1] == "WEEKLY" and not _has_end_limit(data[0]))


def _is_supported_component(component: Any) -> bool:
    if str(component.get("STATUS") or "").upper() == "CANCELLED":
        return False
    data = _rrule(component)
    return data is None or data[1] == "WEEKLY"


def _byday_weekdays(component: Any, start: datetime) -> tuple[int, ...]:
    data = _rrule(component)
    if data is None:
        return (start.isoweekday(),)
    byday = data[0].get("BYDAY")
    if not byday:
        return (start.isoweekday(),)
    values = byday if isinstance(byday, list) else [byday]
    result = []
    for value in values:
        text = str(value).upper()
        for token, weekday in _BYDAY.items():
            if token in text and weekday not in result:
                result.append(weekday)
    return tuple(sorted(result)) or (start.isoweekday(),)


def _iter_property_dates(value: Any):
    if value is None:
        return
    values = value if isinstance(value, list) else [value]
    for item in values:
        dates = getattr(item, "dts", None)
        if dates:
            for nested in dates:
                yield getattr(nested, "dt", nested)
        else:
            yield getattr(item, "dt", item)


def _property_dates(component: Any, name: str) -> tuple[date | datetime, ...]:
    return tuple(
        value
        for value in _iter_property_dates(component.get(name))
        if isinstance(value, (date, datetime))
    )


def _build_infinite_spec(component: Any, times: tuple[datetime, datetime]) -> InfiniteSpec | None:
    data = _rrule(component)
    if data is None:
        return None
    start, end = times
    exdates = frozenset(
        _as_date(value) for value in _property_dates(component, "EXDATE")
    )
    return InfiniteSpec(
        uid=str(component.get("UID") or ""),
        summary=_component_text(component, "SUMMARY"),
        location=_component_text(component, "LOCATION"),
        start=start,
        end=end,
        interval=data[2],
        weekdays=_byday_weekdays(component, start),
        first_date=start.date(),
        exdates=exdates,
        rdates=_property_dates(component, "RDATE"),
    )


def _occurrence_from_component(component: Any) -> Occurrence | None:
    if str(component.get("STATUS") or "").upper() == "CANCELLED":
        return None
    times = _component_times(component)
    if times is None:
        return None
    start, end = times
    return Occurrence(
        date=start.date(),
        start=start,
        end=end,
        summary=_component_text(component, "SUMMARY"),
        location=_component_text(component, "LOCATION"),
        uid=str(component.get("UID") or ""),
    )


def _finite_expansion_end(components: list[Any], start_date: date) -> date:
    value = start_date

    for component in components:
        times = _component_times(component)
        if times is None:
            continue
        start, end = times
        data = _rrule(component)
        candidate = end.date()
        if data is not None:
            rule, _frequency, interval = data
            count = int(_first(rule.get("COUNT")) or 0)
            until = _first(rule.get("UNTIL"))
            if count:
                candidate = (start + timedelta(weeks=(count - 1) * interval)).date()
            elif isinstance(until, (date, datetime)):
                candidate = _as_date(until)
        value = max(value, candidate)

    return max(value, start_date + timedelta(weeks=1)) + timedelta(days=1)


def _finite_calendar(calendar: Any, finite_components: list[Any]) -> Any:
    result = icalendar.Calendar()
    for component in calendar.subcomponents:
        if component.name == "VTIMEZONE":
            result.add_component(component)
    for component in finite_components:
        result.add_component(component)
    return result


def _expand_finite(
    calendar: Any,
    finite_components: list[Any],
    start_date: date,
) -> list[Occurrence]:
    if not finite_components:
        return []
    result_calendar = _finite_calendar(calendar, finite_components)
    start = datetime.combine(start_date, time.min)
    end_date = _finite_expansion_end(finite_components, start_date)
    end = datetime.combine(end_date, time.max)
    components = recurring_ical_events.of(result_calendar).between(start, end)
    recurring_masters = {
        str(component.get("UID") or "") for component in finite_components
        if _rrule(component) is not None
    }
    result = []
    for component in components:
        occurrence = _occurrence_from_component(component)
        if occurrence and occurrence.date >= start_date:
            result.append(
                Occurrence(
                    date=occurrence.date,
                    start=occurrence.start,
                    end=occurrence.end,
                    summary=occurrence.summary,
                    location=occurrence.location,
                    uid=occurrence.uid,
                    recurring=occurrence.uid in recurring_masters,
                )
            )
    return result


def _unique_occurrences(occurrences: list[Occurrence]) -> list[Occurrence]:
    result = []
    seen = set()
    for occurrence in occurrences:
        key = (
            occurrence.date,
            occurrence.start,
            occurrence.end,
            occurrence.summary,
            occurrence.location,
        )
        if key in seen:
            continue
        seen.add(key)
        result.append(occurrence)
    return result


def _rdate_occurrences(spec: InfiniteSpec) -> list[Occurrence]:
    result = []
    duration = spec.end - spec.start
    for value in spec.rdates:
        if isinstance(value, datetime):
            start = _local_datetime(value)
        else:
            start = datetime.combine(value, spec.start.timetz())
        result.append(
            Occurrence(
                date=start.date(),
                start=start,
                end=start + duration,
                summary=spec.summary,
                location=spec.location,
                uid=spec.uid,
            )
        )
    return result


def _subject_key(summary: str, location: str) -> tuple[str, str] | None:
    if not summary:
        return None
    return summary, location


def _time_bounds_minutes(start_time: str, end_time: str) -> tuple[int, int]:
    sh, sm = map(int, start_time.split(":"))
    eh, em = map(int, end_time.split(":"))
    return sh * 60 + sm, eh * 60 + em


def _resolve_slot_conflicts(
    slots: list[tuple[str, str]],
    context: str,
    reported: set[str],
) -> list[tuple[str, str]]:
    """对同一星期的时间槽做冲突解决：保留不重叠的槽，跳过与已保留重叠的槽。"""
    kept: list[tuple[str, str]] = []
    for slot in sorted(slots):
        s, e = _time_bounds_minutes(slot[0], slot[1])
        overlaps = any(
            s < _time_bounds_minutes(k[0], k[1])[1]
            and _time_bounds_minutes(k[0], k[1])[0] < e
            for k in kept
        )
        if overlaps:
            ref = f"{context}: {slot[0]}-{slot[1]}"
            if ref not in reported:
                reported.add(ref)
                logger.warning(
                    "ICS import conflict skipped slot on {}: {} overlaps an already kept slot",
                    context,
                    slot,
                )
            continue
        kept.append(slot)
    return kept


def _collect_infinite(
    masters: list[Any],
) -> list[InfiniteSpec]:
    specs = []
    for component in masters:
        if not _is_supported_component(component) or not _is_infinite_weekly(component):
            continue
        times = _component_times(component)
        if times is None:
            continue
        spec = _build_infinite_spec(component, times)
        if spec is None:
            continue
        specs.append(spec)
    return specs


def _read(path: str | Path, start_date: date | str) -> ScheduleData:
    if isinstance(start_date, str):
        start_date = datetime.strptime(start_date, "%Y-%m-%d").date()

    calendar = icalendar.Calendar.from_ical(Path(path).read_bytes())
    all_components = list(calendar.walk("VEVENT"))

    # 主事件（无 RECURRENCE-ID）与替换子事件（RECURRENCE-ID，同 UID）分开处理。
    masters = [c for c in all_components if c.get("RECURRENCE-ID") is None]
    children = [c for c in all_components if c.get("RECURRENCE-ID") is not None]

    infinite_specs = _collect_infinite(masters)

    finite_components = [
        component
        for component in masters
        if _is_supported_component(component) and not _is_infinite_weekly(component)
    ]
    finite_occurrences = _unique_occurrences(
        _expand_finite(calendar, finite_components, start_date)
    )

    recurrence_children = [occ for component in children if (occ := _occurrence_from_component(component))]

    max_week_cycle = 1
    for spec in infinite_specs:
        max_week_cycle = lcm(max_week_cycle, spec.interval)

    subjects: dict[tuple[str, str], str] = {}
    subject_list: list[Subject] = []
    subject_values = [
        (spec.summary, spec.location)
        for spec in infinite_specs
    ] + [
        (occurrence.summary, occurrence.location)
        for occurrence in finite_occurrences
    ] + [
        (occurrence.summary, occurrence.location)
        for occurrence in recurrence_children
    ]
    for summary, location in subject_values:
        key = _subject_key(summary, location)
        if key is None or key in subjects:
            continue
        subject_id = generate_id("subj")
        subjects[key] = subject_id
        subject_list.append(
            Subject(
                id=subject_id,
                name=summary,
                color=get_random_subject_color(),
                location=location or None,
                isLocalClassroom=not bool(location),
            )
        )

    # ── 装配：days=纯时间骨架，overrides=课程 ──────────────────────────────
    # 与真实 CW2 格式一致：
    # - days：每星期一条 weeks="all" 的时间骨架，entry 只定义时间槽（subjectId=null）
    # - overrides：每门课是一条 Timetable，entryId 指向骨架槽 + dayOfWeek + weeks + subjectId

    all_positions = set(range(1, max_week_cycle + 1))
    even_positions = {position for position in all_positions if position % 2 == 0}
    odd_positions = all_positions - even_positions

    def _reducible_rule(positions: set[int]) -> WeekRule | None:
        if positions == all_positions:
            return WeekType.ALL
        if positions == even_positions:
            return WeekType.EVEN
        if positions == odd_positions:
            return WeekType.ODD
        if len(positions) == 1:
            return next(iter(positions))
        return None

    # 1. 区分"普通周规则槽"与"独立槽"
    #    普通周规则 = 无限周重复(每周/按轮换都占) → 进 weeks="all" 骨架；
    #    其时间槽被有限课/RDATE 共享时仍用 override 复用槽。
    #    独立槽 = 只有指定周(有限COUNT/UNTIL/RDATE)或特定日期(单次)使用该时段、
    #              且无任何普通周规则共享 → 单独建 Timeline(weeks=[绝对周] 或 date)，
    #              不塞进 weeks="all"(否则平时空白占用)。
    slots_by_weekday: dict[int, list[tuple[str, str]]] = defaultdict(list)

    for spec in infinite_specs:
        st = spec.start.strftime("%H:%M")
        et = spec.end.strftime("%H:%M")
        for weekday in spec.weekdays:
            slots_by_weekday[weekday].append((st, et))

    for weekday in slots_by_weekday:
        slots_by_weekday[weekday] = sorted(set(slots_by_weekday[weekday]))
    ordinary_slots = {
        (wd, st, et) for wd in slots_by_weekday for st, et in slots_by_weekday[wd]
    }

    # 独立槽(weeks 集合)，按 (weekday, st, et, summary) 分组绝对周。
    # 仅收集"该时段没有普通周规则共享"的有限课/RDATE。
    standalone_weeks: dict[tuple[int, str, str, str], set[int]] = defaultdict(set)
    standalone_subject: dict[tuple[int, str, str, str], str] = {}
    standalone_title: dict[tuple[int, str, str, str], str] = {}

    def _remember_standalone(
        weekday: int, st: str, et: str, summary: str, location: str, abs_week: int
    ) -> None:
        key = (weekday, st, et, summary)
        standalone_weeks[key].add(abs_week)
        if key not in standalone_subject:
            subj_key = _subject_key(summary, location or "")
            subject_id = subjects.get(subj_key) if subj_key else None
            standalone_subject[key] = subject_id
            standalone_title[key] = None if subject_id else (summary or None)

    for occurrence in finite_occurrences:
        if occurrence.date < start_date or not occurrence.recurring:
            continue
        weekday = occurrence.date.isoweekday()
        st = occurrence.start.strftime("%H:%M")
        et = occurrence.end.strftime("%H:%M")
        if (weekday, st, et) in ordinary_slots:
            continue  # 与普通周规则共享 → 稍后作为 override
        _remember_standalone(
            weekday, st, et, occurrence.summary, occurrence.location,
            _week_index(occurrence.date, start_date),
        )

    for spec in infinite_specs:
        for occ in _rdate_occurrences(spec):
            if occ.date < start_date:
                continue
            weekday = occ.date.isoweekday()
            st = occ.start.strftime("%H:%M")
            et = occ.end.strftime("%H:%M")
            if (weekday, st, et) in ordinary_slots:
                continue
            _remember_standalone(
                weekday, st, et, occ.summary, occ.location,
                _week_index(occ.date, start_date),
            )

    # 2. 构建骨架：每星期一条 Timeline(weeks="all")，entry 只有时间槽（无课程信息）
    reported: set[str] = set()
    slot_id_map: dict[tuple[int, str, str], str] = {}
    skeleton_days: list[Timeline] = []

    for weekday in sorted(slots_by_weekday.keys()):
        resolved_slots = _resolve_slot_conflicts(
            slots_by_weekday[weekday], f"weekday {weekday}", reported
        )
        entries = []
        for st, et in resolved_slots:
            entry_id = generate_id("entry")
            slot_id_map[(weekday, st, et)] = entry_id
            entries.append(
                Entry(
                    id=entry_id,
                    type=EntryType.CLASS,
                    startTime=st,
                    endTime=et,
                    subjectId=None,
                    title=None,
                )
            )
        entries = fill_short_breaks(entries)
        skeleton_days.append(
            Timeline(
                id=generate_id("day"),
                dayOfWeek=[weekday],
                weeks=WeekType.ALL,
                entries=entries,
            )
        )

    # 2b. 独立槽 → 单独 Timeline（weeks=[绝对周]，entry 直接带课程）
    #      按 (weekday, st, et) 聚合该槽所有课程；若同槽多门课在同一周冲突，
    #      按确定性顺序保留一课（其余跳到后续周）并记录。
    standalone_by_slot: dict[tuple[int, str, str], list[dict]] = defaultdict(list)
    for (weekday, st, et, summary), weeks in standalone_weeks.items():
        entry = {
            "weekday": weekday,
            "st": st,
            "et": et,
            "weeks": set(weeks),
            "subject_id": standalone_subject[(weekday, st, et, summary)],
            "title": standalone_title[(weekday, st, et, summary)],
        }
        standalone_by_slot[(weekday, st, et)].append(entry)

    for (weekday, st, et), entries_slot in sorted(standalone_by_slot.items()):
        # 冲突消解：同槽多门课，取它们的绝对周并集；同周被多门课占用时保留第一课
        claimed: dict[int, dict] = {}
        for entry in sorted(entries_slot, key=lambda e: str(e.get("title")) or ""):
            for week in entry["weeks"]:
                if week not in claimed:
                    claimed[week] = entry
        # 归并成 week → 唯一课程
        week_owner: dict[int, dict] = claimed

        timeline_entries: list[Entry] = []
        owner_weeks: dict[tuple, set[int]] = defaultdict(set)
        for week in sorted(week_owner):
            owner = week_owner[week]
            owner_weeks[(owner["st"], owner["et"], owner["subject_id"], owner["title"])].add(week)
        for (o_st, o_et, subject_id, title), weeks in sorted(owner_weeks.items()):
            timeline_entries.append(
                Entry(
                    id=generate_id("entry"),
                    type=EntryType.CLASS,
                    startTime=o_st,
                    endTime=o_et,
                    subjectId=subject_id,
                    title=title,
                )
            )
        timeline_entries = fill_short_breaks(timeline_entries)
        skeleton_days.append(
            Timeline(
                id=generate_id("day"),
                dayOfWeek=[weekday],
                weeks=sorted(week_owner.keys()),
                entries=timeline_entries,
            )
        )

    # 3. 构建 overrides
    overrides: list[Timetable] = []

    # 3a. 无限重复 → 每个 (spec, weekday) 一条 override
    for spec in infinite_specs:
        st = spec.start.strftime("%H:%M")
        et = spec.end.strftime("%H:%M")
        positions = set(spec.positions(start_date, max_week_cycle))
        rule = _reducible_rule(positions)
        key = _subject_key(spec.summary, spec.location)
        subject_id = subjects.get(key) if key else None
        title = None if subject_id else (spec.summary or None)

        for weekday in spec.weekdays:
            entry_id = slot_id_map.get((weekday, st, et))
            if entry_id is None:
                continue
            if rule is not None:
                overrides.append(
                    Timetable(
                        id=generate_id("override"),
                        entryId=entry_id,
                        dayOfWeek=[weekday],
                        weeks=rule,
                        subjectId=subject_id,
                        title=title,
                    )
                )
            else:
                # 不可归约（如 INTERVAL=3 多相位）→ 每个轮换位一条 override
                for position in sorted(positions):
                    overrides.append(
                        Timetable(
                            id=generate_id("override"),
                            entryId=entry_id,
                            dayOfWeek=[weekday],
                            weeks=position,
                            subjectId=subject_id,
                            title=title,
                        )
                    )

    # 3b. 周期有限/RDATE → 按 (weekday, startTime, endTime, subjectId) 合并
    #     仅处理"与普通周规则共享槽"的有限课（独立槽已收集到 standalone，稍后单建 Timeline）
    finite_groups: dict[tuple, dict] = {}
    for occurrence in finite_occurrences:
        if occurrence.date < start_date or not occurrence.recurring:
            continue
        weekday = occurrence.date.isoweekday()
        st = occurrence.start.strftime("%H:%M")
        et = occurrence.end.strftime("%H:%M")
        if (weekday, st, et) not in ordinary_slots:
            continue  # 独立槽，单独 Timeline
        absolute_week = _week_index(occurrence.date, start_date)
        key = _subject_key(occurrence.summary, occurrence.location)
        subject_id = subjects.get(key) if key else None
        group_key = (weekday, st, et, subject_id, occurrence.summary)
        if group_key not in finite_groups:
            finite_groups[group_key] = {
                "weeks": set(),
                "weekday": weekday,
                "st": st,
                "et": et,
                "subject_id": subject_id,
            }
        finite_groups[group_key]["weeks"].add(absolute_week)

    for rdate_occ in [
        occ for spec in infinite_specs for occ in _rdate_occurrences(spec) if occ.date >= start_date
    ]:
        weekday = rdate_occ.date.isoweekday()
        st = rdate_occ.start.strftime("%H:%M")
        et = rdate_occ.end.strftime("%H:%M")
        if (weekday, st, et) not in ordinary_slots:
            continue  # 独立槽，单独 Timeline
        absolute_week = _week_index(rdate_occ.date, start_date)
        key = _subject_key(rdate_occ.summary, rdate_occ.location)
        subject_id = subjects.get(key) if key else None
        group_key = (weekday, st, et, subject_id, rdate_occ.summary)
        if group_key not in finite_groups:
            finite_groups[group_key] = {
                "weeks": set(),
                "weekday": weekday,
                "st": st,
                "et": et,
                "subject_id": subject_id,
            }
        finite_groups[group_key]["weeks"].add(absolute_week)

    for (_weekday, _st, _et, _subj, summary), info in sorted(finite_groups.items()):
        entry_id = slot_id_map.get((info["weekday"], info["st"], info["et"]))
        if entry_id is None:
            continue
        title = None if info["subject_id"] else (summary or None)
        overrides.append(
            Timetable(
                id=generate_id("override"),
                entryId=entry_id,
                dayOfWeek=[info["weekday"]],
                weeks=sorted(info["weeks"]),
                subjectId=info["subject_id"],
                title=title,
            )
        )

    # 3c. RECURRENCE-ID 替换 → 每个 child 一条 override
    # 子事件复用父事件的骨架槽（entryId 指向父槽），调课时间通过 override 的
    # startTime/endTime 表达，绝不为子事件单独造槽（否则会出现幽灵空槽）。
    for occurrence in recurrence_children:
        weekday = occurrence.date.isoweekday()
        absolute_week = _week_index(occurrence.date, start_date)
        st = occurrence.start.strftime("%H:%M")
        et = occurrence.end.strftime("%H:%M")
        key = _subject_key(occurrence.summary, occurrence.location)
        subject_id = subjects.get(key) if key else None
        title = None if subject_id else (occurrence.summary or None)

        # 找到基础事件的骨架槽（用于 entryId）
        base_spec = next((s for s in infinite_specs if s.uid == occurrence.uid), None)
        if base_spec:
            base_st = base_spec.start.strftime("%H:%M")
            base_et = base_spec.end.strftime("%H:%M")
            entry_id = slot_id_map.get((weekday, base_st, base_et))
            time_changed = (st != base_st or et != base_et)
        else:
            # 父事件不在无限集中：按子事件自身时间槽定位，缺失时补一个骨架槽
            entry_id = slot_id_map.get((weekday, st, et))
            if entry_id is None:
                skeleton_day = next(
                    (d for d in skeleton_days if d.dayOfWeek == [weekday]), None
                )
                if skeleton_day is not None:
                    new_entry_id = generate_id("entry")
                    slot_id_map[(weekday, st, et)] = new_entry_id
                    skeleton_day.entries.append(
                        Entry(
                            id=new_entry_id,
                            type=EntryType.CLASS,
                            startTime=st,
                            endTime=et,
                            subjectId=None,
                            title=None,
                        )
                    )
                    entry_id = new_entry_id
            time_changed = False

        if entry_id is None:
            continue

        overrides.append(
            Timetable(
                id=generate_id("override"),
                entryId=entry_id,
                dayOfWeek=[weekday],
                weeks=[absolute_week],
                subjectId=subject_id,
                title=title,
                startTime=st if time_changed else None,
                endTime=et if time_changed else None,
            )
        )

    # 4. EXDATE / DTSTART前期屏蔽 + 单次事件 → 生成 date Timeline
    # date Timeline 是当天完整快照：复制骨架（排除被屏蔽槽），再加当天的单次课程槽。
    # 单次事件(无 RRULE 的纯一次性事件)不占固定时段，只能借此表达，平时不产生空白占用。
    # 按日期聚合：每日期只有一个 date Timeline（同时处理屏蔽与单次增补）。
    day_events: dict[date, dict[str, set]] = defaultdict(lambda: {"masked": set(), "singles": set()})

    for spec in infinite_specs:
        for exdate in spec.exdates:
            st = spec.start.strftime("%H:%M")
            et = spec.end.strftime("%H:%M")
            for weekday in spec.weekdays:
                if exdate.isoweekday() == weekday:
                    day_events[exdate]["masked"].add((st, et))
        # DTSTART前期
        cursor = start_date.toordinal()
        while cursor < spec.first_date.toordinal():
            candidate = date.fromordinal(cursor)
            if spec.matches_pattern(candidate, start_date, max_week_cycle):
                for weekday in spec.weekdays:
                    if candidate.isoweekday() == weekday:
                        st = spec.start.strftime("%H:%M")
                        et = spec.end.strftime("%H:%M")
                        day_events[candidate]["masked"].add((st, et))
            cursor += 1

    # 单次事件(recurring=False) → 当天快照增补
    single_by_date: dict[date, list[Occurrence]] = defaultdict(list)
    for occurrence in finite_occurrences:
        if occurrence.date >= start_date and not occurrence.recurring:
            single_by_date[occurrence.date].append(occurrence)
            day_events[occurrence.date]  # 确保该日期存在，触发 date Timeline

    subjects_direct: dict[tuple[str, str], str] = subjects

    for day in sorted(day_events.keys()):
        weekday = day.isoweekday()
        skeleton_day = next((d for d in skeleton_days if d.dayOfWeek == [weekday]), None)
        masked_slots = day_events[day]["masked"]

        entries: list[Entry] = []
        if skeleton_day is not None:
            # 复制骨架，排除被屏蔽的槽
            for entry in skeleton_day.entries:
                if entry.type != EntryType.CLASS:
                    entries.append(entry.model_copy())
                    continue
                if (entry.startTime, entry.endTime) in masked_slots:
                    continue  # 被屏蔽，不加入 date Timeline
                entries.append(entry.model_copy())

        # 增加单次课程槽（直接填 subjectId/title；date Timeline 即当天生效，无需 weeks）
        for occurrence in single_by_date.get(day, []):
            st = occurrence.start.strftime("%H:%M")
            et = occurrence.end.strftime("%H:%M")
            key = _subject_key(occurrence.summary, occurrence.location)
            subject_id = subjects_direct.get(key) if key else None
            title = None if subject_id else (occurrence.summary or None)
            entries.append(
                Entry(
                    id=generate_id("entry"),
                    type=EntryType.CLASS,
                    startTime=st,
                    endTime=et,
                    subjectId=subject_id,
                    title=title,
                )
            )

        skeleton_days.append(
            Timeline(
                id=generate_id("day"),
                date=day.isoformat(),
                entries=fill_short_breaks(entries),
            )
        )

    if not skeleton_days:
        logger.warning(f"No supported ICS events found in {path}")

    return ScheduleData(
        meta=build_meta(start_date=start_date, max_week_cycle=max_week_cycle),
        subjects=subject_list,
        days=skeleton_days,
        overrides=overrides,
    )


def read(path: str | Path, start_date: date | str) -> ScheduleData:
    return _read(path, start_date)


def validate(path: str | Path) -> bool:
    try:
        calendar = icalendar.Calendar.from_ical(Path(path).read_bytes())
        return any(component.name == "VEVENT" for component in calendar.walk())
    except Exception:
        return False


READ = read
