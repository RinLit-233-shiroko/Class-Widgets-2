"""用户可配置的本地自动化规则与安全的外部命令适配。"""
from __future__ import annotations

import json
import os
import platform
import shlex
import subprocess
import time
import uuid
from pathlib import Path
from typing import TYPE_CHECKING, Any

from loguru import logger
from pydantic import BaseModel, Field, field_validator
from PySide6.QtCore import Property, QProcess, Signal, Slot

from src.core import CONFIGS_PATH
from src.core.notification import NotificationProvider
from src.core.notification.model import NotificationLevel
from src.core.schedule import EntryType

from .base import AutomationTask

if TYPE_CHECKING:
    from src.core.central import AppCentral


TRIGGER_TYPES = {
    "app_started",
    "app_exiting",
    "process_started",
    "process_running",
    "process_exited",
    "class_started",
    "break_started",
    "school_dismissal",
    "noon_dismissal",
}
ACTION_TYPES = {"notification", "run_program"}


class AutomationTrigger(BaseModel):
    """单条自动化规则的触发器。"""

    type: str = "app_started"
    process_name: str = ""

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str) -> str:
        if value not in TRIGGER_TYPES:
            raise ValueError(f"Unsupported automation trigger: {value}")
        return value


class AutomationAction(BaseModel):
    """单条规则可执行的安全动作。外部程序始终以参数列表执行，绝不经由 Shell。"""

    id: str = Field(default_factory=lambda: uuid.uuid4().hex)
    type: str = "notification"
    title: str = "自动化提醒"
    message: str = ""
    program: str = ""
    arguments: list[str] = Field(default_factory=list)
    duration_ms: int = 8000

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str) -> str:
        if value not in ACTION_TYPES:
            raise ValueError(f"Unsupported automation action: {value}")
        return value

    @field_validator("title")
    @classmethod
    def validate_title(cls, value: str) -> str:
        return value.strip()[:80] or "自动化提醒"

    @field_validator("message")
    @classmethod
    def validate_message(cls, value: str) -> str:
        return value.strip()[:500]

    @field_validator("duration_ms")
    @classmethod
    def validate_duration(cls, value: int) -> int:
        return max(1000, min(int(value), 60000))


class AutomationRule(BaseModel):
    """用户可启停的规则。每条规则可包含多个动作。"""

    id: str = Field(default_factory=lambda: uuid.uuid4().hex)
    name: str = "新自动化"
    enabled: bool = True
    trigger: AutomationTrigger = Field(default_factory=AutomationTrigger)
    actions: list[AutomationAction] = Field(default_factory=lambda: [AutomationAction()])
    cooldown_seconds: int = 30

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        return value.strip()[:80] or "新自动化"

    @field_validator("cooldown_seconds")
    @classmethod
    def validate_cooldown(cls, value: int) -> int:
        return max(0, min(int(value), 86400))


class AutomationProfile(BaseModel):
    """一个独立保存在本地的自动化配置文件。"""

    id: str = Field(default_factory=lambda: uuid.uuid4().hex)
    name: str = "新自动化配置"
    enabled: bool = False
    rules: list[AutomationRule] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        return value.strip()[:80] or "新自动化配置"


