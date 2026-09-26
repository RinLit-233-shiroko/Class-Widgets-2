from copy import deepcopy
from datetime import datetime, timedelta
from typing import Optional

from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer
from PySide6.QtQml import QJSValue
from loguru import logger

from src.core.schedule import ScheduleData, Subject, Timeline, Entry, EntryType
from src.core.schedule import ScheduleManager
from src.core.schedule.model import (
    Timetable,
    WeekType,
    normalize_week_rule,
    week_rule_matches,
    week_rules_equal,
)
from src.core.utils import generate_id, get_default_subjects


def _jsvalue_to_python(value):
    """
    将 QML 传来的 QVariant / QJSValue 转成 Python 原生类型
    支持 int, str, list[int], list[str] 等
    """
    if isinstance(value, QJSValue):
        if value.isArray():
            length = value.property("length").toInt()
            return [value.property(str(i)).toVariant() for i in range(length)]
        elif value.isString():
            return value.toString()
        elif value.isNumber():
            return int(value.toNumber())
        elif value.isBool():
            return value.toBool()
        else:
            return None
    return value


class ScheduleEditor(QObject):
    updated = Signal()
    subjectsChanged = Signal()
    daysChanged = Signal()
    entriesChanged = Signal()
    metaChanged = Signal()
    overridesChanged = Signal()
    overridesRevisionChanged = Signal()
    dirtyChanged = Signal()
    scheduleFilesChanged = Signal()

    def __init__(self, manager: ScheduleManager):
        super().__init__()
        self.manager = manager
        self._filename = manager.schedule_path.stem
        self.schedule: ScheduleData = self.manager.schedule
        self._dirty = False
        self._entries_revision = 0
        self._overrides_revision = 0
        self._days_data: list[dict] = []
        self._entries_data: list[dict] = []
        self._suppress_update = False
        self._refresh_timer = QTimer(self)
        self._refresh_timer.setSingleShot(True)
        self._refresh_timer.setInterval(100)
        self._refresh_timer.timeout.connect(self.refresh_manager)
        self._rebuild_schedule_caches()
        self.updated.connect(self._on_updated)
        self.manager.scheduleSwitched.connect(self.refresh)
        self.manager.schedulesChanged.connect(self.scheduleFilesChanged)

    @Slot("QVariantList", result=bool)
    def duplicateSchedules(self, names: list) -> bool:
        """编辑器首页的批量复制入口。"""
        return self.manager.duplicateSchedules(names)

    @Slot("QVariantList", str, result=bool)
    def exportSchedules(self, names: list, format_id: str = "json") -> bool:
        """编辑器首页的批量导出入口。format_id 支持 "json"（CW2）与 "cses"。"""
        return self.manager.exportSchedules(names, format_id)

    @Slot("QVariantList", result=bool)
    def deleteSchedules(self, names: list) -> bool:
        """编辑器首页的批量删除入口。当前课表会由管理器保留。"""
        return self.manager.deleteSchedules(names)

    def _validate_time_range(self, start_time: str, end_time: str) -> bool:
        """
        验证时间范围，确保结束时间不早于开始时间
        
        Args:
            start_time: 开始时间字符串，格式为 "HH:MM"
            end_time: 结束时间字符串，格式为 "HH:MM"
            
        Returns:
            bool: 如果时间范围有效返回True，否则返回False
        """
        try:
            start = datetime.strptime(start_time, "%H:%M").time()
            end = datetime.strptime(end_time, "%H:%M").time()
            
            # 结束时间必须晚于开始时间
            if end <= start:
                logger.warning(f"Invalid time range: end time {end_time} is not later than start time {start_time}")
                return False
                
            return True
        except ValueError as e:
            logger.error(f"Invalid time format: {e}")
            return False

    def refresh(self, schedule: ScheduleData):  # 接受来自 manager 的更新
        self._refresh_timer.stop()
        self.schedule = schedule
        self._filename = self.manager.schedule_path.stem
        self._rebuild_schedule_caches()
        self._dirty = False
        self._suppress_update = True
        self.updated.emit()
        self._suppress_update = False
        self.subjectsChanged.emit()
        self.daysChanged.emit()
        self._entries_revision += 1
        self.entriesChanged.emit()
        self.metaChanged.emit()
        self.overridesChanged.emit()
        self._overrides_revision += 1
        self.overridesRevisionChanged.emit()

    def _on_updated(self):
        if self._suppress_update:
            return
        self._dirty = True
        self.dirtyChanged.emit()
        self._refresh_timer.start()

    def _rebuild_schedule_caches(self):
        if not self.schedule:
            self._days_data = []
            self._entries_data = []
            return
        self._days_data = [day.model_dump() for day in self.schedule.days]
        self._entries_data = self._days_data

    def _emit_days_changed(self):
        self._rebuild_schedule_caches()
        self.daysChanged.emit()

    def _emit_entries_changed(self, changed_day: Optional[Timeline] = None):
        """Refresh the QML entry cache without serializing unrelated days."""
        if not self.schedule:
            self._entries_data = []
        elif changed_day is None:
            # Some operations (for example removing a subject) can affect
            # entries in multiple days, so those callers request a full sync.
            self._entries_data = [day.model_dump() for day in self.schedule.days]
        else:
            day_index = next(
                (i for i, day in enumerate(self.schedule.days)
                 if day.id == changed_day.id),
                -1,
            )
            if day_index < 0:
                self._entries_data = [day.model_dump() for day in self.schedule.days]
            else:
                entries_data = self._entries_data.copy()
                entries_data[day_index] = changed_day.model_dump()
                self._entries_data = entries_data
        self._entries_revision += 1
        self.entriesChanged.emit()

    def refresh_manager(self):
        self.manager.modify(self.schedule)  # 提交给 manager

    # Subject 操作
    @Slot(str, str, str, str, str, bool, result=str)
    def addSubject(self, name: str, teacher: str = "", icon: str = "", color: str = "",
                   location: str = "", is_local_classroom: bool = True) -> str:
        """添加科目"""
        subject = Subject(
            id=generate_id("subj"),
            name=name,
            teacher=teacher or None,
            icon=icon or None,
            color=color or None,
            location=location or None,
            isLocalClassroom=is_local_classroom
        )
        self.schedule.subjects.append(subject)
        self.updated.emit()
        self.subjectsChanged.emit()
        return subject.id

    @Slot(str, str, str, str, str, str, str, bool)
    def updateSubject(self, subject_id: str, name: str = "", simplified_name: str = "", teacher: str = "",
                      icon: str = "", color: str = "", location: str = "", is_local_classroom: bool = True) -> None:
        """更新科目"""
        subject = self.getSubject(subject_id)
        if not subject:
            return

        changes = {
            "name": name or subject.name,
            "simplifiedName": simplified_name or subject.simplifiedName,
            "icon": icon or None,
            "color": color or None,
            "teacher": teacher or None,
            "location": location or None,
            "isLocalClassroom": is_local_classroom,
        }
        if all(getattr(subject, field) == value for field, value in changes.items()):
            return

        for field, value in changes.items():
            setattr(subject, field, value)
        self.updated.emit()
        self.subjectsChanged.emit()

    @Slot(str)
    def removeSubject(self, subject_id: str) -> None:
        """删除科目"""
        self.removeSubjects([subject_id])

    @Slot("QVariantList", result=int)
    def removeSubjects(self, subject_ids: list) -> int:
        """批量删除科目，并移除引用这些科目的课程条目。返回实际删除的科目数量。

        单个与批量共用这一条路径，保证两者对课程条目的清理行为完全一致。
        """
        if not self.schedule:
            return 0

        targets = {str(sid) for sid in (subject_ids or []) if str(sid)}
        if not targets:
            return 0

        removed = [s for s in self.schedule.subjects if s.id in targets]
        if not removed:
            return 0

        self.schedule.subjects = [
            s for s in self.schedule.subjects if s.id not in targets
        ]
        # 删除相关的课程条目
        for day in self.schedule.days:
            day.entries = [e for e in day.entries if e.subjectId not in targets]

        self._emit_entries_changed()
        self.updated.emit()
        self.subjectsChanged.emit()
        return len(removed)

    @Slot(str, result="QVariant")
    def getSubject(self, subject_id: str) -> Optional[Subject]:
        """获取科目信息"""
        return next((s for s in self.schedule.subjects if s.id == subject_id), None)

    # Day 操作
    @Slot(list, "QVariant", str, result=str)
    def addDay(self, day_of_week: Optional[list[int]] = None, weeks=None, date: str = "") -> str:
        """添加日程"""
        day = Timeline(
            id=generate_id("day"),
            entries=[],
            dayOfWeek=day_of_week or None,
            weeks=normalize_week_rule(_jsvalue_to_python(weeks)),
            date=date or None
        )
        self.schedule.days.append(day)
        self._emit_days_changed()
        self._entries_revision += 1
        self.entriesChanged.emit()
        self.updated.emit()
        return day.id

    @Slot(str, list, "QVariant", str)
    def updateDay(self, day_id: str, day_of_week: Optional[list[int]] = None,
                   weeks: WeekType | str | list[int] | Optional[int] = None, date: str = "") -> None:
        """更新日程"""
        day = self.getDay(day_id)
        if not day:
            return

        # The editor submits the complete mode state. Clear fields from the
        # previous mode so a stale date cannot keep taking precedence.
        day.dayOfWeek = day_of_week or None
        if weeks is not None:
            weeks = normalize_week_rule(_jsvalue_to_python(weeks))
            if weeks == WeekType.ALL:
                day.weeks = WeekType.ALL
            else:
                day.weeks = weeks
        day.date = date or None
        self._emit_days_changed()
        self._entries_revision += 1
        self.entriesChanged.emit()
        self.updated.emit()

    @Slot(str)
    def removeDay(self, day_id: str) -> None:
        """删除日程"""
        day = self.getDay(day_id)
        if not day:
            logger.warning(f"Day: {day_id} not found")
            return

        self.schedule.days.remove(day)
        self._emit_days_changed()
        self._entries_revision += 1
        self.entriesChanged.emit()
        self.updated.emit()

    @Slot(str, result=str)
    def duplicateDay(self, day_id: str) -> Optional[str]:
        """
        复制指定时间线
        """
        original_day = self.getDay(day_id)
        if not original_day:
            logger.warning(f"Day to duplicate not found: {day_id}")
            return None

        new_day = deepcopy(original_day)
        new_day.id = generate_id("day")  # 生成新的 day id

        # 为 entries 生成新的 id
        for entry in new_day.entries:
            entry.id = generate_id("entry")

        self.schedule.days.append(new_day)
        self._emit_days_changed()
        self._entries_revision += 1
        self.entriesChanged.emit()
        self.updated.emit()
        return new_day.id

    @Slot(str, result="QVariant")
    def getDay(self, day_id: str) -> Optional[Timeline]:
        """获取日程信息"""
        return next((d for d in self.schedule.days if d.id == day_id), None)

    # Entry 操作
    @Slot(str, str, str, str, str, str, result=str)
    def addEntry(self, day_id: str, entry_type: str,
                  start_time: str, end_time: str,
                  subject_id: str = "", title: str = "") -> str:
        """添加条目"""
        day = self.getDay(day_id)
        if not day:
            return ""

        # 验证时间范围
        if not self._validate_time_range(start_time, end_time):
            logger.error(f"Cannot add entry: invalid time range {start_time} - {end_time}")
            return ""

        entry = Entry(
            id=generate_id("entry"),
            type=EntryType(entry_type),
            startTime=start_time,
            endTime=end_time,
            subjectId=subject_id or None,
            title=title or None
        )
        day.entries.append(entry)
        day.entries.sort(key=lambda e: e.startTime)  # 排序
        self._emit_entries_changed(day)
        self.updated.emit()
        return entry.id

    @Slot(str, str, str, str, str, str)
    def updateEntry(self, entry_id: str,
                     entry_type: str = "", start_time: str = "",
                     end_time: str = "", subject_id: str = "",
                     title: str = "") -> None:
        """更新条目"""
        entry = self.getEntry(entry_id)
        if not entry:
            logger.warning(f"Entry: {entry_id} not found")
            return

        # 如果提供了时间参数，需要验证时间范围
        current_start = start_time if start_time else entry.startTime
        current_end = end_time if end_time else entry.endTime
        
        if start_time or end_time:
            if not self._validate_time_range(current_start, current_end):
                logger.error(f"Cannot update entry: invalid time range {current_start} - {current_end}")
                return

        if entry_type:
            entry.type = EntryType(entry_type)
        if start_time:
            entry.startTime = start_time
        if end_time:
            entry.endTime = end_time
        entry.subjectId = subject_id
        entry.title = title

        changed_day = None
        for day in self.schedule.days:  # 排序
            if entry in day.entries:
                day.entries.sort(key=lambda e: e.startTime)
                changed_day = day
                break
        self._emit_entries_changed(changed_day)
        self.updated.emit()

    @Slot(str)
    def removeEntry(self, entry_id: str) -> None:
        """删除条目"""
        for day in self.schedule.days:
            entry = next((e for e in day.entries if e.id == entry_id), None)
            if entry:
                day.entries.remove(entry)
                self._emit_entries_changed(day)
                self.updated.emit()
                return

    @Slot(str, result="QVariant")
    def getEntry(self, entry_id: str) -> Optional[Entry]:
        """获取条目信息"""
        for day in self.schedule.days:
            entry = next((e for e in day.entries if e.id == entry_id), None)
            if entry:
                return entry
        return None

    # Override
    @Slot(str, list, "QVariant", result=str)
    def findOverride(self, entry_id: str, day_of_week, weeks) -> Optional[str]:
        """
        查找已有 override，返回其 id，如不存在返回空字符串
        """
        day_of_week_list = day_of_week or None
        weeks = normalize_week_rule(_jsvalue_to_python(weeks))
        for o in self.schedule.overrides:
            if o.entryId != entry_id:
                continue
            if o.dayOfWeek != day_of_week_list:
                continue
            # `None` and "all" both mean "every week", so they must match.
            if not week_rules_equal(o.weeks, weeks):
                continue
            return o.id
        return None

    @Slot(str, list, "QVariant", str, str, result=bool)
    def addOverride(self, entry_id: str, day_of_week, weeks, subject_id="", title=""):
        weeks = normalize_week_rule(_jsvalue_to_python(weeks))
        override = Timetable(
            id=generate_id("override"),
            entryId=entry_id,
            dayOfWeek=day_of_week,
            weeks=weeks,
            subjectId=subject_id or None,
            title=title or None
        )
        self.schedule.overrides.append(override)
        self.overridesChanged.emit()
        self._overrides_revision += 1
        self.overridesRevisionChanged.emit()
        self.updated.emit()
        return True

    @Slot(str, str, str, result=bool)
    def updateOverride(self, override_id: str, subject_id=None, title=None):
        for o in self.schedule.overrides:
            if o.id == override_id:
                if subject_id is not None:
                    o.subjectId = subject_id
                if title is not None:
                    o.title = title
                self.overridesChanged.emit()
                self._overrides_revision += 1
                self.overridesRevisionChanged.emit()
                self.updated.emit()
                return True
        return False

    @Slot(str, result=bool)
    def removeOverride(self, override_id: str):
        for override in self.schedule.overrides:
            if override.id == override_id:
                self.schedule.overrides.remove(override)
                self.overridesChanged.emit()
                self._overrides_revision += 1
                self.overridesRevisionChanged.emit()
                self.updated.emit()
                return True
        return False

    @Slot(str, result=str)
    def subjectNameById(self, subject_id: str) -> Optional[str]:
        """根据 ID 获取科目名称"""
        subject = self.getSubject(subject_id)
        if subject:
            return subject.name
        return None

    @staticmethod
    def _weeks_match(weeks, week_list: list[int], max_week_cycle: int) -> bool:
        """Return whether a timeline applies to one of the given absolute weeks.

        ``week_rule_matches`` is the single source of truth here: an integer is
        a position inside ``maxWeekCycle`` (多周轮换), a list is a set of
        absolute semester weeks (指定周), and ``odd`` / ``even`` is the absolute
        parity (单双周). An empty specific list matches no week at all and must
        never fall back to "every week".
        """
        if weeks is None:
            return True
        rule = normalize_week_rule(weeks)
        if rule is None:
            return False
        return any(week_rule_matches(rule, week, max_week_cycle) for week in week_list)

    @classmethod
    def _override_priority(
        cls,
        override: Timetable,
        week_list: list[int],
        day_of_week: int,
        max_week_cycle: int,
    ) -> Optional[int]:
        """Return how specific an applicable override is, or ``None``.

        A specific-week list (3) wins over a cycle position or parity rule (2),
        which wins over an unrestricted rule (1).
        """
        if override.dayOfWeek and day_of_week not in override.dayOfWeek:
            return None

        rule = normalize_week_rule(override.weeks)
        if rule is None:
            # No rule at all means the override applies to every week.
            return 1
        if not any(
            week_rule_matches(rule, week, max_week_cycle) for week in week_list
        ):
            return None
        if rule == WeekType.ALL:
            return 1
        if isinstance(rule, list):
            return 3
        # Integer cycle position or odd/even parity.
        return 2

    def _resolve_entry_override(
        self,
        entry: Entry,
        week_list: list[int],
        day_of_week: int,
        overrides: list[Timetable],
    ) -> dict:
        data = entry.model_dump()
        max_week_cycle = max(1, self.schedule.meta.maxWeekCycle)
        applicable = []
        for override in overrides:
            if override.entryId != entry.id:
                continue
            priority = self._override_priority(
                override, week_list, day_of_week, max_week_cycle
            )
            if priority is not None:
                applicable.append((priority, override))

        # Apply matching overrides from least to most specific. Overrides are
        # field-wise, matching the existing single-entry resolution behavior.
        subject_overridden = False
        title_overridden = False
        for _, override in sorted(applicable, key=lambda item: item[0]):
            if override.subjectId:
                data["subjectId"] = override.subjectId
                subject_overridden = True
            if override.title:
                data["title"] = override.title
                title_overridden = True
            if override.startTime:
                data["startTime"] = override.startTime
            if override.endTime:
                data["endTime"] = override.endTime
        if subject_overridden and not title_overridden:
            data["title"] = None
        return data

    @Slot(str, int, int, result="QVariant")
    def getEntryOverride(self, entry_id: str, week: int, day_of_week: int):
        entry = self.getEntry(entry_id)
        if not entry:
            return None
        week = _jsvalue_to_python(week)
        week_list = week if isinstance(week, list) else [week]
        return self._resolve_entry_override(
            entry, week_list, day_of_week, self.schedule.overrides
        )

    @Slot(int, result="QVariant")
    def getEffectiveEntries(self, week: int) -> list[list[dict]]:
        """Return effective class entries for all seven columns at once."""
        if not self.schedule:
            return []

        week = _jsvalue_to_python(week)
        week_list = week if isinstance(week, list) else [week]
        max_week_cycle = max(1, self.schedule.meta.maxWeekCycle)

        overrides_by_entry: dict[str, list[Timetable]] = {}
        for override in self.schedule.overrides:
            overrides_by_entry.setdefault(override.entryId, []).append(override)

        columns: list[list[dict]] = []
        # ISO weekday order, Monday ... Sunday, matching the editor table's
        # Monday-first columns: column index i is dayOfWeek i + 1.
        for day_of_week in (1, 2, 3, 4, 5, 6, 7):
            # The editor receives an absolute semester week.  Match the QML
            # calendar exactly: find the seven-day block from startDate, then
            # normalize that block to its Monday before resolving columns.
            try:
                block_start = datetime.strptime(
                    self.schedule.meta.startDate, "%Y-%m-%d"
                ).date() + timedelta(days=(week_list[0] - 1) * 7)
                week_start = block_start - timedelta(days=block_start.weekday())
                current_date = week_start + timedelta(days=day_of_week - 1)
                date_str = current_date.isoformat()
            except (TypeError, ValueError, IndexError):
                date_str = None

            # A weekday may be described by several timelines at once, for
            # example an all-week skeleton plus an independent parity or
            # specific-week timeline.  Keep the same merge semantics as
            # ScheduleServices: later timelines replace entries occupying the
            # same time slot, while disjoint entries are retained.
            matched_days = []
            for candidate in self.schedule.days:
                if candidate.date:
                    if candidate.date == date_str:
                        matched_days.append((4, candidate))
                    continue
                if (
                    (not candidate.dayOfWeek or day_of_week in candidate.dayOfWeek)
                    and self._weeks_match(candidate.weeks, week_list, max_week_cycle)
                ):
                    rule = normalize_week_rule(candidate.weeks)
                    if rule is None or rule == WeekType.ALL:
                        priority = 1
                    elif isinstance(rule, int) or rule in (WeekType.ODD, WeekType.EVEN):
                        priority = 2
                    else:
                        priority = 3
                    matched_days.append((priority, candidate))
            if not matched_days:
                columns.append([])
                continue

            merged: dict[tuple[str, str], Entry] = {}
            for _, day in sorted(matched_days, key=lambda item: item[0]):
                for entry in day.entries:
                    if entry.type == EntryType.CLASS:
                        merged[(entry.startTime, entry.endTime)] = entry

            columns.append(
                [
                    self._resolve_entry_override(
                        entry,
                        week_list,
                        day_of_week,
                        overrides_by_entry.get(entry.id, []),
                    )
                    for entry in sorted(
                        merged.values(), key=lambda item: item.startTime
                    )
                ]
            )

        return columns

    @Slot(str, "QVariant", int, result=str)
    def getOverrideTitle(self, entry_id: str, week, day_of_week: int) -> str:
        """Return only the title explicitly supplied by a matching override."""
        week = _jsvalue_to_python(week)
        week_list = week if isinstance(week, list) else [week]
        max_week_cycle = max(1, self.schedule.meta.maxWeekCycle or 1)
        titles = []
        for o in self.schedule.overrides:
            if o.entryId != entry_id:
                continue
            priority = self._override_priority(
                o, week_list, day_of_week, max_week_cycle
            )
            if priority is not None and o.title:
                titles.append((priority, o.title))
        return sorted(titles, key=lambda item: item[0])[-1][1] if titles else ""

    @Slot(str, result=bool)
    def setStartDate(self, date_str: str) -> bool:
        """
        设置开学日期，格式: yyyy-mm-dd
        """
        try:
            datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            logger.warning(f"Invalid date format: {date_str}")
            return False

        if not self.schedule or not self.schedule.meta:
            logger.warning("No schedule or meta data available.")
            return False

        self.schedule.meta.startDate = date_str
        self.metaChanged.emit()
        self.updated.emit()
        return True

    @Slot(str, int, result=bool)
    def setTimelineSettings(self, date_str: str, max_weeks: int) -> bool:
        """一次性更新时间线设置，避免一次确认触发多次全局刷新。"""
        try:
            datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            logger.warning(f"Invalid date format: {date_str}")
            return False

        if not self.schedule or not self.schedule.meta or max_weeks < 1:
            logger.warning("Invalid schedule meta data or max week cycle.")
            return False

        changed = (
            self.schedule.meta.startDate != date_str
            or self.schedule.meta.maxWeekCycle != max_weeks
        )
        if not changed:
            return True

        self.schedule.meta.startDate = date_str
        self.schedule.meta.maxWeekCycle = max_weeks
        self.metaChanged.emit()
        self.updated.emit()
        return True

    @Slot(result=str)
    def getStartDate(self) -> str:
        """
        获取当前开学日期
        """
        if not self.schedule or not self.schedule.meta:
            return datetime.now().strftime("%Y-%m-%d")
        return getattr(self.schedule.meta, "startDate", datetime.now().strftime("%Y-%m-%d"))

    @Slot(result=bool)
    def restoreDefaultSubjects(self):
        """加载默认学科"""
        default_subjects = get_default_subjects()
        self.schedule.subjects.clear()
        for subj in default_subjects:
            self.schedule.subjects.append(subj)
        self.updated.emit()
        self.subjectsChanged.emit()

    @Slot(int, result=bool)
    def setMaxWeekCycle(self, max_weeks: int):
        """设置最大周数"""
        if not self.schedule or not self.schedule.meta:
            logger.warning("No schedule or meta data available.")
            return False

        self.schedule.meta.maxWeekCycle = max_weeks
        self.metaChanged.emit()
        self.updated.emit()
        return True

    @Slot(result=int)
    def getMaxWeekCycle(self) -> int:
        """获取最大周数"""
        if not self.schedule or not self.schedule.meta:
            return 1
        return getattr(self.schedule.meta, "maxWeekCycle", 1)

    # 数据访问
    @Property("QVariant", notify=metaChanged)
    def meta(self) -> dict:
        """获取课程表元数据"""
        if not self.schedule or not self.schedule.meta:
            return {}
        return self.schedule.meta.model_dump()

    @Property(list, notify=subjectsChanged)
    def subjects(self) -> list[dict]:
        """获取所有科目"""
        if not self.schedule:
            return []
        return [subject.model_dump() for subject in self.schedule.subjects]

    @Property(list, notify=daysChanged)
    def days(self) -> list[dict]:
        """获取所有日程"""
        return self._days_data

    @Property(int, notify=entriesChanged)
    def entriesRevision(self) -> int:
        """条目变化版本，用于刷新依赖嵌套 entries 的 QML 绑定。"""
        return self._entries_revision

    @Property(list, notify=entriesChanged)
    def entriesData(self) -> list[dict]:
        """获取包含最新条目的日程快照，不触发时间线列表刷新。"""
        return self._entries_data

    @Property(list, notify=overridesChanged)
    def overrides(self) -> list[Timetable]:
        """获取所有条目"""
        if not self.schedule:
            return []

        return [override.model_dump() for override in self.schedule.overrides]

    @Property(int, notify=overridesRevisionChanged)
    def overridesRevision(self) -> int:
        """Override content version for refreshing QML bindings."""
        return self._overrides_revision

    @Property("QVariant", notify=updated)
    def scheduleData(self) -> dict:
        """获取完整的课程表数据"""
        if not self.schedule:
            return {}
        return self.schedule.model_dump()

    @Property("QVariant", notify=updated)
    def path(self) -> str:
        """获取课程表文件路径"""
        return self.manager.schedule_path.as_uri()

    @Property("QVariant", notify=updated)
    def filename(self) -> str:
        """获取课程表文件名"""
        return self._filename

    @Slot()
    def markSaved(self):
        """标记为已保存"""
        self._refresh_timer.stop()
        if self._dirty:
            self._dirty = False
            self.dirtyChanged.emit()

    @Property(bool, notify=dirtyChanged)
    def dirty(self) -> bool:
        """检查是否有未保存的更改"""
        return self._dirty

