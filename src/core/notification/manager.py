from typing import Dict, List
from threading import Lock

from PySide6.QtCore import Signal, QObject, Slot
from loguru import logger

from src.core.notification import NotificationData, NotificationLevel, NotificationProviderConfig


class NotificationManager(QObject):
    notified = Signal(dict)

    def __init__(self, config_manager, app_central=None):
        super().__init__()
        self.providers: Dict[str, object] = {}
        self.configs = config_manager
        self.app_central = app_central
        self._qml_ready = False
        self._pending_notifications: List[dict] = []
        self._lock = Lock()

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

    # qml 准备就绪后，自动发送所有待处理
    @Slot()
    def notifyQmlReady(self):
        """
        QML 调用此方法通知 Python 端 QML 已准备就绪
        此方法会自动刷新所有待处理的通知
        """
        self.set_qml_ready(True)

    def set_qml_ready(self, ready: bool = True):
        """
        设置 QML 是否已准备就绪
        当 QML 准备好后，会自动发送所有待处理的通知
        """
        pending = None
        with self._lock:
            self._qml_ready = ready
            if ready and self._pending_notifications:
                logger.info(f"QML ready, flushing {len(self._pending_notifications)} pending notifications")
                pending = list(self._pending_notifications)
                self._pending_notifications.clear()

        if ready and pending:
            for payload in pending:
                self.notified.emit(payload)

    def flush_pending_notifications(self):
        """
        手动刷新待处理的通知
        """
        with self._lock:
            if not self._pending_notifications:
                return
            pending = list(self._pending_notifications)
            self._pending_notifications.clear()
        
        for payload in pending:
            self.notified.emit(payload)

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
            with self._lock:
                if not self._qml_ready:
                    logger.debug(f"QML not ready, queuing notification: {data.title}")
                    self._pending_notifications.append(payload)
            
            if self._qml_ready:
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
