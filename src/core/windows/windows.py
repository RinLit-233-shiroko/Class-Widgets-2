from loguru import logger
from pathlib import Path
from typing import Union

from PySide6.QtCore import QCoreApplication, QObject, Property, Signal, Slot

from RinUI import RinUIWindow
from src.core.directories import CW_PATH, DEFAULT_THEME
from src.core.plaza import MarkdownRenderBridge, PlazaBridge, TutorialRecommendationsBridge
from src.core.plugin.bridge import PluginBackendBridge


class ReleasableWindow(RinUIWindow):
    def __init__(self, central):
        # Auxiliary windows own their engine. Sharing the main engine couples
        # root-object creation and context lifetime across unrelated windows.
        super().__init__(shared_engine=False)
        self.central = central
        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)
        self._retranslate_connected = True
        self._released = False
        self._theme_window_handles: tuple[int, ...] = ()

        # RinUI's ThemeManager is a process-wide singleton. RinUIWindow connects
        # it once per window, so window churn otherwise accumulates duplicate
        # aboutToQuit callbacks. AppCentral owns the single shutdown call.
        app = QCoreApplication.instance()
        if app:
            try:
                app.aboutToQuit.disconnect(self.theme_manager.clean_up)
            except (RuntimeError, TypeError):
                pass
        logger.info("ReleasableWindow created")

    @property
    def is_released(self) -> bool:
        return self._released

    def load(self, qml_path: Union[str, Path] = None) -> None:
        super().load(qml_path)
        self._theme_window_handles = tuple(int(window.winId()) for window in self.windows)

    def release(self):
        if self._released:
            return
        self._released = True

        if self._retranslate_connected:
            try:
                self.central.retranslate.disconnect(self.engine.retranslate)
            except (RuntimeError, TypeError):
                pass
            self._retranslate_connected = False

        app = QCoreApplication.instance()
        if app and self.win_event_filter:
            app.removeNativeEventFilter(self.win_event_filter)
            self.win_event_filter = None
        if self.win_event_manager:
            self.win_event_manager.set_windows([])

        for handle in self._theme_window_handles:
            while handle in self.theme_manager.windows:
                self.theme_manager.windows.remove(handle)
        self._theme_window_handles = ()

        root_window = getattr(self, "root_window", None)
        if root_window:
            root_window.hide()
            root_window.releaseResources()
            root_window.deleteLater()
            self.root_window = None
        self.windows = []

        logger.info("ReleasableWindow released")
        self._cleanup_engine()

    def _cleanup_engine(self):
        self.engine.clearComponentCache()
        self.engine.collectGarbage()
        self.engine.deleteLater()


class Settings(ReleasableWindow, QObject):
    extraSettingsChanged = Signal()

    def __init__(self, parent):
        super().__init__(parent)
        self.bridge = PluginBackendBridge()

        self.engine.addImportPath(DEFAULT_THEME)
        self.engine.rootContext().setContextProperty(
            "UtilsBackend", self.central.utils_backend
        )
        self.engine.rootContext().setContextProperty(
            "UpdaterBridge", self.central.updater_bridge
        )
        self.engine.rootContext().setContextProperty("PluginBackendBridge", self.bridge)
        self.engine.rootContext().setContextProperty("Settings", self)
        self.extra_settings = []

        self.load(CW_PATH / "Windows" / "Settings.qml")
        logger.info("Settings window initialized")


class Editor(ReleasableWindow):
    def __init__(self, parent):
        super().__init__(parent)

        self.load(CW_PATH / "Windows" / "Editor.qml")


class PluginPlaza(ReleasableWindow):
    def __init__(self, parent):
        super().__init__(parent)
        self.plaza_bridge = PlazaBridge(self.central.configs)
        self.markdown_render_bridge = MarkdownRenderBridge()

        self.engine.rootContext().setContextProperty("PlazaBridge", self.plaza_bridge)
        self.engine.rootContext().setContextProperty("MarkdownRenderBridge", self.markdown_render_bridge)

        self.load(CW_PATH / "Windows" / "PluginPlaza.qml")

    def release(self):
        if self.is_released:
            return
        try:
            self.plaza_bridge.shutdown()
        finally:
            super().release()


