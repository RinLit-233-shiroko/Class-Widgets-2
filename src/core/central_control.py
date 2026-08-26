from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import TYPE_CHECKING
from urllib.parse import urljoin

import requests
from loguru import logger
from PySide6.QtCore import QObject, Property, QThread, QTimer, Signal, Slot

from src import __SCHEDULE_SCHEMA_VERSION__
from src.core.notification import NotificationProvider
from src.core.notification.model import NotificationLevel
from src.core.schedule.model import ScheduleData

if TYPE_CHECKING:
    from src.core.config.manager import ConfigManager
    from src.core.notification.manager import NotificationManager
    from src.core.schedule.manager import ScheduleManager


MAX_SCHEDULE_BYTES = 2 * 1024 * 1024
MAX_COMMANDS = 20
MAX_COMMAND_TEXT_LENGTH = 500
MAX_EXECUTED_COMMAND_IDS = 100
_SCHEDULE_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")
_COMMAND_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,80}$")


class _CentralControlFetchWorker(QThread):
    completed = Signal(bool, str, object)

    def __init__(self, manifest_url: str, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.manifest_url = manifest_url

    def run(self) -> None:
        try:
            payload = CentralControlScheduleService.fetch_manifest_payload(self.manifest_url)
        except Exception as exc:
            self.completed.emit(False, str(exc), {})
            return
        self.completed.emit(True, "", payload)


class CentralControlScheduleService(QObject):
    """从静态集控清单接收课程表和一次性公告命令。"""

    changed = Signal()
    applied = Signal(str)

    def __init__(
        self,
        configs: "ConfigManager",
        schedule_manager: "ScheduleManager",
        notification_manager: "NotificationManager",
        parent: QObject | None = None,
    ) -> None:
        super().__init__(parent)
        self._configs = configs
        self._schedule_manager = schedule_manager
        self._worker: _CentralControlFetchWorker | None = None
        self._syncing = False
        self._status_text = self.tr("尚未检查集控内容")
        self._last_applied_name = ""
        self._last_policy_version = ""
        self._last_announcement_count = 0
        self._auto_fetch_timer = QTimer(self)
        self._auto_fetch_timer.timeout.connect(self.fetchAndApplySchedule)
        self._notification_provider = NotificationProvider(
            id="com.classwidgets.central-control",
            name=self.tr("集控公告"),
            icon="ic_fluent_megaphone_20_regular",
            use_system_notify=True,
            manager=notification_manager,
        )

    @Property(str, notify=changed)
    def manifestUrl(self) -> str:
        return self._configs.central_control.schedule_manifest_url

    @Property(bool, notify=changed)
    def autoFetchEnabled(self) -> bool:
        return self._configs.central_control.auto_fetch_enabled

    @Property(int, notify=changed)
    def autoFetchIntervalMinutes(self) -> int:
        return self._configs.central_control.auto_fetch_interval_minutes

    @Property(bool, notify=changed)
    def syncing(self) -> bool:
        return self._syncing

    @Property(str, notify=changed)
    def statusText(self) -> str:
        return self._status_text

    @Property(str, notify=changed)
    def lastAppliedName(self) -> str:
        return self._last_applied_name

    @Property(str, notify=changed)
    def lastPolicyVersion(self) -> str:
        return self._last_policy_version

    @Property(int, notify=changed)
    def lastAnnouncementCount(self) -> int:
        return self._last_announcement_count

    def start(self) -> None:
        """在配置加载后启动自动拉取；手动模式不产生网络请求。"""
        self._configure_auto_fetch(fetch_immediately=True)

    def stop(self) -> None:
        self._auto_fetch_timer.stop()

    @Slot(str)
    def setManifestUrl(self, manifest_url: str) -> None:
        self._configs.set("central_control.schedule_manifest_url", manifest_url.strip())
        self._configure_auto_fetch(fetch_immediately=True)
        self.changed.emit()

    @Slot(bool)
    def setAutoFetchEnabled(self, enabled: bool) -> None:
        self._configs.set("central_control.auto_fetch_enabled", enabled)
        self._configure_auto_fetch(fetch_immediately=True)
        self.changed.emit()

    @Slot(int)
    def setAutoFetchIntervalMinutes(self, minutes: int) -> None:
        safe_minutes = max(1, min(int(minutes), 1440))
        self._configs.set("central_control.auto_fetch_interval_minutes", safe_minutes)
        self._configure_auto_fetch(fetch_immediately=False)
        self.changed.emit()

    @Slot()
    def fetchAndApplySchedule(self) -> None:
        if self._syncing:
            return

        manifest_url = self.manifestUrl.strip()
        if not manifest_url:
            self._set_status(self.tr("请先填写集控地址"))
            return
        if not manifest_url.startswith(("https://", "http://")):
            self._set_status(self.tr("集控地址必须以 http:// 或 https:// 开头"))
            return

        self._syncing = True
        self._set_status(self.tr("正在检查集控内容…"), emit=False)
        self.changed.emit()
        self._worker = _CentralControlFetchWorker(manifest_url, self)
        self._worker.completed.connect(self._on_fetch_completed)
        self._worker.finished.connect(self._worker.deleteLater)
        self._worker.start()

    @Slot(bool, str, object)
    def _on_fetch_completed(self, success: bool, error: str, payload: object) -> None:
        self._syncing = False
        self._last_announcement_count = 0
        if not success:
            self._set_status(self.tr("集控内容接收失败：{0}").format(error))
            return

        try:
            schedule_name, policy_version = self._cache_and_apply(payload)
            announcement_count = self._apply_announcement_commands(payload)
        except Exception as exc:
            logger.exception("Failed to apply central-control content")
            self._set_status(self.tr("集控内容应用失败：{0}").format(exc))
            return

        self._last_applied_name = schedule_name
        self._last_policy_version = policy_version
        self._last_announcement_count = announcement_count
        status = self.tr("已应用集控课程表“{0}”（策略版本：{1}）").format(
            schedule_name,
            policy_version,
        )
        if announcement_count:
            status += self.tr("；已处理 {0} 条公告命令").format(announcement_count)
        self._set_status(status)
        self.applied.emit(schedule_name)

    @staticmethod
    def fetch_manifest_payload(manifest_url: str) -> dict:
        """下载并校验清单、课程表和公告命令；全部通过才返回。"""
        manifest_response = requests.get(
            manifest_url,
            timeout=15,
            headers={"Accept": "application/json", "User-Agent": "ClassWidgetsCentralControl/2"},
        )
        manifest_response.raise_for_status()
        manifest = manifest_response.json()
        if not isinstance(manifest, dict) or manifest.get("schemaVersion") != 1:
            raise ValueError("集控清单格式或版本不受支持")

        schedule_info = manifest.get("schedule")
        if not isinstance(schedule_info, dict):
            raise ValueError("集控清单缺少课程表信息")

        schedule_id = str(schedule_info.get("id", ""))
        if not _SCHEDULE_ID_PATTERN.fullmatch(schedule_id):
            raise ValueError("课程表标识仅允许字母、数字、短横线和下划线")

        schedule_url = str(schedule_info.get("url", ""))
        expected_sha256 = str(schedule_info.get("sha256", "")).lower()
        if not schedule_url or not re.fullmatch(r"[a-f0-9]{64}", expected_sha256):
            raise ValueError("集控清单缺少有效的课程表地址或 SHA-256 校验值")

        resolved_schedule_url = urljoin(manifest_url, schedule_url)
        schedule_response = requests.get(
            resolved_schedule_url,
            timeout=20,
            headers={"Accept": "application/json", "User-Agent": "ClassWidgetsCentralControl/2"},
        )
        schedule_response.raise_for_status()
        content = schedule_response.content
        if len(content) > MAX_SCHEDULE_BYTES:
            raise ValueError("课程表文件超过允许的 2 MB 大小")
        actual_sha256 = hashlib.sha256(content).hexdigest()
        if actual_sha256 != expected_sha256:
            raise ValueError("课程表 SHA-256 校验失败")

        try:
            schedule_raw = json.loads(content.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ValueError("课程表不是有效的 UTF-8 JSON 文件") from exc

        schedule = ScheduleData.model_validate(schedule_raw)
        if schedule.meta.version != __SCHEDULE_SCHEMA_VERSION__:
            raise ValueError(f"不支持的课程表架构版本：{schedule.meta.version}")

        policy_version = str(manifest.get("policyVersion", "unknown"))
        return {
            "schedule_id": schedule_id,
            "schedule_name": str(schedule_info.get("name", schedule_id)),
            "policy_version": policy_version,
            "schedule": schedule.model_dump(),
            "sha256": actual_sha256,
            "commands": CentralControlScheduleService._validate_commands(manifest.get("commands", [])),
        }

    @staticmethod
    def _validate_commands(raw_commands: object) -> list[dict]:
        if raw_commands is None:
            return []
        if not isinstance(raw_commands, list):
            raise ValueError("集控命令必须是数组")
        if len(raw_commands) > MAX_COMMANDS:
            raise ValueError(f"集控命令数量不能超过 {MAX_COMMANDS} 条")

        commands: list[dict] = []
        for raw_command in raw_commands:
            if not isinstance(raw_command, dict):
                raise ValueError("集控命令格式无效")
            command_id = str(raw_command.get("id", ""))
            command_type = str(raw_command.get("type", ""))
            if not _COMMAND_ID_PATTERN.fullmatch(command_id):
                raise ValueError("公告命令标识格式无效")
            if command_type != "announcement":
                raise ValueError(f"不支持的集控命令类型：{command_type}")

            title = str(raw_command.get("title", "集控公告")).strip()
            message = str(raw_command.get("message", "")).strip()
            if not title or not message:
                raise ValueError("公告命令必须包含标题和内容")
            if len(title) > 80 or len(message) > MAX_COMMAND_TEXT_LENGTH:
                raise ValueError("公告标题或内容过长")

            try:
                duration = int(raw_command.get("duration", 8000))
            except (TypeError, ValueError) as exc:
                raise ValueError("公告显示时长无效") from exc
            duration = max(1000, min(duration, 60000))

            expires_at = raw_command.get("expiresAt")
            if expires_at is not None:
                if not isinstance(expires_at, str):
                    raise ValueError("公告过期时间无效")
                try:
                    datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
                except ValueError as exc:
                    raise ValueError("公告过期时间必须是 ISO 8601 格式") from exc

            commands.append(
                {
                    "id": command_id,
                    "type": command_type,
                    "title": title,
                    "message": message,
                    "duration": duration,
                    "expiresAt": expires_at,
                }
            )
        return commands

    def _cache_and_apply(self, payload: object) -> tuple[str, str]:
        if not isinstance(payload, dict):
            raise ValueError("课程表接收结果无效")

        schedule_id = str(payload["schedule_id"])
        policy_version = str(payload["policy_version"])
        schedule = ScheduleData.model_validate(payload["schedule"])
        local_name = f"central_{schedule_id}"
        destination = self._schedule_manager.schedules_dir / f"{local_name}.json"
        temporary = destination.with_suffix(".json.tmp")

        temporary.write_text(
            json.dumps(schedule.model_dump(), ensure_ascii=False, indent=4),
            encoding="utf-8",
        )
        temporary.replace(destination)

        if not self._schedule_manager.load(local_name, force=True):
            raise ValueError("无法切换到已接收的课程表")
        return local_name, policy_version

    def _apply_announcement_commands(self, payload: object) -> int:
        if not isinstance(payload, dict):
            raise ValueError("公告命令接收结果无效")

        commands = payload.get("commands", [])
        if not isinstance(commands, list):
            raise ValueError("公告命令接收结果无效")

        completed_ids = list(self._configs.central_control.executed_command_ids)
        completed_id_set = set(completed_ids)
        processed_count = 0
        for command in commands:
            command_id = command["id"]
            if command_id in completed_id_set or self._is_command_expired(command.get("expiresAt")):
                continue
            self._notification_provider.push(
                int(NotificationLevel.ANNOUNCEMENT),
                command["title"],
                command["message"],
                command["duration"],
                True,
            )
            completed_ids.append(command_id)
            completed_id_set.add(command_id)
            processed_count += 1

        if processed_count:
            self._configs.set(
                "central_control.executed_command_ids",
                completed_ids[-MAX_EXECUTED_COMMAND_IDS:],
            )
        return processed_count

    @staticmethod
    def _is_command_expired(expires_at: object) -> bool:
        if not expires_at:
            return False
        try:
            expires = datetime.fromisoformat(str(expires_at).replace("Z", "+00:00"))
        except ValueError:
            return True
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        return expires.astimezone(timezone.utc) <= datetime.now(timezone.utc)

    def _configure_auto_fetch(self, fetch_immediately: bool) -> None:
        self._auto_fetch_timer.stop()
        if not self.autoFetchEnabled or not self.manifestUrl.strip():
            return

        interval_ms = self.autoFetchIntervalMinutes * 60 * 1000
        self._auto_fetch_timer.setInterval(interval_ms)
        self._auto_fetch_timer.start()
        if fetch_immediately:
            QTimer.singleShot(0, self.fetchAndApplySchedule)

    def _set_status(self, status_text: str, emit: bool = True) -> None:
        self._status_text = status_text
        if emit:
            self.changed.emit()
