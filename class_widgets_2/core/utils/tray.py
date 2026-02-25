import ctypes
import platform
from pathlib import Path

from PySide6.QtWidgets import QSystemTrayIcon
from PySide6.QtGui import QIcon, QAction, QCursor
from PySide6.QtCore import QObject, Signal, Slot, QPoint
from loguru import logger

from class_widgets_2.core import ASSETS_PATH


class TrayIcon(QObject):
    togglePanel = Signal(QPoint)

    def __init__(self):
        super().__init__()
        tray_icon_path = Path(ASSETS_PATH / "images" / "tray_icon.png").as_posix()
        icons_dir = Path(ASSETS_PATH / "images" / "icons")

        self.icon_paths = {
            "default": tray_icon_path,
            "error": Path(icons_dir / "cw2_error.png").as_posix(),
            "update_available": Path(icons_dir / "cw2_update_available.png").as_posix(),
            "up_to_date": Path(icons_dir / "cw2_up_to_date.png").as_posix(),
        }

        self._set_app_user_model_id("Class Widgets 2")

        self.tray = QSystemTrayIcon(QIcon(tray_icon_path))
        self.tray.setToolTip("Class Widgets 2")
        self.tray.activated.connect(self.on_click)
        self.tray.show()

    def _set_app_user_model_id(self, app_id: str):
        if platform.system() != "Windows":
            return
        try:
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(app_id)
        except Exception as e:
            logger.error(f"Failed to set AppUserModelID: {e}")

    def on_click(self, reason):
        # if reason == QSystemTrayIcon.ActivationReason.Trigger:
        pos = QCursor.pos()
        self.togglePanel.emit(pos)

    def push_update_notification(self, title: str, text: str):
        self.tray.showMessage(title, text, QIcon(Path(self.icon_paths["update_available"]).as_posix()), 10000)

    def push_up_to_date_notification(self, title: str, text: str):
        self.tray.showMessage(title, text, QIcon(Path(self.icon_paths["up_to_date"]).as_posix()), 10000)

    def push_error_notification(self, title: str, text: str):
        self.tray.showMessage(title, text, QIcon(Path(self.icon_paths["error"]).as_posix()), 5000)

    def push_notification(self, title: str, text: str, icon: QIcon = None):
        self.tray.showMessage(title, text, icon or QIcon(Path(self.icon_paths["default"]).as_posix()), 5000)

