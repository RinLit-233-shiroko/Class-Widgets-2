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
        self._pending_releases: list[Any] = []
        self._factories: dict[str, Callable[[], Any]] = {
            "settings": self._create_settings,
            "editor": self._create_editor,
            "plugin_plaza": self._create_plugin_plaza,
            "whatsnew": self._create_whatsnew,
            "class_swap": self._create_class_swap,
            "class_swap_restore": self._create_class_swap_restore,
            "single_instance": self._create_single_instance,
            "theme_load_error": self._create_theme_load_error,
            "problem_report": self._create_problem_report,
            "tutorial": self._create_tutorial,
            "debugger": self._create_debugger,
        }
        self._errors = {
            "settings": "Settings window not initialized correctly.",
            "editor": "Editor window not initialized correctly.",
            "plugin_plaza": "Plugin plaza window not initialized correctly.",
            "whatsnew": "WhatsNew window not initialized correctly.",
            "class_swap": "ClassSwap window not initialized correctly.",
            "class_swap_restore": "ClassSwap restore dialog window not initialized correctly.",
            "single_instance": "Single Instance Dialog not initialized correctly.",
            "theme_load_error": "Theme load error dialog window not initialized correctly.",
            "problem_report": "Problem report window not initialized correctly.",
            "tutorial": "Tutorial window not initialized correctly.",
            "debugger": "Debugger window not initialized correctly.",
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
    def closeDebugger(self) -> None:
        self.close_debugger()

    @Slot()
    def closeThemeLoadError(self) -> None:
        self.close_theme_load_error()

    @Slot()
    def closeProblemReport(self) -> None:
        self.close_problem_report()

    @Slot()
    def classSwapRestoreContinue(self) -> None:
        self.central.resolve_class_swap_restore(discard=False)
        self.close_class_swap_restore()

    @Slot()
    def classSwapRestoreDiscard(self) -> None:
        self.central.resolve_class_swap_restore(discard=True)
        self.close_class_swap_restore()

    def open_settings(self) -> None:
        self.open("settings")

    def close_settings(self) -> None:
        self.release("settings")

    def open_editor(self) -> None:
        if self.central.has_today_class_swaps():
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

    def open_tutorial(self) -> None:
        self.open("tutorial")

    def open_debugger(self) -> None:
        self.open("debugger")

    def close_debugger(self) -> None:
        self.release("debugger")

    def open_problem_report(self, report) -> None:
        """显示崩溃报告窗口。

        同一时间只保留第一份报告：后续崩溃只记录日志，避免把用户正在阅读的
        信息替换掉。
        """
        if "problem_report" in self._windows:
            logger.warning(
                "Problem report window already open, keeping the first report"
            )
            return

        try:
            window = self.ensure("problem_report")
        except Exception:
            logger.exception("Failed to create the problem report window")
            return

        window.set_report(report)
        window.show_when_ready()
        self._show_problem_report_when_ready(window, attempts=20)

    def _show_problem_report_when_ready(self, window: Any, attempts: int) -> None:
        if getattr(window, "root_window", None):
            self.open("problem_report")
            logger.info("Problem report window opened")
            return
        if attempts <= 0:
            logger.error("Problem report window root window was not created")
            return
        QTimer.singleShot(
            50,
            lambda: self._show_problem_report_when_ready(window, attempts - 1),
        )

    def close_problem_report(self) -> None:
        self.release("problem_report")

    def open_theme_load_error(self, failed_theme_id: str = "", recovered: bool = True) -> None:
        window = self.ensure("theme_load_error")
        window.set_error_details(failed_theme_id, recovered)
        window.show_when_ready()
        self._show_theme_load_error_when_ready(window, attempts=10)

    def _show_theme_load_error_when_ready(self, window: Any, attempts: int) -> None:
        if getattr(window, "root_window", None):
            self.open("theme_load_error")
            logger.info("Theme load error dialog opened")
            return
        if attempts <= 0:
            logger.error("Theme load error dialog root window was not created")
            return
        QTimer.singleShot(
            50,
            lambda: self._show_theme_load_error_when_ready(window, attempts - 1),
        )

    def close_theme_load_error(self) -> None:
        self.release("theme_load_error")

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
        window = self._windows.pop(name, None)
        if not window:
            return

        root_window = getattr(window, "root_window", None)
        if root_window:
            root_window.hide()

        self._pending_releases.append(window)
        QTimer.singleShot(0, lambda managed_window=window: self._finish_release(managed_window))

    def _finish_release(self, window: Any) -> None:
        for index, pending_window in enumerate(self._pending_releases):
            if pending_window is window:
                self._pending_releases.pop(index)
                self._release_now(window)
                return

    def _release_now(self, window: Any) -> None:
        try:
            if hasattr(window, "release"):
                window.release()
                return

            root_window = getattr(window, "root_window", None)
            if root_window:
                root_window.hide()
                root_window.deleteLater()
        except Exception:
            logger.exception("Failed to release managed window {}", type(window).__name__)

    def release_all(self) -> None:
        windows = list(self._windows.values()) + self._pending_releases
        self._windows.clear()
        self._pending_releases = []

        unique_windows = {id(window): window for window in windows}
        for window in unique_windows.values():
            self._release_now(window)

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

    def _create_problem_report(self):
        from src.core.windows.problem_report import ProblemReport

        return ProblemReport(self.central)

    def _create_theme_load_error(self):
        from src.core.windows.windows import ThemeLoadErrorDialog

        return ThemeLoadErrorDialog(self.central)

    def _create_tutorial(self):
        from src.core.windows.windows import Tutorial

        return Tutorial(self.central)

    def _create_debugger(self):
        from src.core.utils.debugger import DebuggerWindow

        return DebuggerWindow(self.central)

    def _apply_settings_window_workarounds(self, window) -> None:
        import platform

        if platform.system() == "Windows" and platform.release() == "10" and platform.version() < "22000":
            from RinUI import BackdropEffect
            window.setBackdropEffect(BackdropEffect.None_)
