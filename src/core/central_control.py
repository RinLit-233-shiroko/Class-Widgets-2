from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path
from typing import TYPE_CHECKING
from urllib.parse import urljoin

import requests
from loguru import logger
from PySide6.QtCore import QObject, Property, QThread, Signal, Slot

from src import __SCHEDULE_SCHEMA_VERSION__
from src.core.schedule.model import ScheduleData

if TYPE_CHECKING:
    from src.core.config.manager import ConfigManager
    from src.core.schedule.manager import ScheduleManager


MAX_SCHEDULE_BYTES = 2 * 1024 * 1024
_SCHEDULE_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")


class _ScheduleFetchWorker(QThread):
    completed = Signal(bool, str, object)

    def __init__(self, manifest_url: str, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.manifest_url = manifest_url

    def run(self) -> None:
        try:
            payload = CentralControlScheduleService.fetch_schedule_payload(self.manifest_url)
        except Exception as exc:
            self.completed.emit(False, str(exc), {})
            return
        self.completed.emit(True, "", payload)


class CentralControlScheduleService(QObject):
    """手动拉取 GitHub Pages 课程表清单并安全应用到本地课程表库。"""

    changed = Signal()
    applied = Signal(str)

    def __init__(
        self,
        configs: "ConfigManager",
        schedule_manager: "ScheduleManager",
        parent: QObject | None = None,
    ) -> None:
        super().__init__(parent)
        self._configs = configs
        self._schedule_manager = schedule_manager
        self._worker: _ScheduleFetchWorker | None = None
        self._syncing = False
        self._status_text = self.tr("尚未检查集控课程表")
        self._last_applied_name = ""
        self._last_policy_version = ""

    @Property(str, notify=changed)
    def manifestUrl(self) -> str:
        return self._configs.central_control.schedule_manifest_url

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

    @Slot(str)
    def setManifestUrl(self, manifest_url: str) -> None:
        self._configs.set("central_control.schedule_manifest_url", manifest_url.strip())
        self.changed.emit()

    @Slot()
    def fetchAndApplySchedule(self) -> None:
        if self._syncing:
            return

        manifest_url = self.manifestUrl.strip()
        if not manifest_url:
            self._set_status(self.tr("请先填写课程表下发地址"))
            return
        if not manifest_url.startswith(("https://", "http://")):
            self._set_status(self.tr("课程表下发地址必须以 http:// 或 https:// 开头"))
            return

        self._syncing = True
        self._set_status(self.tr("正在检查集控课程表…"), emit=False)
        self.changed.emit()
        self._worker = _ScheduleFetchWorker(manifest_url, self)
        self._worker.completed.connect(self._on_fetch_completed)
        self._worker.finished.connect(self._worker.deleteLater)
        self._worker.start()

    @Slot(bool, str, object)
    def _on_fetch_completed(self, success: bool, error: str, payload: object) -> None:
        self._syncing = False
        if not success:
            self._set_status(self.tr("集控课程表接收失败：{0}").format(error))
            return

        try:
            schedule_name, policy_version = self._cache_and_apply(payload)
        except Exception as exc:
            logger.exception("Failed to apply central-control schedule")
            self._set_status(self.tr("集控课程表应用失败：{0}").format(exc))
            return

        self._last_applied_name = schedule_name
        self._last_policy_version = policy_version
        self._set_status(
            self.tr("已应用集控课程表“{0}”（策略版本：{1}）").format(
                schedule_name,
                policy_version,
            )
        )
        self.applied.emit(schedule_name)

    @staticmethod
    def fetch_schedule_payload(manifest_url: str) -> dict:
        """下载并验证清单和课程表；仅在所有校验通过后返回数据。"""
        manifest_response = requests.get(
            manifest_url,
            timeout=15,
            headers={"Accept": "application/json", "User-Agent": "ClassWidgetsCentralControl/1"},
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
            headers={"Accept": "application/json", "User-Agent": "ClassWidgetsCentralControl/1"},
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
        }

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

    def _set_status(self, status_text: str, emit: bool = True) -> None:
        self._status_text = status_text
        if emit:
            self.changed.emit()
