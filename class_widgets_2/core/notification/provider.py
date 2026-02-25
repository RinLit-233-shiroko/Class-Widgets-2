from PySide6.QtCore import QObject, Slot
from typing import Optional, Union
from pathlib import Path
from .model import NotificationData, NotificationLevel, NotificationProviderConfig

class NotificationProvider(QObject):
    """
    一个 Provider = 一个通知来源（模块 / 插件）
    """

    def __init__(
        self,
        id: str,
        name: str,
        icon: Optional[Union[str, Path]] = None,
        use_system_notify: bool = False,  # 是否支持系统通知
        manager=None,  # 默认 None，内部会自动获取
    ):
        super().__init__()
        self.id = id
        self.name = name
        self.use_system_notify = use_system_notify  # 记录是否支持系统通知
        
        # 自动处理图标：支持 Path 对象和字符串
        if icon is not None and isinstance(icon, Path):
            self.icon = icon.as_uri()
        else:
            # 字符串直接使用
            self.icon = icon

        # 自动获取 manager（如果没传，则尝试从 AppCentral.notification）
        if manager is None:
            from class_widgets_2.core import AppCentral
            self.manager = AppCentral.instance().notification  # 假设 AppCentral 提供 instance()
        else:
            self.manager = manager

        # 自动注册
        self.manager.register_provider(self)

    # ---------- config ----------
    def get_config(self) -> NotificationProviderConfig:
        """
        从 ConfigManager 读取该 provider 的配置
        """
        cfg = self.manager.configs.notifications.providers.get(self.id, None)
        if cfg is None:
            return NotificationProviderConfig()
        return cfg

    @Slot(int, str, str, int, bool, result=None)  # QML 调用签名: level, title, message, duration, closable
    def push(
            self,
            level: int,
            title: str,
            message: Optional[str],
            duration: int,
            closable: bool,
    ):
        cfg = self.get_config()
        if not cfg.enabled:
            return

        data = NotificationData(
            provider_id=self.id,
            level=level,
            title=title,
            message=message,
            duration=duration,
            closable=closable,
            icon=self.icon,  # 传递 Provider 的图标信息
        )

        self.manager.dispatch(data, cfg)