import os
import sys
from pathlib import Path

from PySide6.QtCore import QObject, Property, Signal, Slot, QPoint
from PySide6.QtWidgets import QApplication
from RinUI import RinUIWindow
from loguru import logger

from src.core import CONFIGS_PATH, QML_PATH
from src.core.config import ConfigManager
from src.core.directories import PathManager, DEFAULT_THEME, CW_PATH, LOGS_PATH
from src.core.notification import Notification
from src.core.plugin.api import PluginAPI
from src.core.plugin.manager import PluginManager
from src.core.schedule import ScheduleRuntime, ScheduleManager
from src.core.schedule.editor import ScheduleEditor
from src.core.themes import ThemeManager
from src.core.timer import UnionUpdateTimer
from src.core.utils import TrayIcon, AppTranslator, UtilsBackend
from src.core.utils.debugger import DebuggerWindow
from src.core.widgets import WidgetsWindow, WidgetListModel
from src.core.automations.manager import AutomationManager


class AppCentral(QObject):  # Class Widgets 的中枢
    updated = Signal()
    initialized = Signal()
    togglePanel = Signal(QPoint)
    widgetRegistered = Signal(str)  # 新增：widget注册信号
    retranslate = Signal()  # 新增：翻译信号

    def __init__(self):  # 初始化
        super().__init__()
        self._initialize_schedule_components()
        self._initialize_cores()
        self._initialize_ui_components()

    def _initialize_cores(self):
        """初始化核心"""
        self.app_instance = QApplication.instance()
        self.path_manager = PathManager()  # 统一路径管理
        self.configs = ConfigManager(path=CONFIGS_PATH, filename="configs.json")
        self.theme_manager = ThemeManager(self)
        self.widgets_model = WidgetListModel(self)
        self.plugin_api = PluginAPI(self)
        self.plugin_manager = PluginManager(self.plugin_api, self)
        self.app_translator = AppTranslator(self)
        self.utils_backend = UtilsBackend()
        
        # 交互管理器
        self.automation_manager = AutomationManager(self)

        # debugger
        self.debugger = None

    def _initialize_schedule_components(self):
        """初始化调度相关组件"""
        self.union_update_timer = UnionUpdateTimer()
        self._notification = Notification()
        self.schedule_manager = ScheduleManager(Path(CONFIGS_PATH / "schedules"), self)

        self.runtime = ScheduleRuntime(self)
        self._schedule_editor: ScheduleEditor = ScheduleEditor(self.schedule_manager)

    def _initialize_ui_components(self):
        """初始化UI组件"""
        self.settings = Settings(self)
        self.editor = Editor(self)
        self.widgets_window: WidgetsWindow = WidgetsWindow(self)  # 简化参数传递

    def run(self):  # 运行
        self._load_config()  # 加载配置
        self._load_translator()  # 加载翻译

        # 如果教程未完成，先显示引导窗口
        if not getattr(self.configs.app, "tutorial_completed", False):
            logger.info("Tutorial not completed, showing tutorial window first.")
            self.tutorial_window = Tutorial(self)
            self.tutorial_window.root_window.show()
            return  # 中断后续初始化流程，教程窗口负责完成设置后重启

        self._setup_logging()  # 设置日志
        self._load_schedule()  # 加载课程表
        self._load_runtime()  # 加载运行时
        self._init_tray_icon()  # 初始化托盘图标
        self.initialized.emit()  # 发送信号
        logger.info(f"Configs loaded.")

    def _load_config(self):
        """加载和验证配置"""
        self.configs.load_config()

    def update(self):
        self.runtime.refresh()
        self.updated.emit()  # 发送信号

    def cleanup(self):
        self.union_update_timer.stop()
        logger.info("Clean up.")

    # for qml
    @Property(QObject, notify=initialized)
    def scheduleRuntime(self):  # 运行时
        return self.runtime

    @Property(QObject)
    def notification(self):
        return self._notification

    @Property(QObject, notify=initialized)
    def scheduleEditor(self):  # 课程表编辑器
        return self._schedule_editor

    @Property(QObject, notify=updated)
    def scheduleManager(self):  # 课程表管理器
        return self.schedule_manager

    @Property(QObject, notify=initialized)
    def translator(self):
        return self.app_translator

    @Property(dict, notify=initialized)
    def globalConfig(self):  # 旧接口（仅 Debugger 使用）
        return self.configs.data

    @Slot()
    def quit(self):
        self.configs.save()
        self.cleanup()
        self.app_instance.quit()

    @Slot()
    def restart(self):
        self.configs.save()
        self.cleanup()
        os.execl(sys.executable, sys.executable, *sys.argv)

    def setup_qml_context(self, window):
        """
        为窗口设置标准的QML上下文属性

        Args:
            window: RinUIWindow实例
        """
        context = window.engine.rootContext()
        window.engine.addImportPath(QML_PATH)
        context.setContextProperty("WidgetsModel", self.widgets_model)
        context.setContextProperty("Configs", self.configs)
        context.setContextProperty("ThemeManager", self.theme_manager)
        context.setContextProperty("PluginManager", self.plugin_manager)
        context.setContextProperty("AppCentral", self)
        context.setContextProperty("PathManager", self.path_manager)
        # context.setContextProperty("Translator", self.translator)

    def _load_schedule(self):
        """加载课程表"""
        self.schedule_manager.load(self.configs.schedule.current_schedule)

    def _load_interactions(self):
        """加载交互"""

    def _load_translator(self):
        """加载翻译"""
        self.app_translator.languageChanged.connect(lambda: self.retranslate.emit())
        self.app_translator.setLanguage(self.configs.locale.language)

    def _load_runtime(self):
        if self.configs.app.debug_mode:  # 调试模式
            self.debugger = DebuggerWindow(self)

        self.runtime.refresh(self.schedule_manager.schedule)
        self._setup_runtime_connections()
        self._load_theme_and_plugins()
        self.widgets_window.run()

    def _setup_runtime_connections(self):
        """设置runtime连接"""
        self.runtime.notify.connect(self._notification.push_activity)

        self.union_update_timer.tick.connect(self.update)
        self.union_update_timer.tick.connect(self.automation_manager.update)
        self.schedule_manager.scheduleModified.connect(self.runtime.refresh)

        self.union_update_timer.start()

    def _load_theme_and_plugins(self):
        """主题和插件"""
        self.theme_manager.load()

        self.plugin_manager.set_enabled_plugins(self.configs.plugins.enabled)
        # 加载插件（内置+外部）
        self.plugin_manager.load_plugins()

    def _init_tray_icon(self):
        self.tray_icon = TrayIcon(self)
        self.tray_icon.togglePanel.connect(self._on_tray_toggle)

    def _setup_logging(self):
        """根据 Configs.app.no_logs 决定是否写日志到文件"""
        no_logs = getattr(self.configs.app, "no_logs", False)

        if not no_logs:
            log_path = LOGS_PATH / "ClassWidgets-{time}.log"
            logger.add(
                log_path,
                rotation="1 MB",
                retention="7 days", # save for 7 days
                encoding="utf-8",
                enqueue=True,
                backtrace=True,
                diagnose=True
            )
            logger.info(f"File logging enabled at {log_path}")
        else:
            logger.info("File logging disabled by configuration")

    def _on_tray_toggle(self, pos: QPoint):
        self.togglePanel.emit(pos)

    # settings
    @Slot()
    def openSettings(self):
        """显示设置窗口"""
        if self.settings and self.settings.root_window:
            self.settings.root_window.show()
            self.settings.root_window.raise_()
            self.settings.root_window.requestActivate()
        else:
            logger.error("Settings window not initialized correctly.")

    @Slot()
    def openEditor(self):
        """显示课程表编辑器"""
        if self.editor and self.editor.root_window:
            self.editor.root_window.show()
            self.editor.root_window.raise_()
            self.editor.root_window.requestActivate()
        else:
            logger.error("Editor window not initialized correctly.")

    @Slot()
    def openDebugger(self):
        """显示调试器"""
        if not self.configs.app.debug_mode:
            logger.error("Looks like you tried to open the debugger without debug mode enabled, zako~")
            return

        instance = self.debugger
        if self.debugger and instance.root_window:
            instance.root_window.show()
            instance.root_window.raise_()
            instance.root_window.requestActivate()
        else:
            logger.error("Debugger window not initialized correctly.")

    @Slot()
    def toggleWidgetsEditMode(self):
        """切换小组件编辑模式"""
        if not self.widgets_window:
            return

        root = self.widgets_window.root_window
        widgets_loader = root.findChild(QObject, "widgetsLoader")
        if widgets_loader:
            root.raise_()
            current = widgets_loader.property("editMode")
            widgets_loader.setProperty("editMode", not current)


class Settings(RinUIWindow):
    def __init__(self, parent: AppCentral):
        super().__init__()
        self.central = parent

        self.engine.addImportPath(DEFAULT_THEME)
        self.central.setup_qml_context(self)
        self.engine.rootContext().setContextProperty("UtilsBackend", self.central.utils_backend)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "windows" / "Settings.qml")


class Editor(RinUIWindow):
    def __init__(self, parent: AppCentral):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "windows" / "Editor.qml")


class Tutorial(RinUIWindow):
    def __init__(self, parent: AppCentral):
        super().__init__()
        self.central = parent

        self.central.setup_qml_context(self)
        self.central.retranslate.connect(self.engine.retranslate)

        self.load(CW_PATH / "windows" / "Tutorial.qml")
