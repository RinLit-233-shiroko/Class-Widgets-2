import shutil
import sys
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import Optional, TYPE_CHECKING

from PySide6.QtCore import Slot, QObject, Signal, Property, QUrl, QThread, QCoreApplication
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QApplication, QFileDialog
from loguru import logger

from src.core.directories import PLUGINS_PATH
from src.core.plugin import CW2Plugin, PluginAPI
from src.core.plugin.archive import PluginArchiveInstaller, PluginInstallResult
from src.core.plugin.errors import plugin_install_error_message
from src.core.plugin.loader import PluginLoader, check_api_version
from src.core.plugin.models import PluginMeta, PluginConflict
from src.core.plugin.worker import PluginImportWorker
from src.core.plugin.workers import (
    PlazaDownloadWorker,
    PlazaUpdateWorker,
    PluginInstallWorker,
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
        self._install_thread: QThread | None = None
        self._install_worker: QThread | None = None
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
        self.metas = self.loader.scan_plugins(self.external_path)
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
        if self._install_thread and self._install_thread.isRunning():
            self._install_thread.quit()
            self._install_thread.wait(500)
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
        return bool(
            (self._download_thread and self._download_thread.isRunning())
            or (self._install_thread and self._install_thread.isRunning())
        )

    def _install_is_active_or_paused(self) -> bool:
        return self._install_status in {"Downloading", "Paused", "Installing"}

    def _plugin_meta(self, plugin_id: str) -> PluginMeta | None:
        return next((meta for meta in self.metas if meta.get("id") == plugin_id), None)

    def _unload_plugin_for_replacement(self, plugin_id: str) -> None:
        plugin = self._plugins.pop(plugin_id, None)
        if plugin:
            try:
                plugin.on_unload()
            except Exception as error:
                logger.warning(f"Failed to unload plugin {plugin_id} before replacement: {error}")
        sys.modules.pop(f"cw_plugin_{plugin_id}", None)

    def _complete_install(
        self,
        result: PluginInstallResult,
        *,
        track_plaza: bool = False,
    ) -> None:
        if result.replaced:
            self._unload_plugin_for_replacement(result.plugin_id)
        self._plaza_update_state.pop(result.plugin_id, None)
        self.pluginUpdateStatesChanged.emit()
        self.scan()
        self.pluginListChanged.emit()
        if track_plaza:
            self.plazaPluginsChanged.emit()
            meta = self._plugin_meta(result.plugin_id)
            name = str(meta.get("name", result.plugin_id)) if meta else result.plugin_id
            self._plaza_activity.complete(result.plugin_id, result.version)
            self._plaza_notifications.transfer_succeeded(
                name,
                result.version,
                self._install_kind,
            )
            self.plazaTransferSucceeded.emit(
                result.plugin_id,
                result.version,
                self._install_kind,
            )
        self._install_progress = 100.0
        self.pluginInstallProgressChanged.emit(100.0)
        self._set_install_status("Installed")
        self.pluginInstallSucceeded.emit(result.plugin_id, result.version)
        self._install_tracks_plaza = False
        self._install_kind = ""
        self._remove_download_directory()
        self.check_plaza_updates(background=False)

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

    def _start_install_worker(
        self,
        archive_path: Path,
        *,
        expected_plugin_id: str | None = None,
        expected_version: str | None = None,
        track_plaza: bool = False,
    ) -> bool:
        self._set_install_status("Installing")
        if track_plaza:
            self._plaza_activity.set_installing(self._install_plugin_id)
        self._install_worker = PluginInstallWorker(
            archive_path,
            self.archive_installer,
            expected_plugin_id=expected_plugin_id,
            expected_version=expected_version,
        )
        self._install_thread = self._install_worker
        self._install_worker.completed.connect(
            lambda result: self._complete_install(result, track_plaza=track_plaza)
        )
        self._install_worker.failed.connect(self._fail_install)
        self._install_worker.finished.connect(self._on_install_thread_finished)
        self._install_worker.start()
        return True

    def _on_install_thread_finished(self) -> None:
        thread = self._install_thread
        self._install_thread = None
        self._install_worker = None
        if thread:
            thread.deleteLater()
        self._remove_download_directory()
        self._emit_install_settled_if_idle()

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
        self._start_install_worker(
            Path(archive_path),
            expected_plugin_id=self._install_plugin_id,
            expected_version=plugin.get("version"),
            track_plaza=self._install_tracks_plaza,
        )

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
        if not base_url or self._install_is_active_or_paused():
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
            # 终止插件运行
            if pid in self._plugins:
                try:
                    self._plugins[pid].on_unload()
                except Exception as e:
                    logger.error(f"Error while unloading plugin {pid}: {e}")
                self._plugins.pop(pid, None)

            # 尝试清理模块
            mod_name = f"cw_plugin_{pid}"
            if mod_name in sys.modules:
                try:
                    del sys.modules[mod_name]
                except Exception:
                    pass

            # 删除插件目录
            plugin_dir = Path(meta["_path"])
            if plugin_dir.exists():
                shutil.rmtree(plugin_dir)
                logger.info(f"Uninstalled plugin {pid}, removed {plugin_dir}")

            # 移除 enabled
            self.enabled_plugins.discard(pid)
            self.app_central.configs.plugins.enabled = list(self.enabled_plugins)
            if self._plaza_update_state.pop(pid, None) is not None:
                self.pluginUpdateStatesChanged.emit()

            # 重新扫描插件列表
            self.scan()
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

    def _finish_import(self, result: PluginInstallResult) -> None:
        if result.replaced:
            self._unload_plugin_for_replacement(result.plugin_id)
        self._plaza_update_state.pop(result.plugin_id, None)
        self.pluginUpdateStatesChanged.emit()
        self.scan()
        self.pluginListChanged.emit()
        self._install_progress = 100.0
        self.pluginInstallProgressChanged.emit(100.0)
        self._set_install_status("Installed")
        self.pluginImportSucceeded.emit()

    @Slot(str, result="QVariant")
    def checkPluginConflicts(self, zip_path: str) -> list[PluginConflict]:
        return self._safe_conflicts(zip_path)

    @Slot(str, result=bool)
    def importPluginWithPath(self, zip_path: str) -> bool:
        if not zip_path or self._install_task_in_progress():
            return False
        worker = PluginImportWorker(zip_path, self.external_path)
        self._install_worker = worker  # type: ignore[assignment]
        self._install_thread = worker
        self._install_tracks_plaza = False
        self._install_kind = ""
        self._install_error = ""
        self._set_install_status("Installing")
        worker.completed.connect(self._finish_import)
        worker.error.connect(self._on_import_error)
        worker.finished.connect(self._on_install_thread_finished)
        worker.start()
        return True

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
        if not plugin_id or self._install_is_active_or_paused():
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
