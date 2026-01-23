import importlib
import importlib.util
import json
import sys
from contextlib import contextmanager
from pathlib import Path
from typing import List, Dict

from PySide6.QtCore import QCoreApplication
from loguru import logger
from packaging.specifiers import SpecifierSet
from packaging.version import Version

from src.core.directories import BUILTIN_PLUGINS_PATH
from src.core.plugin import CW2Plugin, PluginAPI
from src.core.plugin.api import __version__ as __API_VERSION__
from src.plugins import BUILTIN_PLUGINS

class PluginLoader:
    def __init__(self, plugin_api: PluginAPI, external_path: Path):
        """
        :param plugin_api: PluginAPI实例
        :param external_path: 外部插件目录路径
        """
        self.api = plugin_api
        self.external_path = external_path
        self.builtin_path = BUILTIN_PLUGINS_PATH
        
        # 注入运行时SDK
        self._inject_runtime_sdk()
    
    def _inject_runtime_sdk(self):
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
    
    def scan_plugins(self, external_path: Path) -> List[dict]:
        """扫描所有插件（外部插件 + 内置插件）"""
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
    def discover_plugins_in_dir(base_dir: Path) -> List[Path]:
        """发现指定目录中的插件"""
        found = []
        if base_dir.exists() and base_dir.is_dir():
            for plugin_dir in base_dir.iterdir():
                if plugin_dir.is_dir() and (plugin_dir / "cwplugin.json").exists():
                    found.append(plugin_dir)
        return found
    
    def _load_meta(self, plugin_dir: Path, type: str = "external") -> dict:
        """加载单个插件的meta信息"""
        try:
            meta_path = plugin_dir / "cwplugin.json"
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            meta["_path"] = plugin_dir
            meta["_type"] = type
            
            if not self.validate_meta(meta, plugin_dir):
                logger.warning(f"Plugin meta invalid, skipped: {plugin_dir}")
                return None
                
            return meta
        except Exception as e:
            logger.exception(f"Failed to read plugin meta from {plugin_dir}: {e}")
            return None
    
    @staticmethod
    def validate_meta(meta: dict, plugin_dir: Path) -> bool:
        """验证插件meta信息"""
        required_fields = ["id", "name", "version", "api_version", "entry", "author"]
        
        for field in required_fields:
            if field not in meta or not meta[field]:
                logger.warning(f"Plugin meta missing required field '{field}' in {plugin_dir}")
                return False
        return True
    
    def load_plugin(self, meta: dict) -> CW2Plugin or None:
        """加载单个插件实例"""
        if meta["_type"] == "builtin":
            return self._load_builtin_plugin(meta)
        else:
            return self._load_external_plugin(meta)
    
    def load_plugins(self, metas: List[dict], enabled_plugins: List[str]) -> Dict[str, CW2Plugin]:
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
                except Exception as e:
                    logger.exception(f"Failed to initialize plugin {meta['id']}: {e}")
            else:
                logger.warning(f"Enabled plugin {pid} not found in metas")
                
        return loaded_plugins
    
    def _load_builtin_plugin(self, meta: dict) -> CW2Plugin or None:
        """加载内置插件"""
        plugin_id = meta["id"]
        
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
            
            plugin_instance.on_load()
            logger.success(f"Loaded builtin plugin {meta['name']} ({plugin_id}) v{meta['version']}")
            return plugin_instance
            
        except Exception as e:
            logger.exception(f"Failed to load builtin plugin {plugin_id}: {e}")
            return None
    
    def _load_external_plugin(self, meta: dict) -> CW2Plugin or None:
        """加载外部插件"""
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
                logger.warning(
                    f"Plugin {plugin_id} (api_version {meta.get('api_version')}) "
                    f"is not compatible with app version"
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
                
                # 注入PATH和meta
                plugin_instance.PATH = plugin_dir
                plugin_instance.meta = meta
                
                if not isinstance(plugin_instance, CW2Plugin):
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
                
                logger.success(f"Loaded plugin {meta['name']} ({plugin_id}) v{meta['version']}")
                return plugin_instance
                
        except Exception as e:
            logger.exception(f"Failed to load plugin {plugin_id}: {e}")
            return None
    
    @contextmanager
    def plugin_import_context(self, plugin_dir: Path):
        """插件导入上下文管理器"""
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