from __future__ import annotations

from typing import TYPE_CHECKING, Any, Callable

from PySide6.QtCore import QObject, QTimer, Slot
from loguru import logger

if TYPE_CHECKING:
    from src.core.central import AppCentral


class AppWindowManager(QObject):
    def __init__(self, central: AppCentral) -> None:
        super().__init__(central)
        self.central = central
        self._windows: dict[str, Any] = {}
        self._factories: dict[str, Callable[[], Any]] = {
            "settings": self._create_settings,
            "editor": self._create_editor,
            "plugin_plaza": self._create_plugin_plaza,
            "whatsnew": self._create_whatsnew,
            "class_swap": self._create_class_swap,
            "class_swap_restore": self._create_class_swap_restore,
            "single_instance": self._create_single_instance,
        }
        self._errors = {
            "settings": "Settings window not initialized correctly.",
            "editor": "Editor window not initialized correctly.",
            "plugin_plaza": "Plugin plaza window not initialized correctly.",
            "whatsnew": "WhatsNew window not initialized correctly.",
            "class_swap": "ClassSwap window not initialized correctly.",
            "class_swap_restore": "ClassSwap restore dialog window not initialized correctly.",
            "single_instance": "Single Instance Dialog not initialized correctly.",
        }

    @Slot()
    def openSettings(self) -> None:
        self.open_settings()

    @Slot()
    def closeSettings(self) -> None:
        self.close_settings()

    @Slot()
    def openEditor(self) -> None:
        self.open_editor()

    @Slot()
    def closeEditor(self) -> None:
        self.close_editor()

    @Slot()
    def openPlaza(self) -> None:
        self.open_plugin_plaza()

    @Slot()
    def closePlaza(self) -> None:
        self.close_plugin_plaza()

    @Slot()
    def openWhatsNew(self) -> None:
        self.open_whatsnew()

    @Slot()
    def closeWhatsNew(self) -> None:
        self.close_whatsnew()

    @Slot()
    def openSingleInstanceDialog(self) -> None:
        self.open_single_instance_dialog()

    @Slot()
    def openClassSwap(self) -> None:
        self.open_class_swap()

    @Slot()
    def closeClassSwap(self) -> None:
        self.close_class_swap()

    @Slot()
    def openClassSwapRestoreDialog(self) -> None:
        self.open_class_swap_restore()

    @Slot()
    def classSwapRestoreContinue(self) -> None:
        self.close_class_swap_restore()
        if self.central._startup_swap_restore_pending:
            self.central._startup_swap_restore_pending = False
            self.central._continue_init()

    @Slot()
    def classSwapRestoreDiscard(self) -> None:
        self.central._class_swap_manager.discardTodaySwaps()
        self.close_class_swap_restore()
        if self.central._startup_swap_restore_pending:
            self.central._startup_swap_restore_pending = False
            self.central._continue_init()

    def open_settings(self) -> None:
        self.open("settings")

    def close_settings(self) -> None:
        self.release("settings")

    def open_editor(self) -> None:
        if self.central._class_swap_manager.hasTodaySwaps():
            logger.warning("Blocked opening editor because temporary class swaps exist today")
            self.open_class_swap_restore()
            return
        self.open("editor")

    def close_editor(self) -> None:
        self.release("editor")

    def open_plugin_plaza(self) -> None:
        self.open("plugin_plaza")

    def close_plugin_plaza(self) -> None:
        self.release("plugin_plaza")

    def open_whatsnew(self) -> None:
        self.open("whatsnew")

    def close_whatsnew(self) -> None:
        self.release("whatsnew")

    def open_class_swap(self) -> None:
        self.open("class_swap")

    def close_class_swap(self) -> None:
        self.release("class_swap")

    def open_class_swap_restore(self) -> None:
        self.open("class_swap_restore")

    def close_class_swap_restore(self) -> None:
        self.release("class_swap_restore")

    def open_single_instance_dialog(self) -> None:
        self.open("single_instance")

    def open(self, name: str) -> None:
        try:
            window = self.ensure(name)
        except KeyError:
            logger.error(f"Window '{name}' is not registered.")
            return

        root_window = getattr(window, "root_window", None)
        if root_window:
            root_window.show()
            root_window.raise_()
            root_window.requestActivate()
            return
        logger.error(self._errors.get(name, f"Window '{name}' not initialized correctly."))

    def ensure(self, name: str) -> Any:
        window = self._windows.get(name)
        if window is None:
            factory = self._factories[name]
            window = factory()
            self._windows[name] = window
        return window

    def release(self, name: str) -> None:
        window = self._windows.get(name)
        if not window:
            return

        root_window = getattr(window, "root_window", None)
        if root_window:
            root_window.hide()

        QTimer.singleShot(0, lambda window_name=name: self._release_now(window_name))

    def _release_now(self, name: str) -> None:
        window = self._windows.pop(name, None)
        if not window:
            return

        try:
            self.central.retranslate.disconnect(window.engine.retranslate)
        except (RuntimeError, TypeError):
            pass

        if hasattr(window, "release"):
            window.release()
            return

        root_window = getattr(window, "root_window", None)
        if root_window:
            root_window.hide()
            root_window.deleteLater()

    def release_all(self) -> None:
        for name in list(self._windows):
            self.release(name)

    def _create_settings(self):
        from src.core.windows.windows import Settings

        window = Settings(self.central)
        self._apply_settings_window_workarounds(window)
        return window

    def _create_editor(self):
        from src.core.windows.windows import Editor

        return Editor(self.central)

    def _create_plugin_plaza(self):
        from src.core.windows.windows import PluginPlaza

        return PluginPlaza(self.central)

    def _create_whatsnew(self):
        from src.core.windows.windows import WhatsNew

        return WhatsNew(self.central)

    def _create_class_swap(self):
        from src.core.windows.windows import ClassSwapWindow

        return ClassSwapWindow(self.central)

    def _create_class_swap_restore(self):
        from src.core.windows.windows import ClassSwapRestoreDialog

        return ClassSwapRestoreDialog(self.central)

    def _create_single_instance(self):
        from src.core.windows.windows import CheckSingleInstanceDialog

        return CheckSingleInstanceDialog(self.central)

    def _apply_settings_window_workarounds(self, window) -> None:
        import platform

        if platform.system() == "Windows" and platform.release() == "10" and platform.version() < "22000":
            from RinUI import BackdropEffect
            window.setBackdropEffect(BackdropEffect.None_)
