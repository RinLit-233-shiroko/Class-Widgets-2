from __future__ import annotations

import sys
from enum import Enum, auto
from pathlib import Path
from typing import Any, Optional, TYPE_CHECKING, Protocol

from PySide6.QtCore import QCoreApplication, QObject, Property, Signal, Slot, QPoint, QProcess, QTimer
from PySide6.QtGui import QFont, QIcon
from PySide6.QtWidgets import QApplication
from loguru import logger

from src.core import CONFIGS_PATH, QML_PATH
from src.core.directories import PathManager, ASSETS_PATH, LOGS_PATH

if TYPE_CHECKING:
    from src.core.notification.manager import NotificationManager, NotificationService
    from src.core.plugin.api import PluginAPI
    from src.core.plugin.manager import PluginManager
    from src.core.schedule import ScheduleRuntime, ScheduleManager
    from src.core.schedule.editor import ScheduleEditor
    from src.core.schedule.swapper import ClassSwapManager
    from src.core.themes import ThemeManager
    from src.core.timer import UnionUpdateTimer
    from src.core.updater.bridge import UpdaterBridge
    from src.core.utils import TrayIcon, AppTranslator, UtilsBackend
    from src.core.utils.instance_locker import SingleInstanceGuard
    from src.core.widgets import WidgetsWindow, WidgetListModel
    from src.core.automations.manager import AutomationManager
    from src.core.windows.manager import AppWindowManager

# runtime imports
from src.core.notification import (
    NotificationManager,
    NotificationService,
)
from src.core.config.manager import ConfigManager
from src.core.plugin.api import PluginAPI
from src.core.plugin.manager import PluginManager
from src.core.schedule import ScheduleRuntime, ScheduleManager
from src.core.schedule.editor import ScheduleEditor
from src.core.schedule.swapper import ClassSwapManager
from src.core.themes import ThemeManager
from src.core.timer import UnionUpdateTimer
from src.core.updater import UpdaterBridge
from src.core.utils import AppTranslator, UtilsBackend
from src.core.utils.instance_locker import SingleInstanceGuard
from src.core.widgets import WidgetsWindow, WidgetListModel
from src.core.automations.manager import AutomationManager
from src.core.windows.manager import AppWindowManager


class QmlContextWindow(Protocol):
    engine: Any


class StartupState(Enum):
    CREATED = auto()
    WAITING_FOR_TUTORIAL = auto()
    INITIALIZING = auto()
    RUNNING = auto()
    FAILED = auto()


