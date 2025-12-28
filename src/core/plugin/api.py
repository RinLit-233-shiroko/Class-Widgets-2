import sys
from pathlib import Path
from typing import Optional, List, Dict, Union
from datetime import datetime
from PySide6.QtCore import Signal, QUrl
from loguru import logger

from src.core.config.model import ConfigBaseModel, PluginsConfig
from src.core.plugin.bridge import PluginBackendBridge
from src.core.schedule.model import EntryType
from PySide6.QtCore import QObject


__version__ = "0.2.0"


class WidgetsAPI:
    def __init__(self, app):
        self._app = app

    def register(self, widget_id: str, name: str, qml_path: Union[str, Path],
                 backend_obj: QObject = None,
                 settings_qml: Optional[Union[str, Path]] = None,
                 default_settings: Optional[dict] = None):
        self._app.widgets_model.add_widget(
            widget_id, name, qml_path, backend_obj, settings_qml, default_settings
        )


from loguru import logger

class NotificationAPI(QObject):
    pushed = Signal(str)  # 给插件监听的信号

    def __init__(self, app):
        super().__init__()
        self._app = app
        app.notification.notified.connect(self._on_notification)

    def _on_notification(self, payload):
        """处理通知信号并发射给插件"""
        try:
            title = payload.get('title', '通知')
            message = payload.get('message', '')
            if message:
                notification_text = f"{title}: {message}"
            else:
                notification_text = title
            self.pushed.emit(notification_text)
        except Exception as e:
            logger.error(f"Error processing notification: {e}")
            self.pushed.emit("通知")

    def get_provider(
            self, plugin, provider_id: str, name: str = None,
            icon: Union[str, Path] = None, use_system_notify: bool = False
    ):
        """
        为插件创建一个 NotificationProvider 实例

        returns:
            NotificationProvider: 可用于发送通知的 Provider 实例
        """
        from src.core.notification import NotificationProvider

        # 如果没有指定名称，使用默认名称
        if name is None:
            name = f"Plugin Provider ({provider_id})"

        if hasattr(icon, 'is_absolute') and not icon.is_absolute():
            icon = plugin.PATH / icon

        provider = NotificationProvider(
            id=provider_id,
            name=name,
            icon=icon,
            manager=self._app.notification,
            use_system_notify=use_system_notify
        )
        
        logger.debug(f"Created notification provider: {provider_id} with icon: {icon}")
        return provider


class ScheduleAPI:
    def __init__(self, app):
        self._app = app

    def get(self):
        return self._app.schedule

    def reload(self):
        self._app.reloadSchedule()


class ThemeAPI(QObject):
    changed = Signal(str)

    def __init__(self, app):
        super().__init__()
        self._app = app
        app.theme_manager.themeChanged.connect(self.changed.emit)

    def current(self) -> Optional[str]:
        return self._app.theme_manager.current_theme


