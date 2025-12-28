import importlib
import importlib.util
import json
import shutil
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import List, Dict

from PySide6.QtCore import Slot, QObject, Signal, Property, QUrl, QThread
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QFileDialog
from loguru import logger
from packaging.specifiers import SpecifierSet
from packaging.version import Version

from src.core.directories import PLUGINS_PATH, BUILTIN_PLUGINS_PATH
from src.core.plugin import CW2Plugin, PluginAPI
from src.core.plugin.api import __version__ as __API_VERSION__
from src.core.plugin.worker import PluginImportWorker
from src.plugins import BUILTIN_PLUGINS

REQUIRED_FIELDS = ["id", "name", "version", "api_version", "entry", "author"]


def validate_meta(meta: dict, plugin_dir: Path) -> bool:
    """
    校验插件 meta 字段完整性
    """
    # 检查必填字段
    for field in REQUIRED_FIELDS:
        if field not in meta or not meta[field]:
            logger.warning(f"Plugin meta missing required field '{field}' in {plugin_dir}")
            return False
    return True


def check_api_version(plugin_api_version: str) -> bool:
    """
    检查插件声明的 API 版本是否兼容
    """
    if not plugin_api_version or plugin_api_version.strip() == "*":
        return True

    try:
        api_v = Version(__API_VERSION__)
        required_specs = SpecifierSet(plugin_api_version)
        return required_specs.contains(api_v)

    except Exception as e:
        logger.debug(
            f"Version check failed. Plugin requirement: {plugin_api_version}, "
            f"Host version: {__API_VERSION__}. Error: {e}"
        )
        return False


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
        self.builtin_path = BUILTIN_PLUGINS_PATH

        # 注入运行时 SDK（让插件 import class_widgets_sdk 拿到真实对象）
        self._inject_runtime_sdk()

        # 扫描并初始化
        self.scan()
        logger.info(f"Found {len(self.metas)} plugins.")
        logger.info("Plugin Manager initialized.")
        self.initialized.emit()

    # ---------------- discover / scan ----------------
    @staticmethod
    def discover_plugins_in_dir(base_dir: Path) -> List[Path]:
        found = []
        if base_dir.exists() and base_dir.is_dir():
            for plugin_dir in base_dir.iterdir():
                if plugin_dir.is_dir() and (plugin_dir / "cwplugin.json").exists():
                    found.append(plugin_dir)
        return found

    def scan(self):
        """扫描外部插件 + 加载内置插件 meta"""
        self.metas.clear()

        # 内置插件
        for item in BUILTIN_PLUGINS:
            meta = item["meta"].copy()
            meta["_type"] = "builtin"
            meta["_class"] = item["class"]
            meta["_path"] = None
            self.metas.append(meta)

        # 扫描外置插件目录
        for plugin_dir in self.discover_plugins_in_dir(self.external_path):
            self._load_meta(plugin_dir, "external")

        logger.info(f"Found {len(self.metas)} plugins (builtin + external).")

    def _load_meta(self, plugin_dir: Path, type: str = "external"):
        try:
            meta_path = plugin_dir / "cwplugin.json"
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            meta["_path"] = plugin_dir
            meta["_type"] = type

            if meta.get("icon"):
                meta["icon"] = QUrl.fromLocalFile(str(plugin_dir / meta["icon"]))

            if not validate_meta(meta, plugin_dir):
                logger.warning(f"Plugin meta invalid, skipped: {plugin_dir}")
                return

            self.metas.append(meta)
        except Exception as e:
            logger.exception(f"Failed to read plugin meta from {plugin_dir}: {e}")

    # runtime SDK 注入
    @staticmethod
    def _inject_runtime_sdk():
        import types

        module_name = "ClassWidgets.SDK"

        if module_name in sys.modules:
            logger.debug(f"{module_name} already injected into sys.modules.")
            return

        fake_mod = types.ModuleType(module_name)
        try:
            from src.core.plugin.api import PluginAPI as RealPluginAPI
            from src.core.plugin import CW2Plugin as RealCW2Plugin
            from src.core.config.model import ConfigBaseModel as RealConfigBaseModel

            # 通知相关类型
            from src.core.notification.provider import NotificationProvider as RealNotificationProvider
            from src.core.notification.model import NotificationLevel, NotificationData

            # 批量注入
            fake_mod.PluginAPI = RealPluginAPI
            fake_mod.CW2Plugin = RealCW2Plugin
            fake_mod.ConfigBaseModel = RealConfigBaseModel
            fake_mod.NotificationProvider = RealNotificationProvider
            fake_mod.NotificationLevel = NotificationLevel
            fake_mod.NotificationData = NotificationData

        except Exception as e:
            logger.exception(f"Failed to import runtime API classes for injection: {e}")
            return

        sys.modules[module_name] = fake_mod
        logger.debug(f"Injected {module_name} into sys.modules (runtime-backed).")

    @contextmanager
    def plugin_import_context(self, plugin_dir: Path):
        """
        上下文：在加载插件期间，临时把 plugin_dir 与 plugin_dir/libs 放到 sys.path 最前面，
        其它 sys.path 项会在 finally 中恢复。切记不要清空 sys.path（可能导致 stdlib 丢失）。
        """
        old_path = sys.path.copy()
        try:
            # 插件目录优先
            to_insert = [str(plugin_dir)]
            libs_dir = plugin_dir / "libs"
            if libs_dir.exists() and libs_dir.is_dir():
                to_insert.insert(0, str(libs_dir))
            for p in reversed(to_insert):
                if p in sys.path:
                    sys.path.remove(p)
                sys.path.insert(0, p)
            yield
        finally:
            # 恢复
            sys.path[:] = old_path

    # 加载启用插件
    def load_plugins(self):
        """加载已启用的插件实例（批量）"""
        for pid in self.enabled_plugins:
            meta = next((m for m in self.metas if m["id"] == pid), None)
            if meta:
                try:
                    logger.info(f"Loading plugin {meta['name']} ({meta['id']}) v{meta['version']}")
                    self._initialized_plugin(meta)
                except Exception as e:
                    logger.exception(f"Failed to initialize plugin {meta['id']}: {e}")
            else:
                logger.warning(f"Enabled plugin {pid} not found in metas")

    def _initialized_plugin(self, meta: dict):
        """
        负责单个插件的加载、实例化与 on_load() 调用
        """
        if meta["_type"] == "builtin":
            return self._load_builtin_plugin(meta)
        else:
            return self._load_external_plugin(meta)

    def _load_builtin_plugin(self, meta: dict):
        plugin_id = meta["id"]

        try:
            if not check_api_version(meta["api_version"]):
                logger.error(
                    f"Builtin-Plugin {plugin_id} (api_version {meta.get('api_version')}) "
                    f"is not compatible with app version {self.app_central.configs.app.version}"
                )

            PluginClass = meta["_class"]
            plugin_instance = PluginClass(self.api)

            # 注入 PATH 与 meta
            plugin_instance.PATH = meta["_path"]
            plugin_instance.meta = meta

            from src.core.plugin import CW2Plugin as RealCW2Plugin
            if not isinstance(plugin_instance, RealCW2Plugin):
                raise TypeError("Builtin plugin must inherit from CW2Plugin")

            plugin_instance.on_load()
            self._plugins[plugin_id] = plugin_instance

            logger.success(f"Loaded builtin plugin {meta['name']} ({plugin_id}) v{meta['version']}")
            return plugin_instance

        except Exception as e:
            logger.exception(f"Failed to load builtin plugin {plugin_id}: {e}")
            return None

    def _load_external_plugin(self, meta: dict):
        plugin_dir: Path = meta["_path"]
        plugin_id = meta["id"]
        module_name = f"cw_plugin_{plugin_id}"

        def cleanup():
            if module_name in sys.modules:
                try:
                    del sys.modules[module_name]
                except Exception:
                    pass

        try:
            if not check_api_version(meta["api_version"]):
                raise RuntimeError(
                    f"Plugin {plugin_id} (api_version {meta.get('api_version')}) "
                    f"is not compatible with app version {self.app_central.configs.app.version}"
                )

            entry_file = plugin_dir / meta["entry"]
            if not entry_file.exists():
                raise FileNotFoundError(f"Entry file not found: {entry_file}")

            cleanup()

            with self.plugin_import_context(plugin_dir):
                spec = importlib.util.spec_from_file_location(module_name, str(entry_file))
                if not spec or not spec.loader:
                    raise RuntimeError("Invalid plugin entry (spec loader not found)")

                module = importlib.util.module_from_spec(spec)
                sys.modules[module_name] = module

                try:
                    spec.loader.exec_module(module)
                except Exception as e:
                    logger.exception(f"Plugin {plugin_id} failed to exec module: {e}")
                    cleanup()
                    raise

                if not hasattr(module, "Plugin"):
                    cleanup()
                    raise AttributeError("Plugin entry file does not define a 'Plugin' class")

                PluginClass = getattr(module, "Plugin")

                try:
                    plugin_instance = PluginClass(self.api)
                except Exception as e:
                    logger.exception(f"Failed to instantiate plugin {plugin_id}: {e}")
                    cleanup()
                    raise

                # 注入 PATH/meta
                plugin_instance.PATH = plugin_dir
                plugin_instance.meta = meta

                from src.core.plugin import CW2Plugin as RealCW2Plugin
                if not isinstance(plugin_instance, RealCW2Plugin):
                    cleanup()
                    raise TypeError("Plugin class must inherit from CW2Plugin (runtime class)")

                try:
                    plugin_instance.on_load()
                except Exception as e:
                    logger.exception(f"Plugin {plugin_id} on_load raised: {e}")
                    try:
                        plugin_instance.on_unload()
                    except Exception:
                        pass
                    cleanup()
                    raise

                self._plugins[plugin_id] = plugin_instance
                logger.success(f"Loaded plugin {meta['name']} ({plugin_id}) v{meta['version']}")

                return plugin_instance

        except Exception as e:
            logger.exception(f"Failed to load plugin {plugin_id}: {e}")
            return None

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

    @Slot(result=bool)
    def importPlugin(self) -> bool:
        """从 ZIP 导入插件（带校验）"""
        zip_path, _ = QFileDialog.getOpenFileName(
            None, "Import Plugin", "", "Class Widgets Plugin (*.cwplugin);;Plugin ZIP (*.zip)"
        )
        if not zip_path:
            return False

        self.thread = QThread()
        self.worker = PluginImportWorker(zip_path, self.external_path, self.scan, self.metas)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)

        def on_finished(diff):
            if diff:
                logger.info(f"Imported plugin(s): {', '.join(diff)}")
                self.pluginListChanged.emit()
                self.pluginImportSucceeded.emit()
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
