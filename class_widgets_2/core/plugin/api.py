import sys
from pathlib import Path
from loguru import logger
from PySide6.QtCore import QObject, Signal

# 导入所有API功能组件
from .components import (
    BaseAPI, WidgetsAPI, NotificationAPI, ScheduleAPI, ThemeAPI,
    RuntimeAPI, ConfigAPI, AutomationAPI, UiAPI
)

# 用于 type hint 避免循环导入
from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from class_widgets_2.core import AppCentral

__version__ = "0.4.1"


class PluginAPI:
    """插件API核心类，管理所有插件可用的API功能"""
    
    def __init__(self, app: "AppCentral"):
        self._app = app
        self._current_plugin = None  # 当前插件上下文
        
        self.widgets: WidgetsAPI = WidgetsAPI(self)
        self.notification: NotificationAPI = NotificationAPI(self)
        self.schedule: ScheduleAPI = ScheduleAPI(self)
        self.theme: ThemeAPI = ThemeAPI(self)
        self.runtime: RuntimeAPI = RuntimeAPI(self)
        self.config: ConfigAPI = ConfigAPI(self)
        self.automation: AutomationAPI = AutomationAPI(self)
        self.ui: 'UiAPI' = UiAPI(self)

    def set_current_plugin(self, plugin):
        """设置当前插件上下文"""
        self._current_plugin = plugin
    
    @property 
    def current_plugin(self) -> 'CW2Plugin':
        """获取当前插件"""
        return self._current_plugin


class CW2Plugin(QObject):
    """所有插件的基类"""
    initialized = Signal()

    def __init__(self, api: PluginAPI):
        super().__init__()

        self.PATH = Path()
        self.meta = {}
        self.pid = None
        self.api = api

        self._load_plugin_libs()  # 插件库加载

    def _load_plugin_libs(self):
        """Automatically adds the plugin's 'libs' subdirectory to sys.path."""
        # 如果 self.PATH 是空的，我们需要更可靠的方式获取根目录
        plugin_root = self.PATH if self.PATH.is_absolute() else (
            Path(__file__).parent.resolve()
        )
        libs_dir = plugin_root / 'libs'
        if libs_dir.is_dir() and str(libs_dir) not in sys.path:
            sys.path.insert(0, str(libs_dir))

    def on_load(self):
        self.pid = self.meta.get("id")
        if self.pid:
            from class_widgets_2.core.plugin.bridge import PluginBackendBridge
            PluginBackendBridge.register_backend(self.meta.get("id"), self)
            # 设置插件上下文
            self.api.set_current_plugin(self)
            logger.debug(self.meta)
        else:
            logger.warning(f"Plugin {self.meta.get('name')} missing meta.id")
        self.initialized.emit()

    def on_unload(self):
        pass

