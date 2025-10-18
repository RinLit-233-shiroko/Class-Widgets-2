from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from .base import AutomationTask
from loguru import logger


class UpdateCheckTask(AutomationTask):
    INTERVAL_MS = 30 * 60 * 1000  # 30min 检查

    def __init__(self, central, parent=None):
        super().__init__(central, parent)
        self.app_central = central

        if not self.app_central.configs.network.auto_check_updates:
            return  # 不检查

        self._timer = QTimer(self)
        self._timer.setInterval(1000)
        self._timer.timeout.connect(self._check_update)
        self._timer.start()

    def _check_update(self):
        if not self.enabled:
            return
        self._timer.setInterval(self.INTERVAL_MS)
        self.app_central.updater_bridge.updateAvailable.connect(self._handle_update_available)
        self.app_central.updater_bridge.checkUpdate()

    def _handle_update_available(self, version, url):
        logger.info(f"Update available: {version}, {url}")
        try:
            text_template = QApplication.translate(
                "UpdateNotification",
                '"{version}" is available!\nGo to "Settings" → "Update" for more details.'
            )
            text = text_template.format(version=version)  # fix translation
            self.app_central.tray_icon.push_update_notification(
                title=QApplication.translate("UpdateNotification", "Class Widgets Update Available"),
                text=text
            )
            self.app_central.updater_bridge.updateAvailable.disconnect(self._handle_update_available)
        except Exception as e:
            logger.error(f"Failed to show tray message: {e}")