class AppCentral(QObject):  # Class Widgets 的中枢
    _instance: Optional[AppCentral] = None
    _BUILTIN_SHORTCUT_NAMES = {
        "com.classwidgets.settings": "Settings",
        "com.classwidgets.schedules": "Schedules",
        "com.classwidgets.plugin-plaza": "Plugin Plaza",
        "com.classwidgets.reschedule-day": "Reschedule Day",
        "com.classwidgets.class-swap": "Class Swap",
    }
    
    updated = Signal()
    initialized = Signal()
    togglePanel = Signal(QPoint)
    widgetRegistered = Signal(str)  # 新增：widget注册信号
    retranslate = Signal()  # 新增：翻译信号
    trayShortcutRequested = Signal(str)

    def __init__(self) -> None:  # 初始化
        super().__init__()
        
        # Singleton pattern - store instance
        if AppCentral._instance is not None:
            raise RuntimeError("AppCentral is a singleton. Use AppCentral.instance() instead.")
        AppCentral._instance = self

        self._check_single_instance()
        self._startup_state = StartupState.CREATED
        self._startup_swap_restore_pending: bool = False
        self._startup_swap_restore_scheduled: bool = False
        self._cleanup_started = False
        self._restart_requested = False
        self._initialize_cores()
        self._initialize_app_icon()
        self._initialize_windows_appid()
        self._initialize_notification()
        self._initialize_schedule_components()
        self._initialize_utils()
        self._initialize_ui_components()
        self.app_instance.aboutToQuit.connect(self.cleanup)
        logger.info("AppCentral initialization completed")

    def _check_single_instance(self) -> None:
        """确保单实例运行"""
        self.instance_guard: SingleInstanceGuard = SingleInstanceGuard()
        if not self.instance_guard.try_acquire():
            lock_info = self.instance_guard.get_lock_info()
            logger.error(f"Another instance is already running: {lock_info}")
            self.multi_instances = True
            return 
        self.multi_instances: bool = False

    @classmethod
    def instance(cls) -> AppCentral:
        """获取 AppCentral 单例实例"""
        if cls._instance is None:
            raise RuntimeError("AppCentral instance not created. Create an instance first.")
        return cls._instance

    def _initialize_cores(self) -> None:
        """初始化核心"""
        self.app_instance: Optional[QApplication] = QApplication.instance()
        self.path_manager: PathManager = PathManager()  # 统一路径管理
        self.configs: ConfigManager = ConfigManager(path=CONFIGS_PATH, filename="configs.json")
        self.theme_manager: ThemeManager = ThemeManager(self)
        self.widgets_model: WidgetListModel = WidgetListModel(self)
        self.tray_icon: Optional[TrayIcon] = None
        self.window_manager: AppWindowManager = AppWindowManager(self)

    def _initialize_notification(self) -> None:
        """初始化通知系统"""
        self._notification: NotificationManager = NotificationManager(config_manager=self.configs, app_central=self)
        self.notification_service: NotificationService = NotificationService(self._notification, self.configs)

    def _initialize_utils(self) -> None:
        self.plugin_api: PluginAPI = PluginAPI(self)
        self.app_translator: AppTranslator = AppTranslator(self)
        self._register_shortcuts()
        self.plugin_manager: PluginManager = PluginManager(self.plugin_api, self)
        self.utils_backend: UtilsBackend = UtilsBackend(self)
        self.automation_manager: AutomationManager = AutomationManager(self)
        self.updater_bridge: UpdaterBridge = UpdaterBridge(self)

    def _register_shortcuts(self) -> None:
        shortcuts = self.plugin_api.ui
        shortcuts.register_shortcut(
            "com.classwidgets.settings",
            QCoreApplication.translate("Shortcuts", "Settings"),
            self.path_manager.images("icons/cw2_settings.png"),
            self.window_manager.open_settings,
        )
        shortcuts.register_shortcut(
            "com.classwidgets.schedules",
            QCoreApplication.translate("Shortcuts", "Schedules"),
            self.path_manager.images("icons/cw2_editor.png"),
            self.window_manager.open_editor,
        )
        shortcuts.register_shortcut(
            "com.classwidgets.plugin-plaza",
            QCoreApplication.translate("Shortcuts", "Plugin Plaza"),
            self.path_manager.images("icons/cw2_plugin.png"),
            self.window_manager.open_plugin_plaza,
        )
        shortcuts.register_shortcut(
            "com.classwidgets.reschedule-day",
            QCoreApplication.translate("Shortcuts", "Reschedule Day"),
            "ic_fluent_calendar_arrow_counterclockwise_20_regular",
            self._request_reschedule_day_shortcut,
        )
        shortcuts.register_shortcut(
            "com.classwidgets.class-swap",
            QCoreApplication.translate("Shortcuts", "Class Swap"),
            "ic_fluent_arrow_swap_20_regular",
            self.window_manager.open_class_swap,
        )

    def _request_reschedule_day_shortcut(self) -> bool:
        self.trayShortcutRequested.emit("com.classwidgets.reschedule-day")
        return False

    def _retranslate_builtin_shortcuts(self) -> None:
        shortcuts = self.plugin_api.ui
        for shortcut_id, source_text in self._BUILTIN_SHORTCUT_NAMES.items():
            shortcuts.set_shortcut_name(
                shortcut_id,
                QCoreApplication.translate("Shortcuts", source_text),
            )

    def _initialize_schedule_components(self):
        """初始化调度相关组件"""
        self.union_update_timer: UnionUpdateTimer = UnionUpdateTimer()
        self.schedule_manager: ScheduleManager = ScheduleManager(Path(CONFIGS_PATH / "schedules"), self)

        self.runtime: ScheduleRuntime = ScheduleRuntime(self)
        self._schedule_editor: ScheduleEditor = ScheduleEditor(self.schedule_manager)
        self._class_swap_manager: ClassSwapManager = ClassSwapManager(self)

    def _initialize_app_icon(self) -> None:
        """设置图标"""
        icon_path = ASSETS_PATH / "images" / "logo.ico"
        self.app_instance.setWindowIcon(QIcon(str(icon_path)))

    def _initialize_windows_appid(self) -> None:
        """解决 Windows 默认图标问题"""
        if sys.platform == 'win32':
            try:
                import ctypes
                ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID('org.classwidgets.app')
            except Exception as e:
                logger.error(f"Failed to set AppUserModelID: {e}")

    def _initialize_ui_components(self):
        """初始化启动必需的UI组件"""
        self.widgets_window: WidgetsWindow = WidgetsWindow(self)
        self.widgets_window.qmlReady.connect(self._schedule_startup_swap_restore_prompt)
        if self.multi_instances:
            self.window_manager.ensure("single_instance")

    def run(self) -> None:  # 运行
        self._load_config()  # 加载配置
        self._load_translator()  # 加载翻译

        if self.multi_instances:
            if not (getattr(sys, "frozen", False) and sys.platform == "darwin"):
                logger.info("Not running in a frozen macOS app. Skipped single instance check.")
                self.quit()
            self.window_manager.open_single_instance_dialog()
        else:
            self.init()

    @Slot()
    def init(self) -> None:
        if self._startup_state is not StartupState.CREATED:
            logger.warning(
                "Ignoring duplicate initialization request in state {}",
                self._startup_state.name,
            )
            return

        # 如果教程未完成，先显示引导窗口
        if not getattr(self.configs.app, "tutorial_completed", False):
            logger.info("Tutorial not completed, showing tutorial window first.")
            self._startup_state = StartupState.WAITING_FOR_TUTORIAL
            self.window_manager.open_tutorial()
            return  # 中断后续初始化流程，教程窗口负责完成设置后重启

        self._startup_state = StartupState.INITIALIZING
        try:
            self._setup_logging()  # 设置日志
            self._load_schedule()  # 加载课程表
            self._load_class_swap()  # 加载换课记录（跨天清理）
            self._startup_swap_restore_pending = self._class_swap_manager.hasTodaySwaps()

            self._load_runtime()  # 加载运行时(以及插件)
            self._init_tray_icon()  # 初始化托盘图标
            self._run_utils()
        except Exception:
            self._startup_state = StartupState.FAILED
            logger.exception("Application initialization failed")
            raise

        self._startup_state = StartupState.RUNNING
        self.initialized.emit()
        logger.info("Initialization completed.")
        self._schedule_startup_swap_restore_prompt()

    @Slot()
    def _schedule_startup_swap_restore_prompt(self) -> None:
        if (
            self._startup_state is not StartupState.RUNNING
            or not self._startup_swap_restore_pending
            or self._startup_swap_restore_scheduled
            or not self.widgets_window.is_qml_ready
        ):
            return

        self._startup_swap_restore_scheduled = True
        QTimer.singleShot(0, self._show_startup_swap_restore_prompt)

    def _show_startup_swap_restore_prompt(self) -> None:
        self._startup_swap_restore_scheduled = False
        if (
            self._startup_state is not StartupState.RUNNING
            or not self._startup_swap_restore_pending
        ):
            return

        logger.warning("Detected temporary class swaps for today on startup, prompting user for action")
        self.window_manager.open_class_swap_restore()

    def resolve_class_swap_restore(self, *, discard: bool) -> None:
        if discard:
            self._class_swap_manager.discardTodaySwaps()
        self._startup_swap_restore_pending = False
        self._startup_swap_restore_scheduled = False

    def has_today_class_swaps(self) -> bool:
        return self._class_swap_manager.hasTodaySwaps()



    def _load_config(self) -> None:
        """加载和验证配置"""
        self.configs.load_config()

    def _load_class_swap(self) -> None:
        """加载换课记录，跨天时自动清理"""
        self._class_swap_manager.loadSwapRecords()

    def update(self) -> None:
        self.runtime.refresh()
        self.updated.emit()  # 发送信号

    def cleanup(self) -> None:
        if self._cleanup_started:
            return
        self._cleanup_started = True

        cleanup_steps = (
            ("configuration save", self.configs.save),
            ("update timer stop", self.union_update_timer.stop),
            ("auxiliary window release", self.window_manager.release_all),
            ("main window release", self.widgets_window.release),
            ("plugin cleanup", self.plugin_manager.cleanup),
            ("RinUI theme cleanup", self.widgets_window.theme_manager.clean_up),
            ("single instance lock release", self.instance_guard.release),
        )
        for step_name, cleanup_step in cleanup_steps:
            try:
                cleanup_step()
            except Exception:
                logger.exception("Failed during {}", step_name)
        logger.info("Clean up.")

    @Property(QObject, notify=initialized)
    def scheduleRuntime(self) -> QObject:  # 运行时
        return self.runtime

    @Property(QObject)
    def notification(self) -> QObject:
        return self._notification

    notification: "NotificationManager[ConfigManager]"

    @Property(QObject, notify=initialized)
    def scheduleEditor(self) -> QObject:  # 课程表编辑器
        return self._schedule_editor

    @Property(QObject, notify=initialized)
    def classSwapManager(self):  # 换课管理器
        return self._class_swap_manager

    @Property(QObject, notify=updated)
    def scheduleManager(self):  # 课程表管理器
        return self.schedule_manager

    @Property(QObject, notify=initialized)
    def translator(self):
        return self.app_translator

    @Property(QObject, notify=initialized)
    def themeManager(self):
        return self.theme_manager

    @Property(dict, notify=initialized)
    def globalConfig(self):  # 旧接口（仅 Debugger 使用）
        return self.configs.data

    @Slot()
    def quit(self):
        self.app_instance.quit()

    @Slot()
    @Slot(str)
    def restart(self, extra_argument: Optional[str] = None):
        if self._restart_requested:
            return

        self._restart_requested = True
        arguments = sys.argv[1:] if getattr(sys, "frozen", False) else sys.argv
        if extra_argument and extra_argument not in arguments:
            arguments.append(extra_argument)
        self.instance_guard.release()
        if not QProcess.startDetached(sys.executable, arguments):
            self.instance_guard.try_acquire()
            self._restart_requested = False
            logger.error("Failed to start replacement process for restart")
            return

        self.app_instance.quit()

    def setup_qml_context(self, window: QmlContextWindow) -> None:
        """
        为窗口设置标准的QML上下文属性

        Args:
            window: RinUIWindow实例
        """
        context = window.engine.rootContext()
        window.engine.addImportPath(QML_PATH)
        context.setContextProperty("WidgetsModel", self.widgets_model)
        context.setContextProperty("Configs", self.configs)
        context.setContextProperty("CWThemeManager", self.theme_manager)
        context.setContextProperty("PluginManager", self.plugin_manager)
        context.setContextProperty("AppCentral", self)
        context.setContextProperty("WindowManager", self.window_manager)
        context.setContextProperty("PathManager", self.path_manager)
        context.setContextProperty("ClassSwapManager", self._class_swap_manager)
        context.setContextProperty("UtilsBackend", self.utils_backend)

    @staticmethod
    def clean_qml_context(window):
        """
        为窗口设置标准的QML上下文属性
        """
        context = window.engine.rootContext()
        context.setContextProperty("WidgetsModel", None)
        context.setContextProperty("Configs", None)
        context.setContextProperty("ThemeManager", None)
        context.setContextProperty("PluginManager", None)
        context.setContextProperty("AppCentral", None)
        context.setContextProperty("WindowManager", None)
        context.setContextProperty("PathManager", None)
        context.setContextProperty("UtilsBackend", None)
        context.setContextProperty("backend", None)

    def _load_schedule(self) -> None:
        """加载课程表"""
        self.schedule_manager.load(self.configs.schedule.current_schedule)

    def _load_interactions(self) -> None:
        """加载交互"""

    def _load_translator(self) -> None:
        """加载翻译"""
        self.app_translator.languageChanged.connect(self._retranslate_builtin_shortcuts)
        self.app_translator.languageChanged.connect(lambda: self.retranslate.emit())
        self.app_translator.setLanguage(self.configs.locale.language)

    def _load_runtime(self) -> None:
        self.runtime.refresh(self.schedule_manager.schedule)
        self._setup_connections()
        self._load_theme_and_plugins()

    def _setup_connections(self) -> None:
        """设置runtime连接"""
        self.union_update_timer.tick.connect(self.update)
        self.union_update_timer.tick.connect(self.automation_manager.update)
        self.schedule_manager.scheduleModified.connect(self.runtime.refresh)
        self._class_swap_manager.updated.connect(self.update)

        self.union_update_timer.start()

    def _run_utils(self) -> None:
        self.automation_manager.init_builtin_tasks()
        self.widgets_window.run()

        if "--update-done" in sys.argv:
            sys.argv.remove("--update-done")
            self.window_manager.open_whatsnew()
            self.updater_bridge.update_complete()

    def _load_theme_and_plugins(self) -> None:
        """主题和插件"""
        logger.info("Loading themes and plugins...")
        self.theme_manager.load()
        logger.info("Themes loaded successfully")

        self.plugin_manager.set_enabled_plugins(self.configs.plugins.enabled)
        # 加载插件（内置+外部）
        self.plugin_manager.scan()  # 延迟扫描插件，确保翻译器已加载
        self.plugin_manager.load_plugins()

    def _init_tray_icon(self) -> None:
        from src.core.utils.tray import TrayIcon

        self.tray_icon = TrayIcon()
        self.tray_icon.togglePanel.connect(self._on_tray_toggle)

    def _setup_logging(self) -> None:
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

    def _on_tray_toggle(self, pos: QPoint) -> None:
        self.togglePanel.emit(pos)

    @Slot()
    def openDebugger(self) -> None:
        """显示调试器"""
        if not self.configs.app.debug_mode:
            logger.error("Looks like you tried to open the debugger without debug mode enabled, zako~")
            return
        self.window_manager.open_debugger()

    @Slot()
    def toggleWidgetsEditMode(self) -> None:
        """切换小组件编辑模式"""
        if not self.widgets_window:
            return

        root = self.widgets_window.root_window
        if not root:
            return

        widgets_loader = root.findChild(QObject, "widgetsLoader")
        if widgets_loader:
            root.raise_()
            current = widgets_loader.property("editMode")
            widgets_loader.setProperty("editMode", not current)

    @Slot(str, str, result=QFont)
    def getQFont(self, target_font: str, fallback_font: str = "Microsoft YaHei") -> QFont:
        """
        构造一个带 fallback 的 QFont 对象。

        :param target_font: 用户选择的主字体
        :param fallback_font: fallback 字体
        :return: QFont 对象
        """
        families = [
            family.strip()
            for family in (target_font, fallback_font)
            if family and family.strip()
        ]
        f = QFont()
        f.setFamilies(families)
        f.setStyleHint(QFont.StyleHint.SansSerif)
        return f
