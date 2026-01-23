import sys
from pathlib import Path
from typing import Optional, List, Dict, Union
from datetime import datetime
from PySide6.QtCore import Signal, QObject
from loguru import logger

from src.core.config.model import ConfigBaseModel, PluginsConfig
from src.core.plugin.bridge import PluginBackendBridge
from src.core.notification import NotificationProvider
from src.core.schedule.model import EntryType


class BaseAPI(QObject):
    """所有API类的基类，提供通用的方法和属性"""
    
    def __init__(self, plugin_api):
        super().__init__()
        self._plugin_api = plugin_api
    
    @property
    def _app(self):
        return self._plugin_api._app
    
    @property 
    def current_plugin(self):
        """获取当前插件"""
        return self._plugin_api.current_plugin
    
    def _resolve_path(self, path: Union[str, Path]) -> Path:
        """统一的路径解析方法"""
        path = Path(path)
        if not path.is_absolute():
            plugin = self.current_plugin
            if plugin and plugin.PATH:
                path = plugin.PATH / path
            else:
                # 对于内置插件，使用相对路径
                logger.debug(f"Built-in plugin path resolution: using relative path {path}")
        return path


class WidgetsAPI(BaseAPI):
    def register(self, widget_id: str, name: str, qml_path: Union[str, Path],
                 backend_obj: QObject = None,
                 settings_qml: Optional[Union[str, Path]] = None,
                 default_settings: Optional[dict] = None):
        if not self.current_plugin:
            raise ValueError("No plugin context available. Make sure this method is called within a plugin.")
            
        # 使用统一的路径解析方法
        qml_path = self._resolve_path(qml_path)
        
        settings_qml_processed = None
        if settings_qml:
            settings_qml_processed = self._resolve_path(settings_qml)
        
        self._app.widgets_model.add_widget(
            widget_id, name, qml_path, backend_obj, settings_qml_processed, default_settings
        )


class NotificationAPI(BaseAPI):
    pushed = Signal(str)  # 给插件监听的信号

    def __init__(self, plugin_api):
        super().__init__(plugin_api)
        self._plugin_api._app.notification.notified.connect(self._on_notification)
    
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
            self, provider_id: str, name: str = None,
            icon: Union[str, Path] = None, use_system_notify: bool = False
    ) -> NotificationProvider:
        return self.register_provider(
            provider_id, name, icon, use_system_notify
        )

    def register_provider(
            self, provider_id: str, name: str = None,
            icon: Union[str, Path] = None, use_system_notify: bool = False
    ) -> NotificationProvider:
        """
        为插件创建一个 NotificationProvider 实例

        returns:
            NotificationProvider: 可用于发送通知的 Provider 实例
        """
        if not self.current_plugin:
            raise ValueError("No plugin context available. Make sure this method is called within a plugin.")

        # 如果没有指定名称，使用默认名称
        if name is None:
            name = f"Plugin Provider ({provider_id})"

        # 使用统一的路径解析方法
        if icon:
            icon = self._resolve_path(icon)

        provider = NotificationProvider(
            id=provider_id,
            name=name,
            icon=icon,
            manager=self._app.notification,
            use_system_notify=use_system_notify
        )
        
        logger.debug(f"Created notification provider: {provider_id} with icon: {icon}")
        return provider


class ScheduleAPI(BaseAPI):
    def get(self):
        return self._app.schedule

    def reload(self):
        self._app.reloadSchedule()


class ThemeAPI(BaseAPI):
    changed = Signal(str)

    def __init__(self, plugin_api):
        super().__init__(plugin_api)
        # 连接主题变更信号，传递主题ID
        def on_theme_changed():
            theme_id = self._plugin_api._app.themeManager.currentTheme
            self.changed.emit(theme_id)
        
        self._plugin_api._app.themeManager.themeChanged.connect(on_theme_changed)

    def current(self) -> Optional[str]:
        return self._app.themeManager.current_theme


class RuntimeAPI(BaseAPI):
    """暴露 ScheduleRuntime 的状态给插件"""
    updated = Signal()       # 课表/时间更新
    statusChanged = Signal(str)  # 当前日程状态变化
    entryChanged = Signal(dict)  # 当前 Entry 更新

    def __init__(self, plugin_api):
        super().__init__(plugin_api)
        self._runtime = self._app.runtime
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


class ConfigAPI(BaseAPI):
    def __init__(self, plugin_api):
        super().__init__(plugin_api)
        self._cm = self._app.configs
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


class AutomationAPI(BaseAPI):
    def register(self, task):
        self._app.automation_manager.add_task(task)


class UiAPI(BaseAPI):
    settingsPageRegistered = Signal()
    
    def __init__(self, plugin_api):
        super().__init__(plugin_api)
        self._registered_pages: list[dict] = []

    @property
    def pages(self):
        return self._registered_pages

    def unregister_settings_page(self, qml_path: Union[str, Path]):
        # 使用统一的路径解析方法
        qml_path = self._resolve_path(qml_path).as_uri()

        for page in self._registered_pages:
            if page["page"] == str(qml_path):
                self._registered_pages.remove(page)
                logger.debug(f"Unregister settings page: {qml_path}")
        self.settingsPageRegistered.emit()

    def register_settings_page(
        self,
        qml_path: str | Path,
        title: str | None = None,
        icon: str | None = None
    ):
        """
        插件提供相对路径，可自定义 title 和 icon

        :param qml_path:
        :param title:
        :param icon: RinUI 内置图标库的图标名称，如 "ic_fluent_cube_20_regular"；可下载 RinUI Icon Library 查找
        :return:
        """
        if not self.current_plugin:
            raise ValueError("No plugin context available. Make sure this method is called within a plugin.")
            
        # 使用统一的路径解析方法
        qml_path = self._resolve_path(qml_path)

        pid = self.current_plugin.meta.get("id")
        if not pid:
            raise ValueError("Plugin initialization failed, missing meta.id")

        self._registered_pages.append({
            "id": pid,
            "page": qml_path.resolve().as_uri(),
            "title": title or self.current_plugin.meta.get("name", "UNKNOWN"),
            "icon": icon or "ic_fluent_cube_20_regular"  # 仅可使用 RinUI 内置图标库的图标
        })
        self.settingsPageRegistered.emit()
        logger.debug(f"Plugin: {pid} register settings page: {qml_path}")
