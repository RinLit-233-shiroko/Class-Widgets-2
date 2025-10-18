from datetime import datetime
from pathlib import Path
from loguru import logger
from pydantic import Field, PrivateAttr
from PySide6.QtCore import QObject, QTimer, Signal, Property, Slot

from .model import AppConfig, ScheduleConfig, PreferencesConfig, PluginsConfig, LocaleConfig, InteractionsConfig, \
    ConfigBaseModel, NetworkConfig
from src import __version__, __version_type__


class RootConfig(ConfigBaseModel):
    app: AppConfig = Field(default_factory=AppConfig)
    locale: LocaleConfig = Field(default_factory=LocaleConfig)
    schedule: ScheduleConfig = Field(default_factory=ScheduleConfig)
    preferences: PreferencesConfig = Field(default_factory=PreferencesConfig)
    interactions: InteractionsConfig = Field(default_factory=InteractionsConfig)
    plugins: PluginsConfig = Field(default_factory=PluginsConfig)
    network: NetworkConfig = Field(default_factory=NetworkConfig)

    _on_change: callable = PrivateAttr(default=None)

    def __setattr__(self, name, value):
        super().__setattr__(name, value)
        if self._on_change and name != "_on_change":
            self._on_change()


# 配置管理器
class ConfigManager(QObject):
    configChanged = Signal()

    def __init__(self, path: Path, filename: str):
        super().__init__()
        self.path = Path(path)
        self.filename = filename
        self.full_path = self.path / filename

        self._config = RootConfig()
        self._bind_nested_on_change(self._config)

        self.save_timer = QTimer(self)
        self.save_timer.setInterval(1000 * 60)  # 1分钟保存一次
        self.save_timer.timeout.connect(self.save)

    def _bind_nested_on_change(self, obj):
        """
        递归绑定 _on_change 给所有嵌套的 ConfigBaseModel
        """
        obj._on_change = lambda: (self.configChanged.emit())
        for field_name, field in obj.__fields__.items():
            value = getattr(obj, field_name)
            if isinstance(value, ConfigBaseModel):
                self._bind_nested_on_change(value)

    def _clean_useless_configs(self):
        """
        清理无用的配置项
        """
        outdated_reschedule_days = []

        for day in self._config.schedule.reschedule_day:
            if datetime.now().strftime('%Y-%m-%d') > day:
                outdated_reschedule_days.append(day)

        for day in outdated_reschedule_days:
            self._config.schedule.reschedule_day.pop(day)

        logger.info(f"Cleaned useless configs.")

    def load_config(self):
        if self.full_path.exists():
            try:
                data = self.full_path.read_text(encoding="utf-8")
                self._config = RootConfig.model_validate_json(data)

                if (self._config.app.version != __version__
                    or self._config.app.channel != __version_type__):
                    logger.warning(f"Config version mismatch: {self._config.app.version} {self._config.app.channel}"
                                   f"!= {__version__} {__version_type__}")
                    self._config.app.version = __version__
                    self._config.app.channel = __version_type__

                self._bind_nested_on_change(self._config)
                self._clean_useless_configs()
            except Exception as e:
                logger.warning(f"Load config failed: {e}, use default config")
        self.save()

    def save(self, silent=False):
        try:
            self.path.mkdir(parents=True, exist_ok=True)
            self.full_path.write_text(self._config.model_dump_json(indent=4), encoding="utf-8")
            if not silent:
                logger.success(f"Save config success: {self.full_path}")
        except Exception as e:
            logger.error(f"Save config failed: {e}")

    def __getattr__(self, name):
        """代理属性获取"""
        if name == '_config':
            return self.__dict__['_config']

        return getattr(self._config, name)

    @Property('QVariant', notify=configChanged)
    def data(self):
        return self._config.model_dump()  # 整个配置转 dict

    @Slot(str, "QVariant")
    def set(self, key: str, value):
        keys = key.split('.')  # 支持点分层，如 "preferences.current_theme"
        cfg = self._config
        for k in keys[:-1]:
            cfg = getattr(cfg, k)

        last_key = keys[-1]

        # 如果最后一级是 dict，就赋值到 dict 的键
        if isinstance(cfg, dict):
            cfg[last_key] = value
        else:
            setattr(cfg, last_key, value)

        self._config._on_change()
        self.configChanged.emit()
