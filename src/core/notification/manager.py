from typing import Dict

from PySide6.QtCore import Signal, QObject
from loguru import logger

from src.core.notification import NotificationData, NotificationLevel, NotificationProviderConfig


class NotificationManager(QObject):
    notified = Signal(dict)

    def __init__(self, config_manager, app_central=None):
        super().__init__()
        self.providers: Dict[str, object] = {}
        self.configs = config_manager
        self.app_central = app_central

    def register_provider(self, provider):
        if not hasattr(provider, "id") or not hasattr(provider, "name"):
            logger.warning(f"Invalid provider registration: {provider}")
            return
        
        self.providers[provider.id] = provider
        _ = provider.get_config()

    def unregister_provider(self, provider_id: str):
        """取消注册通知提供者"""
        if provider_id in self.providers:
            del self.providers[provider_id]
            logger.debug(f"Unregistered notification provider: {provider_id}")

    def is_enabled(self, provider_id: str) -> bool:
        cfg = self.configs.notifications.providers.get(provider_id)
        return True if cfg is None else cfg.enabled

    def dispatch(self, data: NotificationData, cfg=None):
        # 记录通知分发信息
        logger.info(f"Dispatching notification: {data.provider_id} - {data.title} (Level: {data.level})")

        if cfg is None:
            cfg = self.configs.notifications.providers.get(data.provider_id)
        if cfg is None:
            cfg = NotificationProviderConfig()

        if not getattr(self.configs.notifications, "enabled", True):
            return

        if not getattr(cfg, "enabled", True):
            return

        payload = data.model_dump()
        use_system_notify = getattr(cfg, "use_system_notify", False)
        use_app_notify = getattr(cfg, "use_app_notify", True)
        payload["useSystem"] = use_system_notify

        # 如果既不使用系统通知也不使用应用内通知，则直接返回
        if not use_system_notify and not use_app_notify:
            return

        provider = self.providers.get(data.provider_id)
        provider_use_system = hasattr(provider, 'use_system_notify') and provider.use_system_notify if provider else False

        # 发送系统通知
        if use_system_notify and (provider_use_system or use_system_notify):
            try:
                if self.app_central and hasattr(self.app_central, "tray_icon") and self.app_central.tray_icon:
                    self.app_central.tray_icon.push_notification(
                        title=data.title,
                        text=data.message or "",
                        icon=None
                    )
            except Exception as e:
                logger.error(f"System notification error: {e}")

        # 发送应用内通知信号
        if use_app_notify:
            self.notified.emit(payload)

            if not data.silent:
                try:
                    if self.app_central and hasattr(self.app_central, 'utils_backend') and self.app_central.utils_backend:
                        self.app_central.utils_backend.playNotificationSound(data.provider_id, data.level)
                except Exception as e:
                    logger.error(f"Sound playback error: {e}")


    
    def get_providers(self):
        """
        获取所有已注册的通知提供者信息，用于前端展示
        """
        providers_info = []

        for provider_id, provider in self.providers.items():
            # 获取提供者配置
            cfg = self.configs.notifications.providers.get(provider_id, NotificationProviderConfig())

            providers_info.append({
                "id": provider_id,
                "name": getattr(provider, "name", "Unknown Provider"),
                "icon": getattr(provider, "icon", None),
                "enabled": cfg.enabled,
                "useSystemNotify": cfg.use_system_notify,
                "useAppNotify": cfg.use_app_notify
            })

        return providers_info
