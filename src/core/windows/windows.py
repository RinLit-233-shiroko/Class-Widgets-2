from RinUI import RinUIWindow
from PySide6.QtCore import QObject, Signal

from src.core.directories import DEFAULT_THEME, CW_PATH
from src.core.plugin.bridge import PluginBackendBridge
from src.core.plaza import PlazaBridge


from loguru import logger

class Settings(RinUIWindow, QObject):
    extraSettingsChanged = Signal()
    def __init__(self, parent ):
        super().__init__()
        self.central = parent
        self.bridge = PluginBackendBridge()

        self.engine.addImportPath(DEFAULT_THEME)
        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("UtilsBackend", self.central.utils_backend)
        self.engine.rootContext().setContextProperty("UpdaterBridge", self.central.updater_bridge)
        self.engine.rootContext().setContextProperty("PluginBackendBridge", self.bridge)
        self.engine.rootContext().setContextProperty("Settings", self)
        self.central.retranslate.connect(self.engine.retranslate)
        self.extra_settings = []

        self.load(CW_PATH / "windows" / "Settings.qml")
        logger.info("Settings window initialized")


class Editor(RinUIWindow):
    def __init__(self, parent ):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "windows" / "Editor.qml")


class PluginPlaza(RinUIWindow):
    def __init__(self, parent ):
        super().__init__()
        self.central = parent
        self.plaza_bridge = PlazaBridge()

        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("PlazaBridge", self.plaza_bridge)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "windows" / "PluginPlaza.qml")

class Tutorial(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "windows" / "Tutorial.qml")


class WhatsNew(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)
        self.engine.rootContext().setContextProperty("UtilsBackend", self.central.utils_backend)

        self.load(CW_PATH / "windows" / "WhatsNew.qml")

class CheckSingleInstanceDialog(RinUIWindow):
    def __init__(self, parent):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("AppCentral", self.central)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "components" / "dialogs" / "CheckSingleInstanceDialog.qml")