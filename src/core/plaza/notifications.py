from __future__ import annotations

from PySide6.QtCore import QCoreApplication, QObject

from src.core.notification import NotificationData, NotificationLevel, NotificationProvider, NotificationProviderConfig


class PlazaNotificationPublisher(QObject):
    """Publish Plugin Plaza events through a dedicated notification provider."""

    PROVIDER_ID = "com.classwidgets.plugin-plaza"

    def __init__(self, app_central, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._manager = app_central.notification
        self._provider: NotificationProvider | None = None
        self._register_provider()

    def retranslate(self) -> None:
        """Recreate the provider so its displayed name follows the app language."""
        self._manager.unregister_provider(self.PROVIDER_ID)
        if self._provider:
            self._provider.deleteLater()
        self._provider = None
        self._register_provider()

    def _register_provider(self) -> None:
        self._provider = NotificationProvider(
            id=self.PROVIDER_ID,
            name=QCoreApplication.translate("NotificationProviders", "Plugin Plaza"),
            icon="",
            use_system_notify=True,
            manager=self._manager,
        )
        self._provider.setParent(self)

        # Default to system notifications only; keep any user override.
        cfg = self._manager.configs.notifications.providers.get(self.PROVIDER_ID)
        if cfg is None:
            self._manager.configs.notifications.providers[self.PROVIDER_ID] = NotificationProviderConfig(
                use_system_notify=True,
                use_app_notify=False,
            )

    def transfer_succeeded(self, name: str, version: str, kind: str) -> None:
        action = QCoreApplication.translate(
            "PluginPlaza", "Updated" if kind == "update" else "Installed"
        )
        self._dispatch(
            NotificationLevel.INFO,
            QCoreApplication.translate("PluginPlaza", "Plugin Plaza"),
            QCoreApplication.translate("PluginPlaza", "{action} {name} (v{version}).").format(
                action=action,
                name=name,
                version=version,
            ),
        )

    def transfer_failed(self, name: str, error: str, kind: str) -> None:
        action = QCoreApplication.translate(
            "PluginPlaza", "update" if kind == "update" else "installation"
        )
        self._dispatch(
            NotificationLevel.WARNING,
            QCoreApplication.translate("PluginPlaza", "Plugin Plaza {action} failed").format(
                action=action,
            ),
            QCoreApplication.translate("PluginPlaza", "{name}: {error}").format(
                name=name,
                error=error,
            ),
        )

    def updates_available(self, count: int) -> None:
        self._dispatch(
            NotificationLevel.ANNOUNCEMENT,
            QCoreApplication.translate("PluginPlaza", "Plugin updates available"),
            QCoreApplication.translate(
                "PluginPlaza", "{count} plugin update(s) are ready in Plugin Plaza."
            ).format(count=count),
        )

    def _dispatch(self, level: NotificationLevel, title: str, message: str) -> None:
        self._manager.dispatch(NotificationData(
            provider_id=self.PROVIDER_ID,
            level=level,
            title=title,
            message=message,
            icon=self._provider.icon if self._provider else "ic_fluent_apps_20_regular",
            duration=6000,
            closable=True,
        ))
