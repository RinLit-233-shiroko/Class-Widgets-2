from __future__ import annotations

from typing import Optional, TYPE_CHECKING
from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from .base import AutomationTask
from loguru import logger
from src.core.storage.directories import USE_LEGACY_WORK_LAYOUT

if TYPE_CHECKING:
    from src.core.central import AppCentral

class UpdateCheckTask(AutomationTask):
    INTERVAL_MS = 30 * 60 * 1000  

    def __init__(self, central: "AppCentral", parent: Optional[QTimer] = None) -> None:
        super().__init__(central, parent)
        self.app_central: "AppCentral" = central

        if USE_LEGACY_WORK_LAYOUT:
            logger.info("Running from source, update check disabled")
            return  

        if not self.app_central.configs.network.auto_check_updates:
            return  

        self._timer: QTimer = QTimer(self)
        self._timer.setInterval(1000)
        self._timer.timeout.connect(self._check_update)
        self._timer.start()

    def _check_update(self) -> None:
        if not self.enabled:
            return
        self._timer.setInterval(self.INTERVAL_MS)
        self.app_central.updater_bridge.updateAvailable.connect(self._handle_update_available)
        self.app_central.updater_bridge.checkUpdate()

    def _handle_update_available(self, version: str, url: str) -> None:
        logger.info(f"Update available: {version}, {url}")
        try:
            text_template = QApplication.translate(
                "UpdateNotification",
                '"{version}" is available!\nGo to "Settings" → "Update" for more details.'
            )
            text = text_template.format(version=version)  
            self.app_central.tray_icon.push_update_notification(
                title=QApplication.translate("UpdateNotification", "Class Widgets Update Available"),
                text=text
            )
            self.app_central.updater_bridge.updateAvailable.disconnect(self._handle_update_available)
        except Exception as e:
            logger.error(f"Failed to show tray message: {e}")
