import json
import shutil
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import List, Dict

from PySide6.QtCore import Slot, QObject, Signal, Property, QUrl, QThread, QCoreApplication
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QApplication, QFileDialog
from loguru import logger

from src.core.directories import PLUGINS_PATH
from src.core.plugin import CW2Plugin, PluginAPI
from src.core.plugin.loader import PluginLoader, check_api_version
from src.core.plugin.worker import PluginImportWorker
from src.core.plugin.api import __version__ as __API_VERSION__
from src.core.notification import NotificationData, NotificationLevel


class PluginManager(QObject):
    initialized = Signal()
    pluginListChanged = Signal()
    pluginImportSucceeded = Signal()
    pluginImportFailed = Signal(str)

    def __init__(self, plugin_api: PluginAPI, app_central):
        """
        :param plugin_api: 由 AppCentral 创建的 PluginAPI 实例
        :param app_central: AppCentral
        """
        super().__init__()
        self.api = plugin_api
        self.app_central = app_central

        # 存放 plugin_id -> plugin instance
        self._plugins: Dict[str, CW2Plugin] = {}
        self.metas: List[dict] = []  # 所有找到的插件 meta
        self.enabled_plugins = set(getattr(self.app_central.configs.plugins, "enabled", []))

        self.external_path = PLUGINS_PATH

        # 创建 PluginLoader 实例
        self.loader = PluginLoader(plugin_api, self.external_path)

        # 连接到 retranslate 信号
        app_central.retranslate.connect(self._on_retranslate)
        
        # 扫描并初始化（延迟到翻译器加载之后）
        # self.scan()
        logger.info("Plugin Manager initialized.")
        self.initialized.emit()

    # ---------------- discover / scan ----------------
    def scan(self):
        """扫描外部插件 + 加载内置插件 meta"""
        # 使用 PluginLoader 扫描插件
        self.metas = self.loader.scan_plugins(self.external_path)
        
        # 修复图标路径（使用 QUrl）
        for meta in self.metas:
            if meta.get("icon"):
                meta["icon"] = QUrl.fromLocalFile(str(Path(meta["_path"]) / meta["icon"]))
            # 动态翻译内置插件的名称
            if meta.get("_type") == "builtin":
                meta["name"] = QCoreApplication.translate("Plugins", meta["name"])

        # 检查不兼容插件并发送通知
        self._check_incompatible_plugins()
        
        logger.info(f"Found {len(self.metas)} plugins (builtin + external).")

    def _check_incompatible_plugins(self):
        """检查不兼容插件并发送通知"""
        incompatible_plugins = [
            meta for meta in self.metas 
            if not meta.get("_compatible", True)  # 默认为True，如果标记为False则不兼容
        ]
        
        if incompatible_plugins:
            plugin_count = len(incompatible_plugins)
            plugin_names = [meta["name"] for meta in incompatible_plugins]
            
            # 发送通知
            notification = NotificationData(
                provider_id="com.classwidgets.plugins",
                level=NotificationLevel.WARNING,
                title=QApplication.translate("PluginManager", "Incompatible"),
                message=QApplication.translate("PluginManager", "{count} incompatible plugin(s) have been loaded, which may cause unknown issues.").format(count=plugin_count),
                duration=10000,
                closable=True,
                silent=True
            )
            
            # 使用app_central的notification发送通知
            self.app_central.notification.dispatch(notification)
            
            logger.warning(
                f"Found {plugin_count} incompatible plugins: {', '.join(plugin_names)}. "
                f"Please check plugin settings for details."
            )

    # runtime SDK 注入
    # 该功能已移至 PluginLoader 中
    
    @contextmanager
    def plugin_import_context(self, plugin_dir: Path):
        """
        上下文：在加载插件期间，临时把 plugin_dir 与 plugin_dir/libs 放到 sys.path 最前面，
        其它 sys.path 项会在 finally 中恢复。切记不要清空 sys.path（可能导致 stdlib 丢失）。
        """
        # 使用 PluginLoader 的 plugin_import_context
        with self.loader.plugin_import_context(plugin_dir):
            yield
    
    # 加载启用插件
    def load_plugins(self):
        """加载已启用的插件实例（批量）"""
        self._plugins = self.loader.load_plugins(self.metas, list(self.enabled_plugins))

    def _on_retranslate(self):
        """翻译变更时重新扫描插件以更新翻译"""
        logger.info("Retranslating plugins...")
        self.scan()
        self.pluginListChanged.emit()
        
        # 重新注册已加载插件的 widgets 以更新翻译
        for plugin_id, plugin in self._plugins.items():
            if hasattr(plugin, 'register_widgets'):
                try:
                    plugin.register_widgets()
                    logger.debug(f"Re-registered widgets for plugin {plugin_id}")
                except Exception as e:
                    logger.warning(f"Failed to re-register widgets for plugin {plugin_id}: {e}")

    def _initialized_plugin(self, meta: dict):
        """
        负责单个插件的加载、实例化与 on_load() 调用
        """
        # 直接使用 PluginLoader 加载单个插件
        return self.loader.load_plugin(meta)

    # ---------------- 管理 / 卸载 ----------------
    def set_enabled_plugins(self, enabled_plugins: List[str]):
        if not enabled_plugins:
            return
        self.enabled_plugins = set(enabled_plugins)

    def cleanup(self):
        """卸载全部插件（用于退出时）"""
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

    @Slot(result='QVariant')
    def importPlugin(self) -> List[dict]:
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
        conflicts = self.get_conflicting_plugins(zip_path)
        
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

    def get_conflicting_plugins(self, zip_path: str) -> List[dict]:
        """检测ZIP文件中是否有与已安装插件冲突的插件"""
        import zipfile
        import json
        
        logger.debug(f"Analyzing zip file: {zip_path}")
        conflicting_plugins = []
        
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                members = zip_ref.namelist()
                logger.debug(f"Found {len(members)} files in zip")
                
                plugin_json_files = [m for m in members if m.endswith('cwplugin.json')]
                logger.debug(f"Found {len(plugin_json_files)} plugin.json files: {plugin_json_files}")
                
                for member in plugin_json_files:
                    try:
                        # 读取ZIP内的插件meta
                        meta_content = zip_ref.read(member).decode('utf-8')
                        plugin_meta = json.loads(meta_content)
                        
                        plugin_id = plugin_meta.get("id")
                        logger.debug(f"Found plugin ID: {plugin_id} in {member}")
                        
                        if plugin_id:
                            # 检查是否已存在此插件ID
                            existing_plugin = next((m for m in self.metas if m["id"] == plugin_id), None)
                            if existing_plugin:
                                logger.warning(f"Plugin conflict detected: {plugin_id} (existing: {existing_plugin.get('version', 'unknown')}, new: {plugin_meta.get('version', 'unknown')})")
                                conflicting_plugins.append({
                                    "id": plugin_id,
                                    "name": plugin_meta.get("name", plugin_id),
                                    "version": plugin_meta.get("version", "unknown"),
                                    "existing_version": existing_plugin.get("version", "unknown"),
                                    "meta": plugin_meta
                                })
                            else:
                                logger.debug(f"No conflict found for plugin: {plugin_id}")
                    except Exception as e:
                        logger.warning(f"Failed to read plugin meta from {member}: {e}")
                        continue
        except Exception as e:
            logger.error(f"Failed to analyze zip file {zip_path}: {e}")
            
        return conflicting_plugins

    @Slot(str, result='QVariant')
    def checkPluginConflicts(self, zip_path: str) -> List[dict]:
        """QML接口：检测ZIP文件中是否有与已安装插件冲突的插件"""
        return self.get_conflicting_plugins(zip_path)

    @Slot(str, result=bool)
    def importPluginWithPath(self, zip_path: str) -> bool:
        """通过指定路径导入插件（带冲突检测）"""
        if not zip_path:
            return False

        self.thread = QThread()
        self.worker = PluginImportWorker(zip_path, self.external_path, self.scan, self.metas)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)

        def on_finished(result):
            if result and len(result) > 0:
                data = result[0]
                new_plugins = data.get("new_plugins", [])
                updated_plugins = data.get("updated_plugins", [])
                
                if new_plugins or updated_plugins:
                    if updated_plugins:
                        logger.info(f"Updated plugin(s): {', '.join(updated_plugins)}")
                    if new_plugins:
                        logger.info(f"Imported new plugin(s): {', '.join(new_plugins)}")
                    
                    self.pluginListChanged.emit()
                    self.pluginImportSucceeded.emit()
                else:
                    logger.warning(f"No plugins were imported from: {zip_path}")
                    self.pluginImportFailed.emit("No valid plugin found in archive.")
            else:
                logger.warning(f"Plugin import failed: {zip_path}")
                self.pluginImportFailed.emit("No valid plugin found in archive.")
            self.thread.quit()
            self.worker.deleteLater()
            self.thread.deleteLater()

        def on_error(msg):
            logger.error(f"Plugin import error: {msg}")
            self.pluginImportFailed.emit(msg)
            self.thread.quit()
            self.worker.deleteLater()
            self.thread.deleteLater()

        self.worker.finished.connect(on_finished)
        self.worker.error.connect(on_error)

        self.thread.start()
        return True

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

            # 重新扫描插件列表
            self.scan()
            self.pluginListChanged.emit()
            return True
        except Exception as e:
            logger.exception(f"Failed to uninstall plugin {pid}: {e}")
            return False