class RuntimeAPI(QObject):
    """暴露 ScheduleRuntime 的状态给插件"""
    updated = Signal()       # 课表/时间更新
    statusChanged = Signal(str)  # 当前日程状态变化
    entryChanged = Signal(dict)  # 当前 Entry 更新

    def __init__(self, app):
        super().__init__()
        self._runtime = app.runtime
        self._runtime.updated.connect(self._on_runtime_updated)
        self._runtime.currentsChanged.connect(lambda t: self.statusChanged.emit(t.value))

    # ------------------- 时间 -------------------
    @property
    def current_time(self) -> datetime:
        return self._runtime.current_time

    @property
    def current_day_of_week(self) -> int:
        return self._runtime.current_day_of_week

    @property
    def current_week(self) -> int:
        return self._runtime.current_week

    @property
    def current_week_of_cycle(self) -> int:
        return self._runtime.current_week_of_cycle

    @property
    def time_offset(self) -> int:
        return self._runtime.time_offset

    # ------------------- 日程 -------------------
    @property
    def schedule_meta(self) -> Optional[Dict]:
        if not self._runtime.schedule_meta:
            return None
        return self._runtime.schedule_meta.model_dump()

    @property
    def current_day_entries(self) -> List[Dict]:
        if not self._runtime.current_day:
            return []
        return [e.model_dump() for e in self._runtime.current_day.entries]

    @property
    def current_entry(self) -> Optional[Dict]:
        if not self._runtime.current_entry:
            return None
        return self._runtime.current_entry.model_dump()

    @property
    def next_entries(self) -> List[Dict]:
        if not self._runtime.next_entries:
            return []
        return [e.model_dump() for e in self._runtime.next_entries]

    @property
    def remaining_time(self) -> Dict:
        if not self._runtime.remaining_time:
            return {"minute": 0, "second": 0}
        r = self._runtime.remaining_time
        return {"minute": r.seconds // 60, "second": r.seconds % 60}

    @property
    def progress(self) -> float:
        return self._runtime.get_progress_percent() or 0.0

    @property
    def current_status(self) -> str:
        return self._runtime.current_status.value if self._runtime.current_status else EntryType.FREE.value

    @property
    def current_subject(self) -> Optional[Dict]:
        if not self._runtime.current_subject:
            return None
        return self._runtime.current_subject.model_dump()

    @property
    def current_title(self) -> Optional[str]:
        return self._runtime.current_title

    def _on_runtime_updated(self):
        self.updated.emit()
        self.entryChanged.emit(self.current_entry or {})


class ConfigAPI:
    def __init__(self, app):
        self.app = app
        self._cm = app.configs
        self._plugin_models: Dict[str, ConfigBaseModel] = {}  # 运行时对象

    def register_plugin_model(self, plugin_id: str, model: ConfigBaseModel):
        """
        注册插件配置 Model
        """
        if plugin_id in self._cm.plugins.configs:
            saved_config = self._cm.plugins.configs[plugin_id]
            try:
                # 使用模型解析已保存的配置
                validated = type(model).model_validate(saved_config)
                # 更新模型实例
                for field in model.__fields__:
                    if hasattr(validated, field):
                        setattr(model, field, getattr(validated, field))
            except Exception as e:
                logger.warning(f"Failed to load saved config for {plugin_id}: {e}")
                # 如果解析失败，保存当前模型到配置
                self._cm.plugins.configs[plugin_id] = model.model_dump()
        else:
            # 用模型默认值初始化
            self._cm.plugins.configs[plugin_id] = model.model_dump()
        self._plugin_models[plugin_id] = model
        original_on_change = getattr(model, '_on_change', None)

        def _sync_to_config_manager():
            if original_on_change:
                try:
                    original_on_change()
                except Exception as e:
                    logger.error(f"Error in original _on_change for {plugin_id}: {e}")

            # 同步到 ConfigManager
            try:
                self._cm.plugins.configs[plugin_id] = model.model_dump()
                self._cm._config._on_change()
            except Exception as e:
                logger.error(f"Failed to sync config for {plugin_id}: {e}")
        model._on_change = _sync_to_config_manager
        model._on_change()

        logger.debug(f"Plugin: {plugin_id} registered config model: {model}")

    def get_plugin_model(self, plugin_id: str) -> Optional[ConfigBaseModel]:
        return self._plugin_models.get(plugin_id)

    def save(self):
        return self._cm.save()


class AutomationAPI:
    def __init__(self, app):
        self._app = app

    def register(self, task):
        self._app.automation_manager.add_task(task)


class UiAPI(QObject):
    settingsPageRegistered = Signal()
    def __init__(self):
        super().__init__()
        self._registered_pages: list[dict] = []

    @property
    def pages(self):
        return self._registered_pages

    def unregister_settings_page(self, plugin, qml_path: Union[str, Path]):
        qml_path = Path(qml_path)
        if not qml_path.is_absolute():
            qml_path = plugin.PATH / qml_path
        qml_path = qml_path.as_uri()

        for page in self._registered_pages:
            if page["page"] == str(qml_path):
                self._registered_pages.remove(page)
                logger.debug(f"Unregister settings page: {qml_path}")
        self.settingsPageRegistered.emit()

    def register_settings_page(
        self,
        plugin,
        qml_path: str | Path,
        title: str | None = None,
        icon: str | None = None
    ):
        """插件提供相对路径，可自定义 title 和 icon"""
        qml_path = Path(qml_path)
        if not qml_path.is_absolute():
            qml_path = plugin.PATH / qml_path

        pid = plugin.meta.get("id")
        if not pid:
            raise ValueError("Plugin initialization failed, missing meta.id")

        self._registered_pages.append({
            "id": pid,
            "page": qml_path.resolve().as_uri(),
            "title": title or plugin.meta.get("name", "UNKNOWN"),
            "icon": icon or plugin.meta.get("icon", "ic_fluent_cube_20_regular")
        })
        self.settingsPageRegistered.emit()
        logger.debug(f"Plugin: {pid} register settings page: {qml_path}")


class PluginAPI:
    def __init__(self, app):
        self.widgets: WidgetsAPI = WidgetsAPI(app)
        self.notification: NotificationAPI = NotificationAPI(app)
        self.schedule: ScheduleAPI = ScheduleAPI(app)
        self.theme: ThemeAPI = ThemeAPI(app)
        self.runtime: RuntimeAPI = RuntimeAPI(app)
        self.config: ConfigAPI = ConfigAPI(app)
        self.automation: AutomationAPI = AutomationAPI(app)
        self.ui: UiAPI = UiAPI()


class CW2Plugin(QObject):
    def __init__(self, api: PluginAPI):
        super().__init__()
        self.PATH = Path()
        self.meta = {}
        self.pid = None
        self.api = api
        self._load_plugin_libs()  # 插件库加载

    def _load_plugin_libs(self):
        """Automatically adds the plugin's 'lib' subdirectory to sys.path."""
        # 如果 self.PATH 是空的，我们需要更可靠的方式获取根目录
        plugin_root = self.PATH if self.PATH.is_absolute() else (
            Path(__file__).parent.resolve()
        )
        lib_dir = plugin_root / 'lib'
        if lib_dir.is_dir() and str(lib_dir) not in sys.path:
            sys.path.insert(0, str(lib_dir))

    def on_load(self):
        self.pid = self.meta.get("id")
        if self.pid:
            PluginBackendBridge.register_backend(self.meta.get("id"), self)
            logger.debug(self.meta)
        else:
            logger.warning(f"Plugin {self.meta.get('name')} missing meta.id")

    def on_unload(self):
        pass
