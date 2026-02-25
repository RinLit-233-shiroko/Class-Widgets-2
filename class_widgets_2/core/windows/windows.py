from loguru import logger
from PySide6.QtCore import QObject, Signal

from RinUI import RinUIWindow
from class_widgets_2.core.directories import CW_PATH, DEFAULT_THEME
from class_widgets_2.core.plaza import PlazaBridge
from class_widgets_2.core.plugin.bridge import PluginBackendBridge


class Settings(RinUIWindow, QObject):
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


class Editor(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "Windows" / "Editor.qml")


class PluginPlaza(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent
        self.plaza_bridge = PlazaBridge()

        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("PlazaBridge", self.plaza_bridge)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "Windows" / "PluginPlaza.qml")


class Tutorial(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "Windows" / "Tutorial.qml")


class WhatsNew(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)
        self.engine.rootContext().setContextProperty(
            "UtilsBackend", self.central.utils_backend
        )

        self.load(CW_PATH / "Windows" / "WhatsNew.qml")


class CheckSingleInstanceDialog(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("AppCentral", self.central)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(
            CW_PATH
            / "Components"
            / "editor"
            / "dialogs"
            / "CheckSingleInstanceDialog.qml"
        )
