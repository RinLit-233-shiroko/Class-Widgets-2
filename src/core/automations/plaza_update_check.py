from __future__ import annotations

from typing import TYPE_CHECKING

from PySide6.QtCore import QTimer

from .base import AutomationTask

if TYPE_CHECKING:
    from src.core.central import AppCentral


class PlazaUpdateCheckTask(AutomationTask):
    """Periodically check Plugin Plaza and optionally install updates in order."""

    INTERVAL_MS = 30 * 60 * 1000
    INITIAL_DELAY_MS = 5 * 1000

    def __init__(self, central: "AppCentral") -> None:
        super().__init__(central)
        self._queue: list[str] = []
        self._active_plugin_id = ""
        self._timer = QTimer(self)
        self._timer.setInterval(self.INITIAL_DELAY_MS)
        self._timer.timeout.connect(self._check_updates)
        self._timer.start()

        manager = self.app_central.plugin_manager
        manager.plazaUpdateCheckCompleted.connect(self._on_check_completed)
        manager.pluginInstallSucceeded.connect(self._on_transfer_completed)
        manager.pluginInstallFailed.connect(self._on_transfer_failed)
        manager.pluginInstallCancelled.connect(self._on_transfer_cancelled)
        manager.pluginInstallSettled.connect(self._on_transfer_settled)

    def _check_updates(self) -> None:
        self._timer.setInterval(self.INTERVAL_MS)
        if not self.app_central.configs.plugins.auto_check_plaza_updates:
            return
        self.app_central.plugin_manager.check_plaza_updates(background=True)

    def _on_check_completed(self, background: bool, results: list[dict]) -> None:
        if not background or not self.app_central.configs.plugins.auto_install_plaza_updates:
            return
        if self._queue or self._active_plugin_id:
            return
        self._queue = [
            str(result["id"])
            for result in results
            if result.get("id") and result.get("update_available")
        ]
        self._start_next()

    def _on_transfer_completed(self, plugin_id: str, _version: str) -> None:
        if plugin_id == self._active_plugin_id:
            self._active_plugin_id = ""

    def _on_transfer_failed(self, _message: str) -> None:
        self._active_plugin_id = ""

    def _on_transfer_cancelled(self, plugin_id: str) -> None:
        if plugin_id == self._active_plugin_id:
            self._active_plugin_id = ""
            self._queue.clear()

    def _on_transfer_settled(self) -> None:
        self._start_next()

    def _start_next(self) -> None:
        if not self._queue or self._active_plugin_id:
            return
        manager = self.app_central.plugin_manager
        if manager.plazaInstallActive or manager.installStatus == "Installing":
            return
        plugin_id = self._queue.pop(0)
        if manager.installPlazaUpdate(plugin_id):
            self._active_plugin_id = plugin_id
            return
        QTimer.singleShot(0, self._start_next)