class Tutorial(ReleasableWindow):
    def __init__(self, parent):
        super().__init__(parent)
        from RinUI import Theme
        self.setTheme(Theme.Auto)
        self.recommendations_bridge = TutorialRecommendationsBridge(self.central.configs)
        self.engine.rootContext().setContextProperty(
            "TutorialRecommendationsBridge", self.recommendations_bridge
        )

        self.load(CW_PATH / "Windows" / "Tutorial.qml")

    def release(self):
        if self.is_released:
            return
        try:
            self.recommendations_bridge.shutdown()
        finally:
            super().release()


class WhatsNew(ReleasableWindow):
    def __init__(self, parent):
        super().__init__(parent)
        self.engine.rootContext().setContextProperty(
            "UtilsBackend", self.central.utils_backend
        )

        self.load(CW_PATH / "Windows" / "WhatsNew.qml")


class CheckSingleInstanceDialog(ReleasableWindow):
    def __init__(self, parent):
        super().__init__(parent)

        self.load(
            CW_PATH
            / "Components"
            / "dialogs"
            / "CheckSingleInstanceDialog.qml"
        )


class ClassSwapWindow(ReleasableWindow):
    """换课窗口。

    与 :class:`src.core.windows.problem_report.ProblemReport` 属于同一类窗口：
    普通窗口，可拖动、可被 Alt+Tab / 任务栏选中，且不置顶。QML 根窗口默认隐藏
    （``visible: false``），由 :meth:`AppWindowManager.open` 统一显示并激活，
    关闭时由 ``WindowManager.closeClassSwap()`` 释放，因此可以反复打开。
    """

    def __init__(self, parent):
        super().__init__(parent)

        self.load(
            CW_PATH
            / "Components"
            / "dialogs"
            / "ClassSwapDialog.qml"
        )
        logger.info("Class swap window QML requested")


class ClassSwapRestoreDialog(ReleasableWindow):
    def __init__(self, parent):
        super().__init__(parent)

        self.load(
            CW_PATH
            / "Components"
            / "dialogs"
            / "ClassSwapRestoreDialog.qml"
        )


class ThemeLoadErrorDialog(ReleasableWindow, QObject):
    failedThemeIdChanged = Signal(str)
    recoveredChanged = Signal(bool)

    def __init__(self, parent):
        super().__init__(parent)
        self._failed_theme_id = ""
        self._recovered = True
        self._show_when_ready = False
        self.engine.rootContext().setContextProperty("ThemeLoadErrorDialog", self)
        self.engine.objectCreated.connect(self._on_object_created)
        self.engine.warnings.connect(self._on_qml_warnings)
        self.load(
            CW_PATH
            / "Components"
            / "dialogs"
            / "ThemeLoadErrorDialog.qml"
        )
        logger.info("Theme load error dialog QML requested")

    @Property(str, notify=failedThemeIdChanged)
    def failedThemeId(self) -> str:
        return self._failed_theme_id

    @Property(bool, notify=recoveredChanged)
    def recovered(self) -> bool:
        return self._recovered

    @Slot(str, bool)
    def set_error_details(self, failed_theme_id: str, recovered: bool) -> None:
        self._failed_theme_id = failed_theme_id
        self._recovered = recovered
        self.failedThemeIdChanged.emit(failed_theme_id)
        self.recoveredChanged.emit(recovered)

    def show_when_ready(self) -> None:
        self._show_when_ready = True
        self._show_root_window()

    def _on_object_created(self, obj, url) -> None:
        if obj is not None:
            logger.info("Theme load error dialog root object created")
            self._show_root_window()

    def _on_qml_warnings(self, warnings) -> None:
        for warning in warnings:
            logger.error(
                "Theme load error dialog QML warning: {}",
                warning.description(),
            )

    def _show_root_window(self) -> None:
        if not self._show_when_ready or not self.root_window:
            return
        logger.info("Showing theme load error dialog window")
        self.root_window.show()
        self.root_window.raise_()
        self.root_window.requestActivate()
