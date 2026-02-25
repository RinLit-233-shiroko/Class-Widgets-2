from datetime import datetime, timedelta
from typing import Optional, List, Union

from class_widgets_2.core.schedule.model import Entry, EntryType, Timeline, Subject, ScheduleData, Timetable, WeekType


class ScheduleServices:
    def __init__(self, app_central):
        self.app_central = app_central

    def _get_reschedule_map(self) -> dict:
        return self.app_central.configs.schedule.reschedule_day

    def get_day_entries(self, schedule: ScheduleData, now: datetime) -> Optional[Timeline]:
        """
        返回当前日期对应的 DayEntry（深拷贝，应用 override，不修改原始数据）
        """
        current_week = self._get_week_index(schedule, now)  # 当前第几周
        reschedule_map = self._get_reschedule_map()

        # 调休处理：优先使用调休映射表
        date_str = now.strftime("%Y-%m-%d")
        if date_str in reschedule_map:
            weekday = reschedule_map[date_str]  # 1-7
        else:
            weekday = now.isoweekday()  # 默认 1-7

        max_week_cycle = schedule.meta.maxWeekCycle or 1

        for day in schedule.days:
            day_of_week_list = [day.dayOfWeek] if isinstance(day.dayOfWeek, int) else day.dayOfWeek
            if day_of_week_list and weekday in day_of_week_list:
                if self._is_in_week(day.weeks, current_week, max_week_cycle):
                    # 深拷贝 day 和 entries
                    day_copy = day.model_copy()
                    day_copy.entries = [entry.model_copy() for entry in day.entries]

                    # 应用 override 到副本
                    for entry in day_copy.entries:
                        for override in schedule.overrides:
                            if override.entryId != entry.id:
                                continue
                            if self._override_applies(override, weekday, current_week):
                                if override.subjectId:
                                    entry.subjectId = override.subjectId
                                if override.title:
                                    entry.title = override.title

                    return day_copy
        return None

    def _override_applies(self, override: Timetable, weekday: int, current_week: int, max_week_cycle: int = 1) -> bool:
        if override.dayOfWeek:
            if weekday not in override.dayOfWeek:
                return False
        if override.weeks:
            if not self._is_in_week(override.weeks, current_week, max_week_cycle):
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
    def get_all_entries(day: Timeline) -> List[Entry]:
        """
        返回当天所有可显示的条目
        """
        entries = [
            e for e in day.entries
            if e.type in {EntryType.CLASS, EntryType.ACTIVITY}
        ]
        return sorted(entries, key=lambda e: datetime.strptime(e.startTime, "%H:%M").time())

    @staticmethod
    def get_next_entries(day: Timeline, now: Optional[datetime] = None) -> List[Entry]:
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
    def get_current_status(day: Timeline, now: Optional[datetime] = None) -> EntryType:
        return ScheduleServices.get_current_entry(day, now).type if ScheduleServices.get_current_entry(day, now) else EntryType.FREE

    @staticmethod
    def get_current_subject(day: Timeline, subjects: List[Subject], now: Optional[datetime] = None) -> Optional[
        Subject]:
        current = ScheduleServices.get_current_entry(day, now)
        if current and current.subjectId:
            for s in subjects:
                if s.id == current.subjectId:
                    return s
        return None

    @staticmethod
    def get_subject(subject_id: str, subjects: List[Subject]) -> Optional[Subject]:
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

        start_date = datetime.fromisoformat(schedule.meta.startDate)
        delta = (now.date() - start_date.date()).days
        return delta // 7 + 1

    @staticmethod
    def _is_in_week(weeks: Union[str, int, list[int], None], current_week: int, max_week_cycle: int = 1) -> bool:
        """
        判断某个 weeks 字段是否包含当前周
        - "all" 或 WeekType.ALL → 永远 True
        - None → 永远 True（等于没限制）
        - int → 当前周 == int
        - list[int] → 当前周 in list
        :arg weeks: 限制周数的字段
        :arg current_week: 当前周
        """
        if weeks is None:
            return True

        if isinstance(weeks, str):
            return weeks == WeekType.ALL.value
        if isinstance(weeks, int):
            return current_week >= weeks and ((current_week - weeks) % max_week_cycle == 0)  # 补做
        if isinstance(weeks, list):
            return current_week in weeks

        return False

