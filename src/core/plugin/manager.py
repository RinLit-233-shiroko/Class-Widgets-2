import shutil
import sys
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import Optional, TYPE_CHECKING

from PySide6.QtCore import Slot, QObject, Signal, Property, QUrl, QCoreApplication
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QApplication, QFileDialog
from loguru import logger

from src.core.storage.directories import PLUGIN_CACHE_PATH, PLUGINS_PATH
from src.core.plugin import CW2Plugin, PluginAPI
from src.core.plugin.archive import PluginArchiveInstaller
from src.core.plugin.errors import plugin_install_error_message
from src.core.plugin.loader import PluginLoader, check_api_version
from src.core.plugin.models import PluginMeta, PluginConflict
from src.core.plugin.workers import (
    PlazaDownloadWorker,
    PlazaUpdateWorker,
    create_plugin_download_directory,
    remove_plugin_download_directory,
)
from src.core.plaza.activity import PlazaActivityStore
from src.core.plaza.notifications import PlazaNotificationPublisher
from src.core.plugin.api import __version__ as __API_VERSION__
from src.core.notification import NotificationData, NotificationLevel

if TYPE_CHECKING:
    from src.core.central import AppCentral


class PluginManager(QObject):
    initialized = Signal()
    pluginListChanged = Signal()
    pluginImportSucceeded = Signal()
    pluginImportFailed = Signal(str)
    pluginInstallStatusChanged = Signal(str)
    pluginInstallProgressChanged = Signal(float)
    pluginInstallSucceeded = Signal(str, str)
    pluginInstallFailed = Signal(str)
    plazaPluginsChanged = Signal()
    plazaUpdatesCheckingChanged = Signal()
    pluginUpdateStatesChanged = Signal()
    plazaActivityChanged = Signal()
    showPlazaDownloadsRequested = Signal()
    plazaUpdateCheckCompleted = Signal(bool, object)
    pluginInstallCancelled = Signal(str)
    pluginInstallSettled = Signal()
    pluginPendingOperationsChanged = Signal()
    plazaTransferSucceeded = Signal(str, str, str)
    plazaTransferFailed = Signal(str, str, str)
    plazaTransferCancelled = Signal(str)

    def __init__(self, plugin_api: PluginAPI, app_central: "AppCentral"):
        """
        :param plugin_api: 由 AppCentral 创建的 PluginAPI 实例
        :param app_central: AppCentral
        """
        super().__init__()
        self.api: PluginAPI = plugin_api
        self.app_central: "AppCentral" = app_central

        # 存放 plugin_id -> plugin instance
        self._plugins: dict[str, CW2Plugin] = {}
        self.metas: list[PluginMeta] = []  # 所有找到的插件 meta
        self.enabled_plugins: set[str] = set(getattr(self.app_central.configs.plugins, "enabled", []))

        self.external_path: Path = PLUGINS_PATH
        self.archive_installer = PluginArchiveInstaller(self.external_path)
        self._download_thread: PlazaDownloadWorker | None = None
        self._download_dir: Path | None = None
        self._download_cleanup_pending = False
        self._resume_download_pending = False
        self._install_plugin_id = ""
        self._install_tracks_plaza = False
        self._install_status = "Idle"
        self._install_progress = 0.0
        self._install_downloaded_bytes = 0
        self._install_total_bytes = 0
        self._install_speed = 0.0
        self._install_error = ""
        self._plaza_update_thread: PlazaUpdateWorker | None = None
        self._plaza_update_state: dict[str, dict[str, object]] = {}
        self._plaza_updates_checking = False
        self._plaza_check_background = False
        self._last_notified_plaza_update_ids: set[str] = set()
        self._install_kind = ""
        self._plaza_activity = PlazaActivityStore(parent=self)
        self._plaza_activity.changed.connect(self.plazaActivityChanged)
        self._plaza_notifications = PlazaNotificationPublisher(app_central, parent=self)

        self.loader: PluginLoader = PluginLoader(plugin_api, self.external_path)
        app_central.retranslate.connect(self._on_retranslate)
        logger.info("Plugin Manager initialized.")
        self.initialized.emit()

    # ---------------- discover / scan ----------------
    def scan(self) -> None:
        # 安全模式只加载内置插件，绝不触碰外部插件目录。
        include_external = not self.app_central.safeMode
        self.metas = self.loader.scan_plugins(
            self.external_path, include_external=include_external
        )
        for meta in self.metas:
            if meta.get("icon") and meta.get("_path"):
                meta["icon"] = QUrl.fromLocalFile(str(Path(meta["_path"]) / meta["icon"]))
            if meta.get("_type") == "builtin":
                meta["name"] = QCoreApplication.translate("Plugins", meta["name"])
        self._check_incompatible_plugins()
        self.plazaPluginsChanged.emit()
        logger.info(f"Found {len(self.metas)} plugins (builtin + external).")

    def _check_incompatible_plugins(self) -> None:
        incompatible_plugins = [
            meta for meta in self.metas if not meta.get("_compatible", True)
        ]
        if not incompatible_plugins:
            return
        notification = NotificationData(
            provider_id="com.classwidgets.plugins",
            level=NotificationLevel.WARNING,
            title=QApplication.translate("PluginManager", "Incompatible"),
            message=QApplication.translate(
                "PluginManager",
                "{count} incompatible plugin(s) have been loaded, which may cause unknown issues.",
            ).format(count=len(incompatible_plugins)),
            duration=10000,
            closable=True,
            silent=True,
        )
        self.app_central.notification.dispatch(notification)

    @contextmanager
    def plugin_import_context(self, plugin_dir: Path):
        with self.loader.plugin_import_context(plugin_dir):
            yield

    def load_plugins(self) -> None:
        self._plugins = self.loader.load_plugins(self.metas, list(self.enabled_plugins))
        self._report_plugin_load_failures()
        self.pluginListChanged.emit()

    @Property("QVariant", notify=pluginListChanged)
    def pluginLoadFailures(self) -> list[dict]:
        """扫描/加载失败的插件，供 UI 与崩溃归因查看。"""
        return [
            {
                "id": failure.plugin_id,
                "name": failure.display_name,
                "stage": failure.stage,
                "error": failure.error,
            }
            for failure in self.loader.failures
        ]

    def _report_plugin_load_failures(self) -> None:
        """把“插件加载失败”从日志里捞到用户面前。

        以前加载失败的插件只会写一行 exception 日志然后悄悄消失，用户既不知道
        少了什么，也无从排查。
        """
        failures = self.loader.failures
        if not failures:
            return

        names = ", ".join(failure.display_name for failure in failures)
        logger.error(
            "{} plugin(s) failed to load and were skipped: {}", len(failures), names
        )
        try:
            self.app_central.notification.dispatch(
                NotificationData(
                    provider_id="com.classwidgets.plugins",
                    level=NotificationLevel.WARNING,
                    title=QApplication.translate(
                        "PluginManager", "Some plugins failed to load"
                    ),
                    message=QApplication.translate(
                        "PluginManager",
                        "{count} plugin(s) could not be loaded and were skipped: {names}",
                    ).format(count=len(failures), names=names),
                    duration=10000,
                    closable=True,
                    silent=True,
                )
            )
        except Exception:
            logger.exception("Failed to report plugin load failures")

    def _on_retranslate(self) -> None:
        logger.info("Retranslating plugins...")
        self._plaza_notifications.retranslate()
        self.scan()
        self.pluginListChanged.emit()
        for plugin_id, plugin in self._plugins.items():
            if hasattr(plugin, "register_widgets"):
                try:
                    plugin.register_widgets()
                except Exception as error:
                    logger.warning(f"Failed to re-register widgets for plugin {plugin_id}: {error}")

    def _initialized_plugin(self, meta: PluginMeta) -> Optional[CW2Plugin]:
        return self.loader.load_plugin(meta)

    # ---------------- management / unload ----------------
    def set_enabled_plugins(self, enabled_plugins: list[str]) -> None:
        self.enabled_plugins = set(enabled_plugins)

    def cleanup(self) -> None:
        """Unload plugins and stop active installation work."""
        download_thread = self._download_thread
        if download_thread and download_thread.isRunning():
            download_thread.cancel()
            download_thread.wait(500)
        if not download_thread or not download_thread.isRunning():
            remove_plugin_download_directory(self._download_dir)
            self._download_dir = None
            self._download_cleanup_pending = False
        if self._plaza_update_thread and self._plaza_update_thread.isRunning():
            self._plaza_update_thread.cancel()
            self._plaza_update_thread.wait(500)
        for pid, plugin in list(self._plugins.items()):
            try:
                plugin.on_unload()
            except Exception as e:
                logger.error(f"Failed to unload plugin {pid}: {e}")
            self.api.ui.unregister_plugin_shortcuts(pid)
            # 尝试从 sys.modules 移除对应模块（使用标准模块前缀 cw_plugin_{id}）
            mod_name = f"cw_plugin_{pid}"
            if mod_name in sys.modules:
                try:
                    del sys.modules[mod_name]
                except Exception:
                    pass
        self._plugins.clear()

    def _set_install_status(self, status: str) -> None:
        if self._install_status != status:
            self._install_status = status
            self.pluginInstallStatusChanged.emit(status)

    def _install_task_in_progress(self) -> bool:
        return bool(self._download_thread and self._download_thread.isRunning())

    def _install_is_active_or_paused(self) -> bool:
        return self._install_status in {"Downloading", "Paused", "Installing"} or self._install_task_in_progress()

    @staticmethod
    def _operation_plugin_id(operation: dict) -> str:
        return str(operation.get("plugin_id", "")).strip()

    def _pending_operations(self) -> list[dict]:
        operations = getattr(self.app_central.configs.plugins, "pending_operations", [])
        return [item for item in operations if isinstance(item, dict)]

    def _has_pending_operation(self, plugin_id: str) -> bool:
        return any(self._operation_plugin_id(item) == plugin_id for item in self._pending_operations())

    def _save_pending_operations(self, operations: list[dict]) -> None:
        self.app_central.configs.plugins.pending_operations = operations
        self.app_central.configs.save(silent=True)
        self.pluginPendingOperationsChanged.emit()

    def _queue_pending_operation(self, operation: dict) -> None:
        """Keep only the newest deferred operation for each plugin ID."""
        plugin_id = self._operation_plugin_id(operation)
        operations = []
        for item in self._pending_operations():
            if self._operation_plugin_id(item) != plugin_id:
                operations.append(item)
                continue
            old_archive = item.get("archive_path")
            if (
                old_archive
                and item.get("type") == "install"
                and Path(str(old_archive)) != Path(str(operation.get("archive_path", "")))
            ):
                Path(str(old_archive)).unlink(missing_ok=True)
        operations.append(operation)
        self._save_pending_operations(operations)

    def _cache_archive(self, archive_path: Path, plugin_id: str) -> Path:
        if not archive_path.is_file():
            raise ValueError(f"Plugin archive does not exist: {archive_path}")
        PLUGIN_CACHE_PATH.mkdir(parents=True, exist_ok=True)
        destination = PLUGIN_CACHE_PATH / f"{plugin_id}-{archive_path.name}"
        shutil.copy2(archive_path, destination)
        return destination

    def _queue_install(
        self,
        archive_path: Path,
        *,
        plugin_id: str,
        version: str | None = None,
        enable_after_install: bool = False,
    ) -> bool:
        try:
            archive = self._cache_archive(archive_path, plugin_id)
            info = self.archive_installer.inspect(archive)
            if info.plugin_id != plugin_id:
                raise ValueError(f"Archive contains '{info.plugin_id}', expected '{plugin_id}'.")
            if version and info.version != version:
                raise ValueError(f"Archive version '{info.version}' does not match '{version}'.")
            self._queue_pending_operation({
                "type": "install",
                "plugin_id": info.plugin_id,
                "archive_path": str(archive),
                "version": info.version,
                "enable_after_install": enable_after_install,
            })
            self.app_central.markRestartRequired()
            return True
        except Exception as error:
            archive = locals().get("archive")
            if isinstance(archive, Path):
                archive.unlink(missing_ok=True)
            self._fail_install(str(error))
            return False

    def _queue_uninstall(self, plugin_id: str) -> bool:
        self._queue_pending_operation({"type": "uninstall", "plugin_id": plugin_id})
        self.app_central.markRestartRequired()
        return True

    @Property("QVariant", notify=pluginPendingOperationsChanged)
    def pendingPluginOperations(self) -> list[dict]:
        return self._pending_operations()

    def apply_pending_operations(self) -> None:
        """Apply deferred file changes before external plugins are scanned."""
        operations = self._pending_operations()
        if not operations:
            return
        remaining: list[dict] = []
        for operation in operations:
            plugin_id = self._operation_plugin_id(operation)
            try:
                operation_type = operation.get("type")
                if not plugin_id or operation_type not in {"install", "uninstall"}:
                    raise ValueError("Invalid pending plugin operation.")
                if operation_type == "install":
                    self.archive_installer.install(
                        str(operation.get("archive_path", "")),
                        expected_plugin_id=plugin_id,
                        expected_version=str(operation.get("version", "")) or None,
                        replace=True,
                    )
                    archive_path = Path(str(operation.get("archive_path", "")))
                    archive_path.unlink(missing_ok=True)
                    if archive_path.parent == PLUGIN_CACHE_PATH:
                        try:
                            archive_path.parent.rmdir()
                        except OSError:
                            pass
                    if operation.get("enable_after_install", False):
                        self.enabled_plugins.add(plugin_id)
                else:
                    target = self.external_path / plugin_id
                    if target.exists():
                        shutil.rmtree(target)
                    self.enabled_plugins.discard(plugin_id)
                logger.info(f"Applied pending plugin {operation_type}: {plugin_id}")
            except Exception as error:
                logger.exception(f"Failed to apply pending plugin operation for {plugin_id}: {error}")
                remaining.append(operation)
                self._install_error = plugin_install_error_message(str(error))
        self.app_central.configs.plugins.enabled = list(self.enabled_plugins)
        self._save_pending_operations(remaining)
        if remaining:
            self._set_install_status("Error")

    def _plugin_meta(self, plugin_id: str) -> PluginMeta | None:
        return next((meta for meta in self.metas if meta.get("id") == plugin_id), None)

    def _fail_install(self, error: str) -> None:
        logger.error(f"Plugin installation failed: {error}")
        message = plugin_install_error_message(error)
        self._install_error = message
        if self._install_tracks_plaza:
            meta = self._plugin_meta(self._install_plugin_id)
            name = str(meta.get("name", self._install_plugin_id)) if meta else self._install_plugin_id
            self._plaza_activity.fail(self._install_plugin_id, message)
            self._plaza_notifications.transfer_failed(name, message, self._install_kind)
            self.plazaTransferFailed.emit(
                self._install_plugin_id,
                message,
                self._install_kind,
            )
        self._set_install_status("Error")
        self.pluginInstallFailed.emit(message)
        self._install_tracks_plaza = False
        self._install_kind = ""

    def _remove_download_directory(self) -> None:
        if self._download_thread and self._download_thread.isRunning():
            self._download_cleanup_pending = True
            return
        remove_plugin_download_directory(self._download_dir)
        self._download_dir = None
        self._download_cleanup_pending = False

    def _on_download_thread_finished(self) -> None:
        thread = self._download_thread
        self._download_thread = None
        if thread:
            thread.deleteLater()
        if self._resume_download_pending and self._install_status == "Paused":
            self._resume_download_pending = False
            self._start_plaza_download()
            return
        if self._download_cleanup_pending or self._install_status in {"Idle", "Error", "Installed", "Cancelled"}:
            self._remove_download_directory()
        self._emit_install_settled_if_idle()

    def _emit_install_settled_if_idle(self) -> None:
        if not self._install_task_in_progress() and self._install_status != "Paused":
            self.pluginInstallStatusChanged.emit(self._install_status)
            self.pluginInstallSettled.emit()

    def _on_download_progress(
        self,
        percent: float,
        speed: float,
        downloaded_bytes: int,
        total_bytes: int,
    ) -> None:
        self._install_progress = min(max(percent, 0.0), 100.0)
        self._install_speed = max(speed, 0.0)
        self._install_downloaded_bytes = max(downloaded_bytes, 0)
        self._install_total_bytes = max(total_bytes, 0)
        self.pluginInstallProgressChanged.emit(self._install_progress)
        if self._install_tracks_plaza:
            self._plaza_activity.set_progress(
                self._install_plugin_id,
                self._install_progress,
                self._install_downloaded_bytes,
                self._install_total_bytes,
                self._install_speed,
            )

    def _on_plaza_download_completed(self, archive_path: str, plugin: dict) -> None:
        plugin_id = self._install_plugin_id
        version = str(plugin.get("version", "")) or None
        if not self._queue_install(Path(archive_path), plugin_id=plugin_id, version=version):
            return
        self._install_progress = 100.0
        self.pluginInstallProgressChanged.emit(100.0)
        self._set_install_status("PendingRestart")
        if self._install_tracks_plaza:
            meta = self._plugin_meta(plugin_id)
            name = str(meta.get("name", plugin_id)) if meta else plugin_id
            self._plaza_activity.complete(plugin_id, version or "")
            self._plaza_notifications.transfer_succeeded(name, version or "", self._install_kind)
            self.plazaTransferSucceeded.emit(plugin_id, version or "", self._install_kind)
        self.pluginInstallSucceeded.emit(plugin_id, version or "")
        self._install_tracks_plaza = False
        self._install_kind = ""
        self._download_cleanup_pending = True

    def _on_plaza_plugin_resolved(self, plugin: dict) -> None:
        if not self._install_tracks_plaza or not isinstance(plugin, dict):
            return
        if str(plugin.get("id", "")) != self._install_plugin_id:
            return
        self._plaza_activity.update_metadata(
            self._install_plugin_id,
            name=str(plugin.get("name", "")),
            author=str(
                plugin.get("author")
                or plugin.get("owner_name")
                or plugin.get("owner_id")
                or ""
            ),
            icon=plugin.get("icon", ""),
            version=str(plugin.get("version", "")),
        )

    def _on_download_failed(self, message: str) -> None:
        self._fail_install(message)

    def _on_download_cancelled(self) -> None:
        self._resume_download_pending = False
        self._install_progress = 0.0
        self._install_downloaded_bytes = 0
        self._install_total_bytes = 0
        self._install_speed = 0.0
        self.pluginInstallProgressChanged.emit(0.0)
        if self._install_tracks_plaza:
            self._plaza_activity.cancel(self._install_plugin_id)
        self._set_install_status("Cancelled")
        self.pluginInstallCancelled.emit(self._install_plugin_id)
        if self._install_tracks_plaza:
            self.plazaTransferCancelled.emit(self._install_plugin_id)
        self._install_tracks_plaza = False
        self._install_kind = ""

    def _on_download_paused(self) -> None:
        self._install_speed = 0.0
        if self._install_tracks_plaza:
            self._plaza_activity.set_paused(self._install_plugin_id)
        self._set_install_status("Paused")

    @Property(str, notify=pluginInstallStatusChanged)
    def installStatus(self) -> str:
        return self._install_status

    @Property(float, notify=pluginInstallProgressChanged)
    def installProgress(self) -> float:
        return self._install_progress

    @Property(int, notify=pluginInstallProgressChanged)
    def installDownloadedBytes(self) -> int:
        return self._install_downloaded_bytes

    @Property(int, notify=pluginInstallProgressChanged)
    def installTotalBytes(self) -> int:
        return self._install_total_bytes

    @Property(float, notify=pluginInstallProgressChanged)
    def installSpeed(self) -> float:
        return self._install_speed

    @Property(str, notify=pluginInstallStatusChanged)
    def installError(self) -> str:
        return self._install_error

    @Property(str, notify=pluginInstallStatusChanged)
    def installPluginId(self) -> str:
        return self._install_plugin_id

    @Property("QVariant", notify=plazaPluginsChanged)
    def plazaPlugins(self) -> list[dict]:
        """Return installed external plugins that are available in the Plaza."""
        known_ids = {
            plugin_id
            for plugin_id, state in self._plaza_update_state.items()
            if state.get("available")
        }
        result = []
        for plugin_id in known_ids:
            meta = next((item for item in self.metas if item.get("id") == plugin_id), {})
            if not meta:
                continue
            plugin_dir = meta.get("_path")
            local_updated_at = ""
            if plugin_dir:
                try:
                    local_updated_at = datetime.fromtimestamp(
                        Path(plugin_dir).stat().st_mtime
                    ).strftime("%Y-%m-%d")
                except OSError:
                    pass
            item = {
                "id": plugin_id,
                "name": meta.get("name", plugin_id),
                "author": meta.get("author", ""),
                "version": meta.get("version", ""),
                "icon": meta.get("icon", ""),
                "local_updated_at": local_updated_at,
            }
            item.update(self._plaza_update_state.get(plugin_id, {}))
            result.append(item)
        return sorted(result, key=lambda item: item["name"].lower())

    @Property("QVariant", notify=plazaActivityChanged)
    def plazaActivity(self) -> list[dict[str, object]]:
        return self._plaza_activity.entries

    @Property("QVariant", notify=pluginUpdateStatesChanged)
    def pluginUpdateStates(self) -> dict[str, dict[str, object]]:
        """Return the latest Plaza update result for each installed plugin."""
        return self._plaza_update_state

    @Property(int, notify=pluginUpdateStatesChanged)
    def plazaUpdateCount(self) -> int:
        return sum(
            1
            for state in self._plaza_update_state.values()
            if state.get("update_available")
        )

    @Property(bool, notify=pluginInstallStatusChanged)
    def plazaInstallActive(self) -> bool:
        return self._install_is_active_or_paused()

    def _plaza_base_url(self) -> str:
        return str(
            getattr(self.app_central.configs.network, "plaza_url", "")
        ).strip().rstrip("/")

    def _plaza_update_records(self) -> list[dict[str, str]]:
        """Build update candidates from the installed external plugin manifests."""
        records = []
        for meta in self.metas:
            if meta.get("_type") != "external":
                continue
            plugin_id = str(meta.get("id", ""))
            installed_version = str(meta.get("version", ""))
            if plugin_id and installed_version:
                records.append({
                    "id": plugin_id,
                    "installed_version": installed_version,
                })
        return records

    @Property(bool, notify=plazaUpdatesCheckingChanged)
    def plazaUpdatesChecking(self) -> bool:
        return self._plaza_updates_checking

    def _set_plaza_updates_checking(self, checking: bool) -> None:
        if self._plaza_updates_checking == checking:
            return
        self._plaza_updates_checking = checking
        self.plazaUpdatesCheckingChanged.emit()

    def _on_plaza_updates_completed(self, results: list[dict]) -> None:
        self._plaza_update_state = {
            result["id"]: {
                "latest_version": result.get("latest_version", ""),
                "update_available": bool(result.get("update_available", False)),
                "update_error": result.get("update_error", ""),
                "available": bool(result.get("available", False)),
            }
            for result in results
            if result.get("id")
        }
        self.plazaPluginsChanged.emit()
        self.pluginUpdateStatesChanged.emit()
        available_ids = {
            plugin_id
            for plugin_id, state in self._plaza_update_state.items()
            if state.get("update_available")
        }
        if self._plaza_check_background:
            new_update_ids = available_ids - self._last_notified_plaza_update_ids
            if new_update_ids:
                self._plaza_notifications.updates_available(len(new_update_ids))
        self._last_notified_plaza_update_ids = available_ids
        self.plazaUpdateCheckCompleted.emit(self._plaza_check_background, results)

    def _on_plaza_updates_finished(self) -> None:
        thread = self._plaza_update_thread
        self._plaza_update_thread = None
        self._set_plaza_updates_checking(False)
        self._plaza_check_background = False
        if thread:
            thread.deleteLater()

    @Slot(result=bool)
    def checkPlazaUpdates(self) -> bool:
        """Check the configured plaza for updates to every external plugin."""
        return self.check_plaza_updates(background=False)

    def check_plaza_updates(self, *, background: bool = False) -> bool:
        """Check for Plugin Plaza updates, optionally without user-facing refresh state."""
        if self._plaza_updates_checking:
            return False

        base_url = self._plaza_base_url()
        records = self._plaza_update_records()
        self._plaza_check_background = background
        self._plaza_update_state = {}
        self.plazaPluginsChanged.emit()
        self.pluginUpdateStatesChanged.emit()
        if not base_url or not records:
            self._last_notified_plaza_update_ids = set()
            self.plazaUpdateCheckCompleted.emit(background, [])
            self._plaza_check_background = False
            return True

        self._set_plaza_updates_checking(True)
        worker = PlazaUpdateWorker(records, base_url)
        self._plaza_update_thread = worker
        worker.completed.connect(self._on_plaza_updates_completed)
        worker.finished.connect(self._on_plaza_updates_finished)
        worker.start()
        return True

    @Slot(str, result=bool)
    def installPlazaUpdate(self, plugin_id: str) -> bool:
        """Install an installed external plugin's latest plaza release."""
        meta = self._plugin_meta(plugin_id)
        if not meta or meta.get("_type") != "external":
            return False
        base_url = self._plaza_base_url()
        if not base_url or self._install_is_active_or_paused() or self._has_pending_operation(plugin_id):
            return False
        return self._start_plaza_install(plugin_id, kind="update")

    @Slot()
    def openPlazaDownloads(self) -> None:
        self.app_central.window_manager.open_plugin_plaza()
        self.showPlazaDownloadsRequested.emit()

    @Slot(result='QVariant')
    def importPlugin(self) -> list[PluginConflict]:
        """从 ZIP 导入插件（带冲突检测）
        
        返回值：
        - []: 用户取消或无冲突（无冲突时直接导入）
        - [冲突信息列表]: 有冲突需要确认
        """
        logger.info("Starting plugin import process...")
        
        zip_path, _ = QFileDialog.getOpenFileName(
            None, "Import Plugin", "", "Class Widgets Plugin (*.cwplugin);;Plugin ZIP (*.zip)"
        )
        if not zip_path:
            logger.info("Plugin import cancelled by user")
            return []

        logger.info(f"Selected plugin file: {zip_path}")
        logger.info("Checking for plugin conflicts...")

        # 检查是否有冲突
        conflicts = self._safe_conflicts(zip_path)
        
        if conflicts:
            logger.warning(f"Found {len(conflicts)} conflicting plugin(s): {[c['id'] for c in conflicts]}")
            # 有冲突，返回冲突信息供QML显示确认对话框
            for conflict in conflicts:
                conflict["zip_path"] = zip_path  # 添加zip路径供后续导入使用
            return conflicts
        else:
            logger.info("No conflicts found, proceeding with direct import")
            # 没有冲突，直接执行导入
            self.importPluginWithPath(zip_path)
            return []

    # ---------------- QML 接口 ----------------
    @Property('QVariant', notify=pluginListChanged)
    def plugins(self):
        """QML调用此函数获取插件列表"""
        return self.metas

    @Slot(str, result=bool)
    def isPluginEnabled(self, pid: str) -> bool:
        return pid in self.enabled_plugins

    @Slot(str, result=bool)
    def isPluginCompatible(self, pid: str) -> bool:
        meta = next((m for m in self.metas if m["id"] == pid), None)
        if not meta:
            return False
        return check_api_version(meta["api_version"])

    @Slot(result=str)
    def getAPIVersion(self) -> str:
        """获取当前 API 版本"""
        return __API_VERSION__

    @Slot(str, bool)
    def setPluginEnabled(self, pid: str, enabled: bool):
        if self.app_central.configs.isKeyLocked("plugins.enabled"):
            logger.warning("Attempt to modify locked config key: plugins.enabled. Blocked.")
            return
        if enabled:
            logger.info(f"Enabled plugin {pid}")
            self.enabled_plugins.add(pid)
        else:
            logger.info(f"Disabled plugin {pid}")
            self.enabled_plugins.discard(pid)
        self.app_central.configs.plugins.enabled = list(self.enabled_plugins)
        self.pluginListChanged.emit()
        self.app_central.markRestartRequired()

    @Slot(str, result=bool)
    def openPluginFolder(self, pid: str) -> bool:
        """
        打开指定插件的本地文件夹
        """
        meta = next((m for m in self.metas if m["id"] == pid), None)
        if not meta:
            logger.warning(f"Plugin {pid} not found, cannot open folder.")
            return False

        folder_path = meta.get("_path")
        if not folder_path or not Path(folder_path).exists():
            logger.warning(f"Plugin folder {folder_path} does not exist.")
            return False

        # 打开文件夹
        url = QUrl.fromLocalFile(str(folder_path))
        success = QDesktopServices.openUrl(url)
        if not success:
            logger.error(f"Failed to open plugin folder: {folder_path}")
        return success

    @Slot(str, result=bool)
    def uninstallPlugin(self, pid: str) -> bool:
        """
        卸载指定外部插件
        """
        if self.app_central.configs.isKeyLocked("plugins.enabled"):
            logger.warning("Attempt to modify locked config key: plugins.enabled. Blocked.")
            return False
        meta = next((m for m in self.metas if m["id"] == pid), None)
        if not meta:
            logger.warning(f"Plugin {pid} not found, cannot uninstall.")
            return False

        # 内置插件卸载不了
        if meta.get("_type") == "builtin":
            logger.warning(f"Plugin {pid} is builtin and cannot be uninstalled.")
            return False

        try:
            # Deletion is intentionally deferred; loaded Python/QML resources may hold files.
            self.enabled_plugins.discard(pid)
            self.app_central.configs.plugins.enabled = list(self.enabled_plugins)
            self._queue_uninstall(pid)
            if self._plaza_update_state.pop(pid, None) is not None:
                self.pluginUpdateStatesChanged.emit()
            self.pluginListChanged.emit()
            return True
        except Exception as e:
            logger.exception(f"Failed to uninstall plugin {pid}: {e}")
            return False

    # ---------------- safe installation overrides ----------------
    def _safe_conflicts(self, zip_path: str) -> list[PluginConflict]:
        try:
            archive_info = self.archive_installer.inspect(zip_path)
        except Exception as error:
            logger.error(f"Failed to inspect plugin archive {zip_path}: {error}")
            return []
        existing = next((meta for meta in self.metas if meta["id"] == archive_info.plugin_id), None)
        if not existing:
            return []
        return [{
            "id": archive_info.plugin_id,
            "name": archive_info.name,
            "version": archive_info.version,
            "existing_version": existing.get("version", "unknown"),
            "meta": archive_info.manifest,
        }]

    @Slot(str, result="QVariant")
    def checkPluginConflicts(self, zip_path: str) -> list[PluginConflict]:
        return self._safe_conflicts(zip_path)

    @Slot(str, result=bool)
    def importPluginWithPath(self, zip_path: str) -> bool:
        if not zip_path or self._install_task_in_progress():
            return False
        self._install_error = ""
        try:
            info = self.archive_installer.inspect(zip_path)
        except Exception as error:
            self._on_import_error(str(error))
            return False
        if self._has_pending_operation(info.plugin_id):
            self._on_import_error("A pending operation already exists for this plugin. Restart to apply it first.")
            return False
        queued = self._queue_install(Path(zip_path), plugin_id=info.plugin_id, version=info.version)
        if queued:
            self._set_install_status("PendingRestart")
            self.pluginImportSucceeded.emit()
        else:
            self.pluginImportFailed.emit(self._install_error)
        return queued

    def _on_import_error(self, message: str) -> None:
        self._fail_install(message)
        self.pluginImportFailed.emit(plugin_install_error_message(message))

    def _start_plaza_install(self, plugin_id: str, *, kind: str) -> bool:
        base_url = self._plaza_base_url()
        if not base_url:
            return False
        self._download_dir = create_plugin_download_directory()
        destination = self._download_dir / "plugin.cwplugin"
        self._install_plugin_id = plugin_id
        self._install_tracks_plaza = True
        self._install_kind = kind
        self._install_error = ""
        self._install_progress = 0.0
        self._install_downloaded_bytes = 0
        self._install_total_bytes = 0
        self._install_speed = 0.0
        self._resume_download_pending = False
        self.pluginInstallProgressChanged.emit(0.0)
        self._set_install_status("Downloading")
        meta = self._plugin_meta(plugin_id)
        self._plaza_activity.start(
            plugin_id=plugin_id,
            name=str(meta.get("name", plugin_id)) if meta else plugin_id,
            author=str(meta.get("author", "")) if meta else "",
            icon=meta.get("icon", "") if meta else "",
            version=str(meta.get("version", "")) if meta else "",
            kind=kind,
        )
        return self._start_plaza_download()

    def _start_plaza_download(self) -> bool:
        base_url = self._plaza_base_url()
        if not base_url or not self._download_dir or not self._install_plugin_id:
            return False
        worker = PlazaDownloadWorker(
            self._install_plugin_id,
            base_url,
            self._download_dir / "plugin.cwplugin",
        )
        self._download_thread = worker
        self._set_install_status("Downloading")
        if self._install_tracks_plaza:
            self._plaza_activity.set_downloading(self._install_plugin_id)
        worker.pluginResolved.connect(self._on_plaza_plugin_resolved)
        worker.progress.connect(self._on_download_progress)
        worker.completed.connect(self._on_plaza_download_completed)
        worker.failed.connect(self._on_download_failed)
        worker.cancelled.connect(self._on_download_cancelled)
        worker.paused.connect(self._on_download_paused)
        worker.finished.connect(self._on_download_thread_finished)
        worker.start()
        return True

    @Slot(str, result=bool)
    def installFromPlaza(self, plugin_id: str) -> bool:
        if not plugin_id or self._install_is_active_or_paused() or self._has_pending_operation(plugin_id):
            return False
        return self._start_plaza_install(plugin_id, kind="install")

    @Slot(result=bool)
    def pausePluginInstall(self) -> bool:
        if self._install_status != "Downloading":
            return False
        if self._download_thread and self._download_thread.isRunning():
            self._on_download_paused()
            self._download_thread.pause()
            return True
        return False

    @Slot(result=bool)
    def resumePluginInstall(self) -> bool:
        if self._install_status != "Paused":
            return False
        if self._download_thread:
            self._resume_download_pending = True
            return True
        return self._start_plaza_download()

    @Slot(result=bool)
    def cancelPluginInstall(self) -> bool:
        if self._download_thread and self._download_thread.isRunning():
            self._resume_download_pending = False
            self._download_thread.cancel()
            return True
        if self._install_status == "Paused":
            self._resume_download_pending = False
            self._on_download_cancelled()
            self._remove_download_directory()
            self._emit_install_settled_if_idle()
            return True
        return False
