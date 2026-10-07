import importlib
import importlib.util
import json
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import Optional, TYPE_CHECKING

from PySide6.QtCore import QCoreApplication
from loguru import logger
from packaging.specifiers import SpecifierSet
from packaging.version import Version

from src.core.storage.directories import BUILTIN_PLUGINS_PATH
from src.core.plugin import CW2Plugin, PluginAPI
from src.core.plugin.api import __version__ as __API_VERSION__
from src.core.plugin.models import PluginLoadFailure, PluginMeta
from src.plugins import BUILTIN_PLUGINS

if TYPE_CHECKING:
    from src.core.config.model import ConfigBaseModel


def _safe_is_dir(path: Path) -> bool:
    """``Path.is_dir()`` 在目录不可读时会抛 ``PermissionError``（WinError 5）。"""
    try:
        return path.is_dir()
    except OSError as error:
        logger.warning("Plugin path {} is not readable: {}", path, error)
        return False


def _safe_exists(path: Path) -> bool:
    """``Path.exists()`` 对 EACCES/EPERM 不返回 False，而是直接抛异常。"""
    try:
        return path.exists()
    except OSError as error:
        logger.warning("Plugin path {} is not accessible: {}", path, error)
        return False


class PluginLoader:
    def __init__(self, plugin_api: PluginAPI, external_path: Path):
        """
        :param plugin_api: PluginAPI实例
        :param external_path: 外部插件目录路径
        """
        self.api: PluginAPI = plugin_api
        self.external_path: Path = external_path
        self.builtin_path: Path = BUILTIN_PLUGINS_PATH
        #: 扫描/加载过程中失败的插件，供 PluginManager 通知与诊断使用。
        self.failures: list[PluginLoadFailure] = []
        
        # 注入运行时SDK
        self._inject_runtime_sdk()
    
    def _inject_runtime_sdk(self) -> None:
        """注入运行时SDK，让插件能够导入 ClassWidgets.SDK"""
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
            
            # API组件类
            from src.core.plugin.components import (
                BaseAPI as RealBaseAPI,
                WidgetsAPI as RealWidgetsAPI,
                NotificationAPI as RealNotificationAPI,
                ScheduleAPI as RealScheduleAPI,
                ThemeAPI as RealThemeAPI,
                RuntimeAPI as RealRuntimeAPI,
                ConfigAPI as RealConfigAPI,
                AutomationAPI as RealAutomationAPI,
                ActionsAPI as RealActionsAPI,
                UiAPI as RealUiAPI
            )
            
            # 通知相关类型
            from src.core.notification.provider import NotificationProvider as RealNotificationProvider
            from src.core.notification.model import NotificationLevel, NotificationData, NotificationProviderConfig
            
            # 课程表相关类型
            from src.core.schedule.model import EntryType, WeekType
            
            # 批量注入
            fake_mod.PluginAPI = RealPluginAPI
            fake_mod.CW2Plugin = RealCW2Plugin
            fake_mod.ConfigBaseModel = RealConfigBaseModel
            
            # API组件类
            fake_mod.BaseAPI = RealBaseAPI
            fake_mod.WidgetsAPI = RealWidgetsAPI
            fake_mod.NotificationAPI = RealNotificationAPI
            fake_mod.ScheduleAPI = RealScheduleAPI
            fake_mod.ThemeAPI = RealThemeAPI
            fake_mod.RuntimeAPI = RealRuntimeAPI
            fake_mod.ConfigAPI = RealConfigAPI
            fake_mod.AutomationAPI = RealAutomationAPI
            fake_mod.ActionsAPI = RealActionsAPI
            fake_mod.UiAPI = RealUiAPI
            
            # 通知相关类型
            fake_mod.NotificationProvider = RealNotificationProvider
            fake_mod.NotificationLevel = NotificationLevel
            fake_mod.NotificationData = NotificationData
            fake_mod.NotificationProviderConfig = NotificationProviderConfig
            
            # 课程表相关类型
            fake_mod.EntryType = EntryType
            fake_mod.WeekType = WeekType
        except Exception as e:
            logger.exception(f"Failed to import runtime API classes for injection: {e}")
            return
            
        sys.modules[module_name] = fake_mod
        logger.debug(f"Injected {module_name} into sys.modules (runtime-backed).")
    
    def scan_plugins(
        self,
        external_path: Path,
        include_external: bool = True,
    ) -> list[PluginMeta]:
        """扫描所有插件（内置插件，以及可选的外部插件）"""
        self.failures = []
        metas = []
        
        # 内置插件
        for item in BUILTIN_PLUGINS:
            meta = item["meta"].copy()
            meta["name"] = QCoreApplication.translate("Plugins", meta["name"])
            meta["_type"] = "builtin"
            meta["_class"] = item["class"]
            meta["_path"] = None
            metas.append(meta)
        
        # 扫描外部插件
        if not include_external:
            # 安全模式：外部插件目录完全不会被读取，也不会被导入。
            logger.warning("Safe mode: external plugins are skipped")
            return metas

        for plugin_dir in self.discover_plugins_in_dir(external_path):
            meta = self._load_meta(plugin_dir, "external")
            if meta:
                # API版本兼容性检查 - 标记但不阻止显示
                if not check_api_version(meta["api_version"]):
                    logger.warning(f"Plugin {meta['name']} API version {meta['api_version']} is incompatible.")
                    meta["_compatible"] = False
                else:
                    meta["_compatible"] = True
                
                metas.append(meta)
        
        return metas
    
    @staticmethod
    def discover_plugins_in_dir(base_dir: Path) -> list[Path]:
        """发现指定目录中的插件。

        外部插件目录位于用户可写区域，权限/占用问题会以 ``PermissionError``
        （WinError 5）的形式出现在 ``exists()`` / ``is_dir()`` / ``iterdir()`` 上。
        扫描阶段必须只跳过读不到的条目，绝不能让启动流程因此中断。
        """
        found: list[Path] = []
        if not _safe_is_dir(base_dir):
            return found

        try:
            entries = list(base_dir.iterdir())
        except OSError as error:
            logger.warning("Failed to list plugin directory {}: {}", base_dir, error)
            return found

        for plugin_dir in entries:
            if not _safe_is_dir(plugin_dir):
                continue
            if not _safe_exists(plugin_dir / "cwplugin.json"):
                continue
            found.append(plugin_dir)
        return found
    
    def _load_meta(self, plugin_dir: Path, type: str = "external") -> Optional[PluginMeta]:
        """加载单个插件的meta信息"""
        try:
            meta_path = plugin_dir / "cwplugin.json"
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            meta["_path"] = plugin_dir
            meta["_type"] = type
            
            if not self.validate_meta(meta, plugin_dir):
                logger.warning(f"Plugin meta invalid, skipped: {plugin_dir}")
                self._record_failure(
                    plugin_id=str(meta.get("id") or plugin_dir.name),
                    name=str(meta.get("name") or ""),
                    stage="scan",
                    error="cwplugin.json is missing required fields",
                )
                return None
                
            return meta
        except Exception as e:
            logger.exception(f"Failed to read plugin meta from {plugin_dir}: {e}")
            self._record_failure(
                plugin_id=plugin_dir.name,
                stage="scan",
                error=f"{type(e).__name__}: {e}",
            )
            return None

    def _record_failure(
        self,
        *,
        plugin_id: str,
        stage: str,
        error: str,
        name: str = "",
    ) -> None:
        """记录一次插件失败，避免“插件悄悄消失”。"""
        self.failures.append(
            PluginLoadFailure(
                plugin_id=str(plugin_id or ""),
                name=str(name or ""),
                stage=stage,
                error=str(error or ""),
            )
        )

    def _discard_plugin(self, plugin_instance, plugin_id: str) -> None:
        """加载失败后的收尾：回调、快捷键、模块缓存都要清干净。"""
        if plugin_instance is not None:
            try:
                plugin_instance.on_unload()
            except Exception:
                logger.exception(
                    "Plugin {} raised while unloading after a failed load", plugin_id
                )
        try:
            self.api.ui.unregister_plugin_shortcuts(plugin_id)
        except Exception:
            logger.exception("Failed to unregister shortcuts of plugin {}", plugin_id)
        self._unregister_module(plugin_id)

    @staticmethod
    def _unregister_module(plugin_id: str) -> None:
        module_name = f"cw_plugin_{plugin_id}"
        if module_name in sys.modules:
            try:
                del sys.modules[module_name]
            except Exception:
                logger.exception("Failed to drop module {}", module_name)
    
    @staticmethod
    def validate_meta(meta: PluginMeta, plugin_dir: Path) -> bool:
        """验证插件meta信息"""
        required_fields = ["id", "name", "version", "api_version", "entry", "author"]
        
        for field in required_fields:
            if field not in meta or not meta[field]:
                logger.warning(f"Plugin meta missing required field '{field}' in {plugin_dir}")
                return False
        return True
    
    def load_plugin(self, meta: PluginMeta) -> Optional[CW2Plugin]:
        """加载单个插件实例"""
        if meta["_type"] == "builtin":
            return self._load_builtin_plugin(meta)
        else:
            return self._load_external_plugin(meta)
    
    def load_plugins(self, metas: list[PluginMeta], enabled_plugins: list[str]) -> dict[str, CW2Plugin]:
        """加载多个插件实例"""
        loaded_plugins = {}
        
        for pid in enabled_plugins:
            meta = next((m for m in metas if m["id"] == pid), None)
            if meta:
                try:
                    logger.info(f"Loading plugin {meta['name']} ({meta['id']}) v{meta['version']}")
                    plugin = self.load_plugin(meta)
                    if plugin:
                        loaded_plugins[pid] = plugin
                    elif not self._has_failure(pid):
                        # 加载器没给出具体原因时仍要留痕，不能安静地少一个插件。
                        self._record_failure(
                            plugin_id=pid,
                            name=str(meta.get("name") or ""),
                            stage="load",
                            error="Plugin did not return an instance",
                        )
                except Exception as e:
                    logger.exception(f"Failed to initialize plugin {meta['id']}: {e}")
                    self._record_failure(
                        plugin_id=str(pid),
                        name=str(meta.get("name") or ""),
                        stage="load",
                        error=f"{type(e).__name__}: {e}",
                    )
            else:
                logger.warning(f"Enabled plugin {pid} not found in metas")
                self._record_failure(
                    plugin_id=str(pid),
                    stage="scan",
                    error="Enabled plugin was not found during the plugin scan",
                )
                
        return loaded_plugins

    def _has_failure(self, plugin_id: str) -> bool:
        return any(failure.plugin_id == plugin_id for failure in self.failures)
    
    def _load_builtin_plugin(self, meta: PluginMeta) -> Optional[CW2Plugin]:
        """加载内置插件"""
        plugin_id = meta["id"]
        plugin_instance = None
        stage = "builtin-load"
        
        try:
            if not check_api_version(meta["api_version"]):
                logger.error(
                    f"Builtin-Plugin {plugin_id} (api_version {meta.get('api_version')}) "
                    f"is not compatible with app version"
                )
            
            PluginClass = meta["_class"]
            plugin_instance = PluginClass(self.api)
            
            # 注入PATH和meta
            plugin_instance.PATH = meta["_path"]
            plugin_instance.meta = meta
            
            if not isinstance(plugin_instance, CW2Plugin):
                raise TypeError("Builtin plugin must inherit from CW2Plugin")
            
            stage = "on_load"
            plugin_instance.on_load()
            logger.success(f"Loaded builtin plugin {meta['name']} ({plugin_id}) v{meta['version']}")
            return plugin_instance
            
        except Exception as e:
            logger.exception(f"Failed to load builtin plugin {plugin_id}: {e}")
            # 内置插件同样可能拿到了 PluginAPI 上下文，失败后必须交还。
            self._discard_plugin(plugin_instance, plugin_id)
            self.api.set_current_plugin(None)
            self._record_failure(
                plugin_id=str(plugin_id),
                name=str(meta.get("name") or ""),
                stage=stage,
                error=f"{type(e).__name__}: {e}",
            )
            return None
    
    def _load_external_plugin(self, meta: PluginMeta) -> Optional[CW2Plugin]:
        """加载外部插件"""
        plugin_dir: Path = meta["_path"]
        plugin_id = meta["id"]
        module_name = f"cw_plugin_{plugin_id}"
        plugin_instance = None
        # 失败时记录卡在哪一步，避免只有在堆栈里才能看出原因。
        stage = "entry"
        
        try:
            if not check_api_version(meta["api_version"]):
                logger.warning(
                    f"Plugin {plugin_id} (api_version {meta.get('api_version')}) "
                    f"is not compatible with app version"
                )
            
            entry_file = plugin_dir / meta["entry"]
            if not _safe_exists(entry_file):
                raise FileNotFoundError(f"Entry file not found: {entry_file}")
            
            self._unregister_module(plugin_id)
            
            with self.plugin_import_context(plugin_dir):
                stage = "import"
                spec = importlib.util.spec_from_file_location(module_name, str(entry_file))
                if not spec or not spec.loader:
                    raise RuntimeError("Invalid plugin entry (spec loader not found)")
                
                module = importlib.util.module_from_spec(spec)
                sys.modules[module_name] = module
                
                stage = "execute"
                spec.loader.exec_module(module)
                
                if not hasattr(module, "Plugin"):
                    raise AttributeError("Plugin entry file does not define a 'Plugin' class")
                
                PluginClass = getattr(module, "Plugin")
                
                stage = "instantiate"
                plugin_instance = PluginClass(self.api)
                
                # 注入PATH和meta
                plugin_instance.PATH = plugin_dir
                plugin_instance.meta = meta
                
                if not isinstance(plugin_instance, CW2Plugin):
                    raise TypeError("Plugin class must inherit from CW2Plugin (runtime class)")
                
                stage = "on_load"
                try:
                    plugin_instance.on_load()
                finally:
                    # Plugin context is only valid while its lifecycle hook runs.
                    self.api.set_current_plugin(None)

            # with 块结束后 sys.path 已恢复，此时持久化插件路径供运行时使用
            self._persist_plugin_paths(plugin_dir)

            logger.success(f"Loaded plugin {meta['name']} ({plugin_id}) v{meta['version']}")
            return plugin_instance
                
        except Exception as e:
            logger.exception(f"Failed to load plugin {plugin_id} during {stage}: {e}")
            self.api.set_current_plugin(None)
            self._discard_plugin(plugin_instance, plugin_id)
            self._record_failure(
                plugin_id=str(plugin_id),
                name=str(meta.get("name") or ""),
                stage=stage,
                error=f"{type(e).__name__}: {e}",
            )
            return None

    @staticmethod
    def _persist_plugin_paths(plugin_dir: Path):
        """将插件目录及其 libs/ 持久化到 sys.path，供运行时延迟导入使用"""
        for p in [plugin_dir / "libs", plugin_dir]:
            ps = str(p)
            if _safe_is_dir(p) and ps not in sys.path:
                sys.path.append(ps)
                logger.debug(f"Persisted plugin path: {ps}")
    
    @contextmanager
    def plugin_import_context(self, plugin_dir: Path):
        """插件导入上下文管理器"""
        old_path = sys.path.copy()
        try:
            # 插件目录优先
            to_insert = [str(plugin_dir)]
            libs_dir = plugin_dir / "libs"
            if _safe_is_dir(libs_dir):
                to_insert.insert(0, str(libs_dir))
            for p in reversed(to_insert):
                if p in sys.path:
                    sys.path.remove(p)
                sys.path.insert(0, p)
            yield
        finally:
            # 恢复
            sys.path[:] = old_path


def check_api_version(plugin_api_version: str) -> bool:
    """检查插件API版本兼容性"""
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
