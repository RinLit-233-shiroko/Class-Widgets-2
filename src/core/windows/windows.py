from loguru import logger
from PySide6.QtCore import QObject, QTimer, Signal

from RinUI import RinUIWindow
from src.core.directories import CW_PATH, DEFAULT_THEME
from src.core.plaza import MarkdownRenderBridge, PlazaBridge
from src.core.plugin.bridge import PluginBackendBridge


class ReleasableWindow(RinUIWindow):
    def release(self):
        root_window = getattr(self, "root_window", None)
        if root_window:
            root_window.hide()
            root_window.deleteLater()
            self.root_window = None
        QTimer.singleShot(0, self._cleanup_engine)

    def _cleanup_engine(self):
        self.engine.clearComponentCache()
        self.engine.collectGarbage()


class Settings(ReleasableWindow, QObject):
    extraSettingsChanged = Signal()

    def __init__(self, parent):
        super().__init__()
        self.central = parent
        self.bridge = PluginBackendBridge()

        self.engine.addImportPath(DEFAULT_THEME)
        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty(
            "UtilsBackend", self.central.utils_backend
        )
        self.engine.rootContext().setContextProperty(
            "UpdaterBridge", self.central.updater_bridge
        )
        self.engine.rootContext().setContextProperty("PluginBackendBridge", self.bridge)
        self.engine.rootContext().setContextProperty("Settings", self)
        self.central.retranslate.connect(self.engine.retranslate)
        self.extra_settings = []

        self.load(CW_PATH / "Windows" / "Settings.qml")
        logger.info("Settings window initialized")


class Editor(ReleasableWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "Windows" / "Editor.qml")


class PluginPlaza(ReleasableWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent
        self.plaza_bridge = PlazaBridge()
        self.markdown_render_bridge = MarkdownRenderBridge()

        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("PlazaBridge", self.plaza_bridge)
        self.engine.rootContext().setContextProperty("MarkdownRenderBridge", self.markdown_render_bridge)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "Windows" / "PluginPlaza.qml")

    def release(self):
        self.plaza_bridge.shutdown()
        super().release()


class Tutorial(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty(
            "UtilsBackend", self.central.utils_backend
        )
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "Windows" / "Tutorial.qml")


class WhatsNew(ReleasableWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)
        self.engine.rootContext().setContextProperty(
            "UtilsBackend", self.central.utils_backend
        )

        self.load(CW_PATH / "Windows" / "WhatsNew.qml")


class CheckSingleInstanceDialog(ReleasableWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(
            CW_PATH
            / "Components"
            / "editor"
            / "dialogs"
            / "CheckSingleInstanceDialog.qml"
        )


class ClassSwapWindow(ReleasableWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(
            CW_PATH
            / "Components"
            / "dialogs"
            / "ClassSwapDialog.qml"
        )


class ClassSwapRestoreDialog(ReleasableWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(
            CW_PATH
            / "Components"
            / "dialogs"
            / "ClassSwapRestoreDialog.qml"
        )
