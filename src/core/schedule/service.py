from datetime import datetime, timedelta
from typing import Optional

from src.core.schedule.model import (
    Entry,
    EntryType,
    Timeline,
    Subject,
    ScheduleData,
    Timetable,
    WeekType,
    normalize_week_rule,
    week_rule_matches,
)
from src.core.utils import get_week_number, get_cycle_week


class ScheduleServices:
    def __init__(self, app_central):
        self.app_central = app_central

    def _get_reschedule_map(self) -> dict:
        return self.app_central.configs.schedule.reschedule_day

    def get_day_entries(self, schedule: ScheduleData, now: datetime) -> Optional[Timeline]:
        """
        返回当前日期对应的 Timeline（深拷贝，应用 override，不修改原始数据）。

        带有 date 的 Timeline 是指定日期时间线，优先于按星期和周次匹配的时间线。
        """
        date_str = now.strftime("%Y-%m-%d")

        # 指定日期时间线优先，不受 dayOfWeek/weeks 限制。
        matched_day = next((day for day in schedule.days if day.date == date_str), None)

        # 绝对周次从开学日起算；周期周次只用于整数规则和多周轮换。
        absolute_week = self._get_week_index(schedule, now)
        reschedule_map = self._get_reschedule_map()

        # 调休处理：优先使用调休映射表
        if date_str in reschedule_map:
            weekday = reschedule_map[date_str]  # 1-7
        else:
            weekday = now.isoweekday()  # 默认 1-7

        max_week_cycle = max(1, schedule.meta.maxWeekCycle or 1)
        cycle_week = get_cycle_week(absolute_week, max_week_cycle)

        # 临时换课
        class_swap = getattr(self.app_central.configs.schedule, "class_swap", None)
        if isinstance(class_swap, dict) and class_swap.get("date") == date_str:
            swap_weekday = class_swap.get("day_of_week")
            swap_week = class_swap.get("week_of_cycle")
            if isinstance(swap_weekday, int) and 1 <= swap_weekday <= 7:
                weekday = swap_weekday
            if isinstance(swap_week, int) and 1 <= swap_week <= max_week_cycle:
                cycle_week = swap_week

        if matched_day is None:
            for day in schedule.days:
                day_of_week_list = [day.dayOfWeek] if isinstance(day.dayOfWeek, int) else day.dayOfWeek
                if (
                    day_of_week_list
                    and weekday in day_of_week_list
                    and self._is_in_week(
                        day.weeks, absolute_week, max_week_cycle, cycle_week
                    )
                ):
                    matched_day = day
                    break

        if matched_day is not None:
            # 深拷贝 day 和 entries
            day_copy = matched_day.model_copy()
            day_copy.entries = [entry.model_copy() for entry in matched_day.entries]

            # 应用 override 到副本
            for entry in day_copy.entries:
                subject_overridden = False
                title_overridden = False
                for override in schedule.overrides:
                    if override.entryId != entry.id:
                        continue
                    if self._override_applies(
                        override, weekday, absolute_week, max_week_cycle, cycle_week
                    ):
                        if override.subjectId:
                            entry.subjectId = override.subjectId
                            subject_overridden = True
                        if override.title:
                            entry.title = override.title
                            title_overridden = True
                        if override.startTime:
                            entry.startTime = override.startTime
                        if override.endTime:
                            entry.endTime = override.endTime

                if subject_overridden and not title_overridden:
                    entry.title = None

            return day_copy
        return None

    @staticmethod
    def _override_applies(
        override: Timetable,
        weekday: int,
        absolute_week: int,
        max_week_cycle: int = 1,
        cycle_week: Optional[int] = None,
    ) -> bool:
        if override.dayOfWeek and weekday not in override.dayOfWeek:
            return False
        if override.weeks is not None:
            if not ScheduleServices._is_in_week(
                override.weeks, absolute_week, max_week_cycle, cycle_week
            ):
                return False
        return True

    @staticmethod
    def get_current_entry(day: Timeline, now: Optional[datetime] = None) -> Optional[Entry]:
        now = now or datetime.now()
        time = now.time()
        for entry in day.entries:
            try:
                start = datetime.strptime(entry.startTime, "%H:%M").time()
                end = datetime.strptime(entry.endTime, "%H:%M").time()
            except ValueError:
                continue
            if start <= time < end:
                return entry
        return None

    @staticmethod
    def get_all_entries(day: Timeline) -> list[Entry]:
        """
        返回当天所有可显示的条目
        """
        entries = [
            e for e in day.entries
            if e.type in {EntryType.CLASS, EntryType.ACTIVITY}
        ]
        return sorted(entries, key=lambda e: datetime.strptime(e.startTime, "%H:%M").time())

    @staticmethod
    def get_next_entries(day: Timeline, now: Optional[datetime] = None) -> list[Entry]:
        now = now or datetime.now()
        now_time = now.time()
        next_entries = [
            e for e in day.entries
            if datetime.strptime(e.startTime, "%H:%M").time() > now_time
            and e.type in {EntryType.CLASS, EntryType.ACTIVITY}
        ]
        return sorted(next_entries, key=lambda e: datetime.strptime(e.startTime, "%H:%M").time())

    @staticmethod
    def get_remaining_time(day: Timeline, now: Optional[datetime] = None) -> timedelta:
        now = now or datetime.now()
        current = ScheduleServices.get_current_entry(day, now)
        if current:
            end_time = datetime.strptime(current.endTime, "%H:%M").time()
            end_dt = now.replace(hour=end_time.hour, minute=end_time.minute, second=0, microsecond=0)
            return max(end_dt - now, timedelta(0))
        upcoming = ScheduleServices.get_next_entries(day, now)
        if upcoming:
            next_start = datetime.strptime(upcoming[0].startTime, "%H:%M").time()
            next_dt = now.replace(hour=next_start.hour, minute=next_start.minute, second=0, microsecond=0)
            return max(next_dt - now, timedelta(0))
        return timedelta(0)

    @staticmethod
    def get_current_status(day: Timeline, now: Optional[datetime] = None, prep_min: int = 2) -> EntryType:
        now = now or datetime.now()
        if upcoming := ScheduleServices.get_next_entries(day, now):
            next_start = datetime.combine(now.date(), datetime.strptime(upcoming[0].startTime, "%H:%M").time())
            if next_start - timedelta(minutes=prep_min) <= now.replace(microsecond=0):
                return EntryType.PREPARATION

        current = ScheduleServices.get_current_entry(day, now)
        return current.type if current else EntryType.FREE

    @staticmethod
    def get_current_subject(day: Timeline, subjects: list[Subject], now: Optional[datetime] = None) -> Optional[Subject]:
        current = ScheduleServices.get_current_entry(day, now)
        if current and current.subjectId:
            for s in subjects:
                if s.id == current.subjectId:
                    return s
        return None

    @staticmethod
    def get_subject(subject_id: str, subjects: list[Subject]) -> Optional[Subject]:
        if not subject_id and subjects:
            return None
        for s in subjects:
            if s.id == subject_id:
                return s
        return None

    @staticmethod
    def _get_week_index(schedule: ScheduleData, now: datetime) -> int:
        """
        根据 schedule.meta.startDate 算出当前是第几周
        """
        if not schedule.meta or not schedule.meta.startDate:
            return 1  # fallback 默认第1周

        return get_week_number(schedule.meta.startDate, now)

    @staticmethod
    def _is_in_week(
        weeks,
        absolute_week: int,
        max_week_cycle: int = 1,
        cycle_week: Optional[int] = None,
    ) -> bool:
        """判断 week rule 是否覆盖指定周。

        - "all" → 所有周
        - "odd"/"even" → 按绝对周次判断单双周
        - int → 周期内第几周（例如每 3 周的第 2 周）
        - list[int] → 指定绝对周次
        - None → 不限制
        """
        rule = normalize_week_rule(weeks)
        if rule is None:
            return weeks is None
        if isinstance(rule, int):
            if cycle_week is None:
                return week_rule_matches(rule, absolute_week, max_week_cycle)
            return cycle_week == rule
        return week_rule_matches(rule, absolute_week, max_week_cycle)
