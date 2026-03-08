"""
Class Swap Manager - 换课管理器

临时换课功能核心逻辑：
- 通过操作 schedule 的 overrides 实现换课
- 持久化换课记录到 configs.json
- 跨天时自动清理临时课表
"""
import json
from copy import deepcopy
from datetime import datetime
from typing import Optional, TYPE_CHECKING

from PySide6.QtCore import QObject, Signal, Slot, Property
from loguru import logger

from src.core.schedule.model import (
    ScheduleData, Timeline, Entry, EntryType, Subject, Timetable, WeekType
)
from src.core.schedule.service import ScheduleServices
from src.core.utils import generate_id, get_week_number, get_cycle_week

if TYPE_CHECKING:
    from src.core.central import AppCentral


class ClassSwapManager(QObject):
    """换课管理器，管理临时换课操作"""
    updated = Signal()
    swapCommitted = Signal()  # 换课提交成功

    def __init__(self, app_central: "AppCentral"):
        super().__init__()
        self.app_central: "AppCentral" = app_central
        self.services: ScheduleServices = ScheduleServices(app_central)

        # 换课操作记录（用于持久化）
        self._swap_records: list[dict[str, str | int]] = []
        # 当前换课日期
        self._swap_date: str = ""

    # ── 数据查询 ────────────────────────────────────────────

    @Slot(int, int, result=list)
    def getDayEntries(self, day_of_week: int, week_of_cycle: int) -> list:
        """
        获取指定 星期+周次 的当日课程列表（已应用 override）
        只返回 class/activity 类型条目

        Args:
            day_of_week: 星期几 (1-7)
            week_of_cycle: 周期内第几周 (1-based)
        Returns:
            list[dict]: 当日课程条目
        """
        return self._get_day_entries(day_of_week, week_of_cycle, include_non_class=False)

    @Slot(result=list)
    def getAllSubjects(self) -> list:
        """获取所有科目列表（用于课程选择池）"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return []
        return [s.model_dump() for s in schedule.subjects]

    @Slot(result=int)
    def getCurrentDayOfWeek(self) -> int:
        """获取当前星期几"""
        return datetime.now().isoweekday()

    @Slot(result=int)
    def getCurrentWeekOfCycle(self) -> int:
        """获取当前周期内第几周"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule or not schedule.meta.startDate:
            return 1
        week = get_week_number(schedule.meta.startDate, datetime.now())
        return get_cycle_week(week, schedule.meta.maxWeekCycle or 1)

    @Slot(result=int)
    def getPreferredDayOfWeek(self) -> int:
        """获取换课界面上次选择的星期（默认今天）"""
        swap_data = getattr(self.app_central.configs.schedule, "class_swap", None)
        if isinstance(swap_data, dict):
            val = swap_data.get("day_of_week")
            if isinstance(val, int) and 1 <= val <= 7:
                return val
        return self.getCurrentDayOfWeek()

    @Slot(result=int)
    def getPreferredWeekOfCycle(self) -> int:
        """获取换课界面上次选择的周期周（默认当前周期周）"""
        swap_data = getattr(self.app_central.configs.schedule, "class_swap", None)
        max_cycle = self.getMaxWeekCycle()
        if isinstance(swap_data, dict):
            val = swap_data.get("week_of_cycle")
            if isinstance(val, int) and 1 <= val <= max_cycle:
                return val
        return self.getCurrentWeekOfCycle()

    @Slot(int, int)
    def setSwapPickerContext(self, day_of_week: int, week_of_cycle: int):
        """保存换课界面当前选择的 星期/周期周"""
        if day_of_week < 1 or day_of_week > 7:
            return

        max_cycle = self.getMaxWeekCycle()
        if week_of_cycle < 1 or week_of_cycle > max_cycle:
            week_of_cycle = 1

        swap_data = getattr(self.app_central.configs.schedule, "class_swap", None)
        if not isinstance(swap_data, dict):
            swap_data = {}

        swap_data["day_of_week"] = day_of_week
        swap_data["week_of_cycle"] = week_of_cycle
        swap_data["date"] = datetime.now().strftime("%Y-%m-%d")
        self.app_central.configs.set("schedule.class_swap", swap_data)

    @Slot(int, int, result=bool)
    def applyPickerToToday(self, day_of_week: int, week_of_cycle: int) -> bool:
        """将换课界面当前选择的 星期/周次 课表立即投射到今天"""
        logger.debug(f"Applying picker context to today: day_of_week={day_of_week}, week_of_cycle={week_of_cycle}")
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return False

        max_cycle = schedule.meta.maxWeekCycle or 1
        if day_of_week < 1 or day_of_week > 7:
            return False
        if week_of_cycle < 1 or week_of_cycle > max_cycle:
            week_of_cycle = 1

        self.setSwapPickerContext(day_of_week, week_of_cycle)

        apply_day_of_week = self.getCurrentDayOfWeek()
        apply_week_of_cycle = self.getCurrentWeekOfCycle()

        # ComboBox 切换时，先清理“今天”已有的临时 swap 覆盖，再整天投射
        self._clear_today_swap_overrides(apply_day_of_week, apply_week_of_cycle)
        self._apply_day_schedule_to_today(
            day_of_week,
            week_of_cycle,
            apply_day_of_week,
            apply_week_of_cycle,
        )

        self.updated.emit()
        return True

    @Slot(result=int)
    def getMaxWeekCycle(self) -> int:
        """获取最大周期"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return 1
        return schedule.meta.maxWeekCycle or 1

    @Slot(str, result=str)
    def getSubjectName(self, subject_id: str) -> str:
        """根据 subjectId 获取科目名"""
        subj = self._find_subject(subject_id)
        return subj.name if subj else ""

    # ── 换课操作 ─────────────────────────────────────────────

    @Slot(str, str, int, int, result=bool)
    def swapTwoEntries(self, entry_id_a: str, entry_id_b: str,
                       day_of_week: int, week_of_cycle: int) -> bool:
        """
        : 交换两节课的科目（dailyScheduleView 内互换）
        """
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return False

        max_cycle = schedule.meta.maxWeekCycle or 1
        apply_day_of_week = self.getCurrentDayOfWeek()
        apply_week_of_cycle = self.getCurrentWeekOfCycle()

        # 记录用户在换课界面的选择
        self.setSwapPickerContext(day_of_week, week_of_cycle)

        # 先把「所选星期+周次」课表整体应用到今天，再在今天执行换课
        self._apply_day_schedule_to_today(
            day_of_week,
            week_of_cycle,
            apply_day_of_week,
            apply_week_of_cycle,
        )

        # 将“基准日课表”的 entry 映射到“今天临时课表”对应位置
        apply_entry_id_a = self._map_entry_to_day(
            entry_id_a,
            day_of_week,
            week_of_cycle,
            apply_day_of_week,
            apply_week_of_cycle,
        )
        apply_entry_id_b = self._map_entry_to_day(
            entry_id_b,
            day_of_week,
            week_of_cycle,
            apply_day_of_week,
            apply_week_of_cycle,
        )

        if not apply_entry_id_a or not apply_entry_id_b:
            logger.warning("[ClassSwap] Cannot map selected entries to today's temporary schedule")
            return False

        # 获取两个 entry 当前应用 override 后的真实 subjectId
        real_a = self._get_effective_subject(entry_id_a, day_of_week, week_of_cycle, max_cycle)
        real_b = self._get_effective_subject(entry_id_b, day_of_week, week_of_cycle, max_cycle)

        if real_a is None or real_b is None:
            logger.warning("Cannot swap: one of the entries not found")
            return False

        weeks_val = apply_week_of_cycle if max_cycle > 1 else "all"

        # 作用到“今天”对应位置的临时课表
        self._set_or_update_override(
            apply_entry_id_a,
            [apply_day_of_week],
            weeks_val,
            real_b["subjectId"],
            real_b.get("title", ""),
        )
        self._set_or_update_override(
            apply_entry_id_b,
            [apply_day_of_week],
            weeks_val,
            real_a["subjectId"],
            real_a.get("title", ""),
        )

        # 记录
        self._add_swap_record("swap", apply_entry_id_a, apply_entry_id_b, real_a["subjectId"], real_b["subjectId"])

        self.swapCommitted.emit()
        self.updated.emit()
        return True

    @Slot(str, str, int, int, result=bool)
    def replaceEntry(self, entry_id: str, new_subject_id: str,
                     day_of_week: int, week_of_cycle: int) -> bool:
        """
        : 将某节课替换为指定科目
        """
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return False

        max_cycle = schedule.meta.maxWeekCycle or 1
        apply_day_of_week = self.getCurrentDayOfWeek()
        apply_week_of_cycle = self.getCurrentWeekOfCycle()

        # 记录用户在换课界面的选择
        self.setSwapPickerContext(day_of_week, week_of_cycle)

        # 先把「所选星期+周次」课表整体应用到今天，再在今天执行替换
        self._apply_day_schedule_to_today(
            day_of_week,
            week_of_cycle,
            apply_day_of_week,
            apply_week_of_cycle,
        )

        # 将“基准日课表”的 entry 映射到“今天临时课表”对应位置
        apply_entry_id = self._map_entry_to_day(
            entry_id,
            day_of_week,
            week_of_cycle,
            apply_day_of_week,
            apply_week_of_cycle,
        )
        if not apply_entry_id:
            logger.warning("[ClassSwap] Cannot map selected entry to today's temporary schedule")
            return False

        old_info = self._get_effective_subject(apply_entry_id, apply_day_of_week, apply_week_of_cycle, max_cycle)
        old_subject_id = old_info["subjectId"] if old_info else ""

        weeks_val = apply_week_of_cycle if max_cycle > 1 else "all"

        self._set_or_update_override(apply_entry_id, [apply_day_of_week], weeks_val, new_subject_id, "")

        self._add_swap_record("replace", apply_entry_id, "", old_subject_id, new_subject_id)

        self.swapCommitted.emit()
        self.updated.emit()
        return True

    # ── 持久化 ─────────────────────────────────────────────

    @Slot()
    def saveSwapRecords(self):
        """保存换课记录到配置"""
        today = datetime.now().strftime("%Y-%m-%d")
        current_swap_data = getattr(self.app_central.configs.schedule, "class_swap", None)
        day_of_week = self.getPreferredDayOfWeek()
        week_of_cycle = self.getPreferredWeekOfCycle()
        if isinstance(current_swap_data, dict):
            stored_day = current_swap_data.get("day_of_week")
            stored_week = current_swap_data.get("week_of_cycle")
            if isinstance(stored_day, int):
                day_of_week = stored_day
            if isinstance(stored_week, int):
                week_of_cycle = stored_week

        swap_data = {
            "date": today,
            "records": self._swap_records,
            "day_of_week": day_of_week,
            "week_of_cycle": week_of_cycle,
        }
        self.app_central.configs.set("schedule.class_swap", swap_data)
        logger.info(f"Swap records saved: {len(self._swap_records)} records")

    @Slot()
    def loadSwapRecords(self):
        """加载换课记录"""
        swap_data = getattr(self.app_central.configs.schedule, "class_swap", None)
        if not swap_data or not isinstance(swap_data, dict):
            self._swap_records = []
            self._swap_date = ""
            return

        day_of_week = swap_data.get("day_of_week") if isinstance(swap_data.get("day_of_week"), int) else self.getCurrentDayOfWeek()
        if not (1 <= day_of_week <= 7):
            day_of_week = self.getCurrentDayOfWeek()
        max_cycle = self.getMaxWeekCycle()
        week_of_cycle = swap_data.get("week_of_cycle") if isinstance(swap_data.get("week_of_cycle"), int) else self.getCurrentWeekOfCycle()
        if not (1 <= week_of_cycle <= max_cycle):
            week_of_cycle = self.getCurrentWeekOfCycle()

        saved_date = swap_data.get("date", "")
        today = datetime.now().strftime("%Y-%m-%d")

        if saved_date != today:
            # 跨天，清理临时课表
            logger.info(f"Swap records expired (saved: {saved_date}, today: {today}), cleaning up")
            self._cleanup_swap_overrides(swap_data.get("records", []))
            self._swap_records = []
            self._swap_date = ""
            # 清空配置（清理 day_of_week/week_of_cycle）
            self.app_central.configs.set("schedule.class_swap", {})
            return

        records = swap_data.get("records", [])
        self._swap_records = [self._normalize_swap_record(r) for r in records if isinstance(r, dict)]
        self._swap_date = saved_date
        self.setSwapPickerContext(day_of_week, week_of_cycle)
        self.saveSwapRecords()
        self._rebuild_overrides_from_records(self._swap_records)
        logger.info(f"Loaded {len(self._swap_records)} swap records for today")

    @Slot(result=bool)
    def hasTodaySwaps(self) -> bool:
        """今天是否有换课记录"""
        swap_data = getattr(self.app_central.configs.schedule, "class_swap", None)
        if not isinstance(swap_data, dict):
            return False

        logger.debug(f"Checking for today's swaps: swap_data={swap_data}")

        # 记录存在
        records = swap_data.get("records")
        if isinstance(records, list) and len(records) > 0:
            logger.debug(f"Found {len(records)} swap records for today")
            return True

        # 仅 picker 上下文（day/week）也视为存在临时课表
        day_of_week = swap_data.get("day_of_week")
        week_of_cycle = swap_data.get("week_of_cycle")
        if isinstance(day_of_week, int) and isinstance(week_of_cycle, int):
            logger.debug(f"Found swap picker context for today ({day_of_week}, {week_of_cycle})")
            return True

        logger.debug(f"swap records {self._swap_records}")

        return len(self._swap_records) > 0

    @Slot(result=list)
    def getSwapRecords(self) -> list:
        """获取今天的换课记录"""
        return self._swap_records

    @Slot()
    def discardTodaySwaps(self):
        """丢弃今天的换课（撤销所有换课 override）"""
        self._cleanup_swap_overrides(self._swap_records)
        self._swap_records = []
        self._swap_date = ""
        self.app_central.configs.set("schedule.class_swap", {})
        self.updated.emit()
        logger.info("All today's swaps discarded")

    # ── 内部方法 ─────────────────────────────────────────────

    def _find_subject(self, subject_id: str) -> Optional[Subject]:
        """查找科目"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule or not subject_id:
            return None
        for s in schedule.subjects:
            if s.id == subject_id:
                return s
        return None

    def _get_effective_subject(self, entry_id: str, day_of_week: int,
                               week_of_cycle: int, max_cycle: int) -> Optional[dict]:
        """获取某个 entry 在指定日期的实际科目（含 override）"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return None

        # 找原始 entry
        entry = None
        for day in schedule.days:
            for e in day.entries:
                if e.id == entry_id:
                    entry = e
                    break
            if entry:
                break

        if not entry:
            return None

        data = {"subjectId": entry.subjectId or "", "title": entry.title or ""}
        data["startTime"] = entry.startTime or ""
        data["endTime"] = entry.endTime or ""

        # 应用 override
        best_priority = -1
        for o in schedule.overrides:
            if o.entryId != entry_id:
                continue
            if o.dayOfWeek and day_of_week not in o.dayOfWeek:
                continue

            priority = self._get_override_priority(o.weeks, week_of_cycle, max_cycle)
            if priority > best_priority:
                best_priority = priority
                if o.subjectId:
                    data["subjectId"] = o.subjectId
                if o.title:
                    data["title"] = o.title
                if o.startTime:
                    data["startTime"] = o.startTime
                if o.endTime:
                    data["endTime"] = o.endTime

        return data

    def _get_override_priority(self, weeks, week_of_cycle: int, max_cycle: int) -> int:
        """计算 override 优先级"""
        if isinstance(weeks, list) and week_of_cycle in weeks:
            return 3
        elif isinstance(weeks, int) and week_of_cycle >= weeks and (week_of_cycle - weeks) % max_cycle == 0:
            return 2
        elif weeks == "all" or weeks is None:
            return 1
        return -1

    def _set_or_update_override(self, entry_id: str, day_of_week: list,
                                 weeks, subject_id: str, title: str,
                                 start_time: Optional[str] = None,
                                 end_time: Optional[str] = None):
        """设置或更新 override"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return

        # 查找已有 override
        for o in schedule.overrides:
            if o.entryId == entry_id and o.dayOfWeek == day_of_week:
                # 检查 weeks 匹配
                if o.weeks == weeks or (isinstance(weeks, str) and weeks == "all" and o.weeks is None):
                    o.subjectId = subject_id or None
                    o.title = title or None
                    if start_time is not None:
                        o.startTime = start_time or None
                    if end_time is not None:
                        o.endTime = end_time or None
                    self.app_central.schedule_manager.modify(schedule)
                    return

        # 新建 override
        override = Timetable(
            id=generate_id("swap"),
            entryId=entry_id,
            dayOfWeek=day_of_week,
            weeks=weeks,
            subjectId=subject_id or None,
            title=title or None,
            startTime=start_time,
            endTime=end_time,
        )
        schedule.overrides.append(override)
        self.app_central.schedule_manager.modify(schedule)

    def _add_swap_record(self, swap_type: str, entry_a: str, entry_b: str,
                          old_subject: str, new_subject: str):
        """添加换课记录"""
        record = {
            "type": swap_type,
            "entry_a": entry_a,
            "entry_b": entry_b,
            "old_subject": old_subject,
            "new_subject": new_subject,
            "timestamp": datetime.now().isoformat()
        }
        self._swap_records.append(record)
        self.saveSwapRecords()

    @staticmethod
    def _normalize_swap_record(record: dict) -> dict:
        """规范化换课记录，移除历史 day/week 冗余字段"""
        return {
            "type": record.get("type", "replace"),
            "entry_a": record.get("entry_a", ""),
            "entry_b": record.get("entry_b", ""),
            "old_subject": record.get("old_subject", ""),
            "new_subject": record.get("new_subject", ""),
            "timestamp": record.get("timestamp", datetime.now().isoformat()),
        }

    def _map_entry_to_day(self, source_entry_id: str,
                          source_day_of_week: int,
                          source_week_of_cycle: int,
                          target_day_of_week: int,
                          target_week_of_cycle: int) -> Optional[str]:
        """按 class/activity 顺序，将 source 日的 entry 映射到 target 日对应位置"""
        source_entries = self.getDayEntries(source_day_of_week, source_week_of_cycle)
        target_entries = self.getDayEntries(target_day_of_week, target_week_of_cycle)

        if not source_entries or not target_entries:
            return None

        source_idx = -1
        for idx, item in enumerate(source_entries):
            if item.get("id") == source_entry_id:
                source_idx = idx
                break

        if source_idx < 0:
            return None
        if source_idx >= len(target_entries):
            return None

        return target_entries[source_idx].get("id")

    def _apply_day_schedule_to_today(
            self,
            source_day_of_week: int,
            source_week_of_cycle: int,
            target_day_of_week: int,
            target_week_of_cycle: int,
    ):
        """将 source(星期+周次) 的课表按顺序投影到 target(今天)"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return

        max_cycle = schedule.meta.maxWeekCycle or 1
        weeks_val = target_week_of_cycle if max_cycle > 1 else "all"

        source_entries = self._get_day_entries(source_day_of_week, source_week_of_cycle, include_non_class=True)
        target_entries = self._get_day_entries(target_day_of_week, target_week_of_cycle, include_non_class=True)

        if not source_entries or not target_entries:
            logger.warning(
                f"[ClassSwap] apply day schedule failed: source={len(source_entries)}, target={len(target_entries)}"
            )
            return

        size = min(len(source_entries), len(target_entries))
        for idx in range(size):
            src = source_entries[idx]
            tgt = target_entries[idx]
            target_entry_id = tgt.get("id")
            if not target_entry_id:
                continue

            self._set_or_update_override(
                target_entry_id,
                [target_day_of_week],
                weeks_val,
                src.get("subjectId", "") or "",
                src.get("title", "") or "",
                src.get("startTime", "") or "",
                src.get("endTime", "") or "",
            )

    def _get_day_entries(self, day_of_week: int, week_of_cycle: int, include_non_class: bool) -> list:
        """获取指定 day/week 的条目（可选择是否包含非 class/activity）"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            logger.warning("[ClassSwap] getDayEntries: schedule is None")
            return []

        max_cycle = schedule.meta.maxWeekCycle or 1
        logger.info(
            f"[ClassSwap] getDayEntries request day={day_of_week}, week={week_of_cycle}, "
            f"days={len(schedule.days)}, overrides={len(schedule.overrides)}"
        )

        for day in schedule.days:
            day_of_week_list = [day.dayOfWeek] if isinstance(day.dayOfWeek, int) else day.dayOfWeek
            if day_of_week_list and day_of_week not in day_of_week_list:
                continue
            if not self._is_in_week(day.weeks, week_of_cycle, max_cycle):
                continue

            logger.info(
                f"[ClassSwap] matched timeline id={day.id}, entries={len(day.entries)}, "
                f"dayOfWeek={day.dayOfWeek}, weeks={day.weeks}"
            )

            day_copy = day.model_copy()
            day_copy.entries = [entry.model_copy() for entry in day.entries]

            for entry in day_copy.entries:
                for override in schedule.overrides:
                    if override.entryId != entry.id:
                        continue
                    if self._override_applies(override, day_of_week, week_of_cycle, max_cycle):
                        if override.subjectId:
                            entry.subjectId = override.subjectId
                        if override.title:
                            entry.title = override.title
                        if override.startTime:
                            entry.startTime = override.startTime
                        if override.endTime:
                            entry.endTime = override.endTime

            result = []
            for e in day_copy.entries:
                entry_type = e.type.value if isinstance(e.type, EntryType) else str(e.type)
                if (not include_non_class) and entry_type not in {EntryType.CLASS.value, EntryType.ACTIVITY.value}:
                    continue
                d = e.model_dump()
                subj = self._find_subject(e.subjectId)
                d["subjectName"] = subj.name if subj else (e.title or "")
                d["subjectColor"] = subj.color if subj else ""
                d["subjectIcon"] = subj.icon if subj else ""
                result.append(d)

            logger.info(f"[ClassSwap] return entries={len(result)}")
            return result

        logger.warning(
            f"[ClassSwap] no timeline matched for day={day_of_week}, week={week_of_cycle}, max_cycle={max_cycle}"
        )
        return []

    def _clear_today_swap_overrides(self, day_of_week: int, week_of_cycle: int):
        """清理今天（指定 day/week）已有 swap override，确保重新投射是全量快照"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return

        before = len(schedule.overrides)
        schedule.overrides = [
            o for o in schedule.overrides
            if not (
                o.id.startswith("swap_")
                and self._override_applies(o, day_of_week, week_of_cycle, schedule.meta.maxWeekCycle or 1)
            )
        ]
        after = len(schedule.overrides)
        if after != before:
            self.app_central.schedule_manager.modify(schedule)

    def _cleanup_swap_overrides(self, records: list):
        """清理换课产生的 override"""
        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return

        swap_ids = set()
        for o in schedule.overrides:
            if o.id.startswith("swap_"):
                swap_ids.add(o.id)

        if swap_ids:
            schedule.overrides = [o for o in schedule.overrides if o.id not in swap_ids]
            self.app_central.schedule_manager.modify(schedule)
            logger.info(f"Cleaned up {len(swap_ids)} swap overrides")

    def _rebuild_overrides_from_records(self, records: list):
        """根据持久化换课记录重建当天临时 override（应用启动后内存恢复）"""
        if not records:
            return

        schedule = self.app_central.schedule_manager.schedule
        if not schedule:
            return

        # 先清理已有 swap override，避免重复叠加
        self._cleanup_swap_overrides(records)

        max_cycle = schedule.meta.maxWeekCycle or 1
        apply_day_of_week = self.getCurrentDayOfWeek()
        apply_week_of_cycle = self.getCurrentWeekOfCycle()
        weeks_val = apply_week_of_cycle if max_cycle > 1 else "all"

        for record in records:
            try:
                swap_type = record.get("type")

                if swap_type == "swap":
                    entry_a = record.get("entry_a", "")
                    entry_b = record.get("entry_b", "")
                    old_subject = record.get("old_subject", "")
                    new_subject = record.get("new_subject", "")

                    if entry_a and new_subject:
                        self._set_or_update_override(
                            entry_a,
                            [apply_day_of_week],
                            weeks_val,
                            new_subject,
                            ""
                        )
                    if entry_b and old_subject:
                        self._set_or_update_override(
                            entry_b,
                            [apply_day_of_week],
                            weeks_val,
                            old_subject,
                            ""
                        )

                elif swap_type == "replace":
                    entry_id = record.get("entry_a", "")
                    new_subject = record.get("new_subject", "")
                    if entry_id and new_subject:
                        self._set_or_update_override(
                            entry_id,
                            [apply_day_of_week],
                            weeks_val,
                            new_subject,
                            ""
                        )
            except Exception as e:
                logger.warning(f"[ClassSwap] Failed to rebuild override from record: {record}, error: {e}")

    @staticmethod
    def _is_in_week(weeks, current_week: int, max_week_cycle: int = 1) -> bool:
        if weeks is None:
            return True
        if isinstance(weeks, str):
            return weeks == WeekType.ALL.value
        if isinstance(weeks, int):
            return current_week >= weeks and ((current_week - weeks) % max_week_cycle == 0)
        if isinstance(weeks, list):
            return current_week in weeks
        return False

    @staticmethod
    def _override_applies(override: Timetable, weekday: int, current_week: int,
                          max_week_cycle: int = 1) -> bool:
        if override.dayOfWeek:
            if weekday not in override.dayOfWeek:
                return False
        if override.weeks:
            if not ClassSwapManager._is_in_week(override.weeks, current_week, max_week_cycle):
                return False
        return True
