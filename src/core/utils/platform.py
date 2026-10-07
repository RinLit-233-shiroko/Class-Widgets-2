from __future__ import annotations

import sys
from typing import TYPE_CHECKING

from PySide6.QtGui import QIcon
from PySide6.QtWidgets import QApplication
from loguru import logger

from src.core.storage.directories import ASSETS_PATH

if TYPE_CHECKING:
    from src.core.utils.instance_locker import SingleInstanceGuard


class PlatformIntegration:
    """Small collection of platform-specific application setup."""

    def __init__(self, app: QApplication) -> None:
        # Import lazily: importing utils at module load time creates a cycle
        # through schedule.model -> schedule.__init__ -> converter.
        from src.core.utils.instance_locker import SingleInstanceGuard

        self.app = app
        self.instance_guard: SingleInstanceGuard = SingleInstanceGuard()
        self.multi_instances = not self.instance_guard.try_acquire()

        if self.multi_instances:
            logger.error(
                "Another instance is already running: {}",
                self.instance_guard.get_lock_info(),
            )

    def initialize(self) -> None:
        self._initialize_app_icon()
        self._initialize_windows_appid()

    def _initialize_app_icon(self) -> None:
        if sys.platform == "darwin":
            return

        filename = "logo.ico" if sys.platform == "win32" else "logo.png"
        self.app.setWindowIcon(QIcon(str(ASSETS_PATH / "images" / filename)))

    @staticmethod
    def _initialize_windows_appid() -> None:
        if sys.platform != "win32":
            return

        try:
            import ctypes

            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(
                "org.classwidgets.app"
            )
        except Exception:
            logger.exception("Failed to set AppUserModelID")