class AutomationProfilesService(AutomationTask):
    """自动化配置文件运行器：按秒检测课程和进程状态。"""

    changed = Signal()
    DEFAULT_PROFILE_NAME = "新自动化配置"

    def __init__(self, app_central: "AppCentral") -> None:
        super().__init__(app_central)
        self._profiles: dict[str, AutomationProfile] = {}
        self._storage_dir = Path(CONFIGS_PATH) / "automation_profiles"
        self._running = False
        self._last_rule_run: dict[tuple[str, str], float] = {}
        self._last_processes: dict[str, set[int]] = {}
        self._process_snapshot_ready = False
        self._last_schedule_status = ""
        self._last_status_text = self.tr("尚未启动自动化服务")
        self._notification_provider = NotificationProvider(
            id="com.classwidgets.automation",
            name=self.tr("自动化"),
            icon="ic_fluent_branch_compare_20_regular",
            manager=app_central.notification,
            use_system_notify=True,
        )

    @property
    def name(self) -> str:
        return "UserAutomationProfiles"

    @Property(list, notify=changed)
    def profiles(self) -> list[dict[str, Any]]:
        return [profile.model_dump() for profile in self._profiles.values()]

    @Property(str, notify=changed)
    def statusText(self) -> str:
        return self._last_status_text

    @Property(bool, notify=changed)
    def running(self) -> bool:
        return self._running

    def start(self) -> None:
        if self._running:
            return
        self._load_profiles()
        self._running = True
        self._last_processes = {}
        self._process_snapshot_ready = False
        self._last_schedule_status = self._runtime_status()
        self._set_status(self.tr("自动化服务已启动；默认配置文件均为关闭状态"))
        self._dispatch_event("app_started")

    def stop(self) -> None:
        if not self._running:
            return
        self._dispatch_event("app_exiting")
        self._running = False
        self._set_status(self.tr("自动化服务已停止"))

    def update(self) -> None:
        if not self._running:
            return
        self._check_process_events()
        self._check_schedule_events()

    @Slot(str, result=str)
    def createProfile(self, name: str) -> str:
        profile = AutomationProfile(name=name or self.DEFAULT_PROFILE_NAME)
        self._profiles[profile.id] = profile
        self._save_profile(profile)
        self._set_status(self.tr("已创建自动化配置文件“{0}”；默认未启用").format(profile.name))
        return profile.id

    @Slot(str)
    def deleteProfile(self, profile_id: str) -> None:
        profile = self._profiles.pop(profile_id, None)
        if profile is None:
            return
        self._profile_path(profile_id).unlink(missing_ok=True)
        self._set_status(self.tr("已删除自动化配置文件“{0}”").format(profile.name))

    @Slot(str, bool)
    def setProfileEnabled(self, profile_id: str, enabled: bool) -> None:
        profile = self._get_profile(profile_id)
        if profile is None:
            return
        profile.enabled = bool(enabled)
        self._save_profile(profile)
        self._set_status(
            self.tr("已{0}自动化配置文件“{1}”").format(
                self.tr("启用") if profile.enabled else self.tr("停用"),
                profile.name,
            )
        )

    @Slot(str, str)
    def updateProfile(self, profile_id: str, name: str) -> None:
        profile = self._get_profile(profile_id)
        if profile is None:
            return
        profile.name = name
        self._save_profile(profile)
        self._set_status(self.tr("已保存自动化配置文件“{0}”").format(profile.name))

    @Slot(str, result=str)
    def addRule(self, profile_id: str) -> str:
        profile = self._get_profile(profile_id)
        if profile is None:
            return ""
        rule = AutomationRule(name=self.tr("新自动化"))
        profile.rules.append(rule)
        self._save_profile(profile)
        return rule.id

    @Slot(str, str)
    def deleteRule(self, profile_id: str, rule_id: str) -> None:
        profile = self._get_profile(profile_id)
        if profile is None:
            return
        profile.rules = [rule for rule in profile.rules if rule.id != rule_id]
        self._save_profile(profile)
        self.changed.emit()

    @Slot(str, str, bool)
    def setRuleEnabled(self, profile_id: str, rule_id: str, enabled: bool) -> None:
        rule = self._get_rule(profile_id, rule_id)
        if rule is None:
            return
        rule.enabled = bool(enabled)
        self._save_profile(self._profiles[profile_id])
        self.changed.emit()

    @Slot(str, str, str, str, str, int)
    def updateRule(
        self,
        profile_id: str,
        rule_id: str,
        name: str,
        trigger_type: str,
        process_name: str,
        cooldown_seconds: int,
    ) -> None:
        profile = self._get_profile(profile_id)
        rule = self._get_rule(profile_id, rule_id)
        if profile is None or rule is None:
            return
        try:
            rule.name = name
            rule.trigger = AutomationTrigger(
                type=trigger_type,
                process_name=process_name.strip(),
            )
            rule.cooldown_seconds = cooldown_seconds
        except ValueError as exc:
            self._set_status(self.tr("自动化规则无效：{0}").format(exc))
            return
        self._save_profile(profile)
        self.changed.emit()

    @Slot(str, str, result=str)
    def addAction(self, profile_id: str, rule_id: str) -> str:
        profile = self._get_profile(profile_id)
        rule = self._get_rule(profile_id, rule_id)
        if profile is None or rule is None:
            return ""
        action = AutomationAction()
        rule.actions.append(action)
        self._save_profile(profile)
        return action.id

    @Slot(str, str, str)
    def deleteAction(self, profile_id: str, rule_id: str, action_id: str) -> None:
        profile = self._get_profile(profile_id)
        rule = self._get_rule(profile_id, rule_id)
        if profile is None or rule is None:
            return
        rule.actions = [action for action in rule.actions if action.id != action_id]
        self._save_profile(profile)
        self.changed.emit()

    @Slot(str, str, str, str, str, str, str, str, int)
    def updateAction(
        self,
        profile_id: str,
        rule_id: str,
        action_id: str,
        action_type: str,
        title: str,
        message: str,
        program: str,
        arguments: str,
        duration_ms: int,
    ) -> None:
        profile = self._get_profile(profile_id)
        rule = self._get_rule(profile_id, rule_id)
        action = self._get_action(profile_id, rule_id, action_id)
        if profile is None or rule is None or action is None:
            return
        try:
            action.type = action_type
            action.title = title
            action.message = message
            action.program = program.strip()
            action.arguments = self._parse_arguments(arguments)
            action.duration_ms = duration_ms
        except ValueError as exc:
            self._set_status(self.tr("自动化动作无效：{0}").format(exc))
            return
        self._save_profile(profile)
        self.changed.emit()

    @Slot(str, str)
    def testNotification(self, title: str, message: str) -> None:
        self._notification_provider.push(
            int(NotificationLevel.ANNOUNCEMENT),
            title.strip()[:80] or self.tr("自动化测试"),
            message.strip()[:500] or self.tr("这是一条自动化测试通知。"),
            5000,
            True,
        )

    def _load_profiles(self) -> None:
        self._storage_dir.mkdir(parents=True, exist_ok=True)
        self._profiles.clear()
        for path in sorted(self._storage_dir.glob("*.json")):
            try:
                raw_profile = json.loads(path.read_text(encoding="utf-8"))
                migrated = False
                for key in (
                    "temperature_command",
                    "temperature_arguments",
                    "temperature_poll_seconds",
                ):
                    if key in raw_profile:
                        raw_profile.pop(key)
                        migrated = True

                compatible_rules = []
                for raw_rule in raw_profile.get("rules", []):
                    trigger = raw_rule.get("trigger", {})
                    if trigger.get("type") == "temperature_at_or_above":
                        migrated = True
                        continue
                    actions = raw_rule.get("actions", [])
                    filtered_actions = [
                        action for action in actions if action.get("type") != "fan_full_speed"
                    ]
                    if len(filtered_actions) != len(actions):
                        raw_rule = dict(raw_rule)
                        raw_rule["actions"] = filtered_actions
                        migrated = True
                    compatible_rules.append(raw_rule)
                raw_profile["rules"] = compatible_rules

                profile = AutomationProfile.model_validate(raw_profile)
                self._profiles[profile.id] = profile
                if migrated:
                    self._write_profile(path, profile)
            except Exception as exc:
                logger.warning("Skipping invalid automation profile {}: {}", path, exc)
        self.changed.emit()

    def _save_profile(self, profile: AutomationProfile) -> None:
        self._storage_dir.mkdir(parents=True, exist_ok=True)
        self._write_profile(self._profile_path(profile.id), profile)

    def _write_profile(self, path: Path, profile: AutomationProfile) -> None:
        temporary = path.with_suffix(".json.tmp")
        temporary.write_text(profile.model_dump_json(indent=2), encoding="utf-8")
        temporary.replace(path)
        self.changed.emit()

    def _profile_path(self, profile_id: str) -> Path:
        return self._storage_dir / f"{profile_id}.json"

    def _get_profile(self, profile_id: str) -> AutomationProfile | None:
        return self._profiles.get(profile_id)

    def _get_rule(self, profile_id: str, rule_id: str) -> AutomationRule | None:
        profile = self._get_profile(profile_id)
        if profile is None:
            return None
        return next((rule for rule in profile.rules if rule.id == rule_id), None)

    def _get_action(self, profile_id: str, rule_id: str, action_id: str) -> AutomationAction | None:
        rule = self._get_rule(profile_id, rule_id)
        if rule is None:
            return None
        return next((action for action in rule.actions if action.id == action_id), None)

    def _check_process_events(self) -> None:
        current = self._snapshot_processes()
        if not self._process_snapshot_ready:
            self._process_snapshot_ready = True
            for profile in self._enabled_profiles():
                for rule in self._enabled_rules(profile):
                    process_name = rule.trigger.process_name.casefold()
                    if rule.trigger.type == "process_running" and current.get(process_name):
                        self._run_rule(profile, rule, self.tr("进程正在运行"))
            self._last_processes = current
            return

        for profile in self._enabled_profiles():
            for rule in self._enabled_rules(profile):
                process_name = rule.trigger.process_name.casefold()
                if not process_name:
                    continue
                previous_ids = self._last_processes.get(process_name, set())
                current_ids = current.get(process_name, set())
                if rule.trigger.type == "process_started" and current_ids - previous_ids:
                    self._run_rule(profile, rule, self.tr("进程启动"))
                elif rule.trigger.type == "process_running" and current_ids and not previous_ids:
                    self._run_rule(profile, rule, self.tr("进程正在运行"))
                elif rule.trigger.type == "process_exited" and previous_ids and not current_ids:
                    self._run_rule(profile, rule, self.tr("进程退出"))
        self._last_processes = current

    def _check_schedule_events(self) -> None:
        current_status = self._runtime_status()
        if not current_status or current_status == self._last_schedule_status:
            return
        previous_status = self._last_schedule_status
        self._last_schedule_status = current_status
        is_class = current_status in {EntryType.CLASS.value, EntryType.ACTIVITY.value}
        was_class = previous_status in {EntryType.CLASS.value, EntryType.ACTIVITY.value}
        is_break = current_status in {
            EntryType.BREAK.value,
            EntryType.PREPARATION.value,
            EntryType.FREE.value,
        }
        if is_class and not was_class:
            self._dispatch_event("class_started")
        if is_break and current_status != previous_status:
            self._dispatch_event("break_started")
            if was_class and self._is_noon_dismissal():
                self._dispatch_event("noon_dismissal")
            elif was_class and not self._has_future_classes_today():
                self._dispatch_event("school_dismissal")

    def _dispatch_event(self, trigger_type: str) -> None:
        for profile in self._enabled_profiles():
            for rule in self._enabled_rules(profile):
                if rule.trigger.type == trigger_type:
                    self._run_rule(profile, rule, trigger_type)

    def _run_rule(self, profile: AutomationProfile, rule: AutomationRule, reason: str) -> None:
        now = time.monotonic()
        key = (profile.id, rule.id)
        previous_run = self._last_rule_run.get(key, 0.0)
        if now - previous_run < rule.cooldown_seconds:
            return
        self._last_rule_run[key] = now
        executed = 0
        for action in rule.actions:
            if self._run_action(profile, rule, action):
                executed += 1
        self._set_status(
            self.tr("已执行自动化“{0}”（{1}；{2} 个动作）").format(
                rule.name,
                reason,
                executed,
            )
        )

    def _run_action(self, profile: AutomationProfile, rule: AutomationRule, action: AutomationAction) -> bool:
        if action.type == "notification":
            self._notification_provider.push(
                int(NotificationLevel.ANNOUNCEMENT),
                action.title,
                action.message,
                action.duration_ms,
                True,
            )
            return True
        if action.type == "run_program":
            if not action.program:
                logger.warning("Skipping automation action without an executable: {}", rule.name)
                return False
            try:
                result = QProcess.startDetached(action.program, action.arguments)
                started = result[0] if isinstance(result, tuple) else bool(result)
            except Exception as exc:
                logger.warning("Failed to start automation program {}: {}", action.program, exc)
                return False
            if not started:
                logger.warning("Automation program did not start: {}", action.program)
            return started
        return False

    def _enabled_profiles(self) -> list[AutomationProfile]:
        return [profile for profile in self._profiles.values() if profile.enabled]

    @staticmethod
    def _enabled_rules(profile: AutomationProfile) -> list[AutomationRule]:
        return [rule for rule in profile.rules if rule.enabled]

    def _runtime_status(self) -> str:
        status = getattr(self.app_central.runtime, "current_status", None)
        return getattr(status, "value", str(status or ""))

    def _is_noon_dismissal(self) -> bool:
        runtime = self.app_central.runtime
        current_time = getattr(runtime, "current_offset_time", None)
        if current_time is None or not 11 <= current_time.hour <= 14:
            return False
        return self._has_future_classes_today()

    def _has_future_classes_today(self) -> bool:
        runtime = self.app_central.runtime
        current_day = getattr(runtime, "current_day", None)
        current_time = getattr(runtime, "current_offset_time", None)
        if current_day is None or current_time is None:
            return False
        for entry in getattr(current_day, "entries", []):
            entry_type = getattr(getattr(entry, "type", None), "value", getattr(entry, "type", ""))
            if entry_type not in {EntryType.CLASS.value, EntryType.ACTIVITY.value}:
                continue
            if str(getattr(entry, "startTime", "")) > current_time.strftime("%H:%M"):
                return True
        return False

    @staticmethod
    def _parse_arguments(arguments: str) -> list[str]:
        try:
            return shlex.split(arguments, posix=platform.system() != "Windows")
        except ValueError:
            return []

    @staticmethod
    def _snapshot_processes() -> dict[str, set[int]]:
        snapshot: dict[str, set[int]] = {}
        system = platform.system()
        try:
            if system == "Linux":
                for path in Path("/proc").iterdir():
                    if not path.name.isdigit():
                        continue
                    try:
                        name = (path / "comm").read_text(encoding="utf-8").strip().casefold()
                    except OSError:
                        continue
                    if name:
                        snapshot.setdefault(name, set()).add(int(path.name))
            elif system == "Windows":
                # 使用 Windows 原生 API 枚举进程，避免每次轮询启动 tasklist.exe
                # 导致控制台窗口闪烁。该路径不创建子进程，也不依赖额外组件。
                import ctypes
                from ctypes import wintypes

                psapi = ctypes.WinDLL("psapi", use_last_error=True)
                kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
                enum_processes = psapi.EnumProcesses
                enum_processes.argtypes = [
                    ctypes.POINTER(wintypes.DWORD),
                    wintypes.DWORD,
                    ctypes.POINTER(wintypes.DWORD),
                ]
                enum_processes.restype = wintypes.BOOL
                open_process = kernel32.OpenProcess
                open_process.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
                open_process.restype = wintypes.HANDLE
                close_handle = kernel32.CloseHandle
                close_handle.argtypes = [wintypes.HANDLE]
                close_handle.restype = wintypes.BOOL
                query_image_name = kernel32.QueryFullProcessImageNameW
                query_image_name.argtypes = [
                    wintypes.HANDLE,
                    wintypes.DWORD,
                    wintypes.LPWSTR,
                    ctypes.POINTER(wintypes.DWORD),
                ]
                query_image_name.restype = wintypes.BOOL

                process_query_limited_information = 0x1000
                capacity = 2048
                process_ids: list[int] = []
                while capacity <= 32768:
                    raw_ids = (wintypes.DWORD * capacity)()
                    bytes_returned = wintypes.DWORD()
                    if not enum_processes(raw_ids, ctypes.sizeof(raw_ids), ctypes.byref(bytes_returned)):
                        raise ctypes.WinError(ctypes.get_last_error())
                    count = bytes_returned.value // ctypes.sizeof(wintypes.DWORD)
                    process_ids = [int(raw_ids[index]) for index in range(count) if raw_ids[index]]
                    if bytes_returned.value < ctypes.sizeof(raw_ids):
                        break
                    capacity *= 2

                for process_id in process_ids:
                    handle = open_process(process_query_limited_information, False, process_id)
                    if not handle:
                        continue
                    try:
                        buffer_size = wintypes.DWORD(32768)
                        image_name = ctypes.create_unicode_buffer(buffer_size.value)
                        if not query_image_name(handle, 0, image_name, ctypes.byref(buffer_size)):
                            continue
                        executable_name = Path(image_name.value).name.casefold()
                        if executable_name:
                            snapshot.setdefault(executable_name, set()).add(process_id)
                    finally:
                        close_handle(handle)
            else:
                result = subprocess.run(
                    ["ps", "-axo", "pid=,comm="],
                    capture_output=True,
                    text=True,
                    timeout=3,
                    check=True,
                    shell=False,
                )
                for line in result.stdout.splitlines():
                    parts = line.strip().split(maxsplit=1)
                    if len(parts) != 2:
                        continue
                    try:
                        snapshot.setdefault(Path(parts[1]).name.casefold(), set()).add(int(parts[0]))
                    except ValueError:
                        continue
        except Exception as exc:
            logger.debug("Unable to snapshot processes: {}", exc)
        return snapshot

    def _set_status(self, status: str) -> None:
        self._last_status_text = status
        self.changed.emit()
