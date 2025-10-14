from enum import Enum

from pydantic import BaseModel, Field, Extra, PrivateAttr
from typing import Dict, List, Optional, Any
from PySide6.QtCore import QLocale, QCoreApplication

from ..directories import DEFAULT_THEME
from src import __version__, __version_type__

class ConfigBaseModel(BaseModel):
    _on_change: callable = PrivateAttr(default=None)

    def __init__(self, **data):
        super().__init__(**data)
        for name, value in self.__dict__.items():
            if isinstance(value, ConfigBaseModel):
                value._on_change = self._on_change

    def __setattr__(self, name, value):  # 实时发送更新信号
        super().__setattr__(name, value)
        if isinstance(value, ConfigBaseModel):
            value._on_change = self._on_change
        if self._on_change and name != "_on_change":
            self._on_change()


class LayoutAnchor(str, Enum):
    TOP_LEFT = "top_left"
    TOP_CENTER = "top_center"
    TOP_RIGHT = "top_right"
    BOTTOM_LEFT = "bottom_left"
    BOTTOM_CENTER = "bottom_center"
    BOTTOM_RIGHT = "bottom_right"


class ZOrder(str, Enum):
    TOP = "top"
    BOTTOM = "bottom"
    NORMAL = "normal"

class WidgetEntry(ConfigBaseModel):
    type_id: str
    instance_id: str
    settings: Optional[Dict[str, Any]] = {}

class LocaleConfig(ConfigBaseModel):
    """
    语言设置
    """
    language: str = QLocale.system().name()

class ScheduleDefaultDurationConfig(ConfigBaseModel):
    """
    课程默认时长
    """
    class_: int = 40  # 分钟
    break_: int = 10
    activity: int = 30

class HideInteractionsConfig(ConfigBaseModel):
    """
    隐藏交互配置
    """
    state: bool = False  # 状态
    in_class: bool = False  # 上课时
    clicked: bool = True  # 点击时
    maximized: bool = False  # 窗口最大化
    fullscreen: bool = False   # 窗口全屏

    mini_mode: bool = False  # 切换迷你模式


class AppConfig(ConfigBaseModel):
    """
    应用程序配置
    """
    debug_mode: bool = False
    no_logs: bool = False
    version: str = __version__
    channel: str = __version_type__
    tutorial_completed: bool = False  # 是否完成初始化
    auto_startup: bool = False  # 开机自启


class PreferencesConfig(ConfigBaseModel):
    """
    偏好设置
    """
    current_theme: str = Field(default_factory=lambda: DEFAULT_THEME.as_uri())
    scale_factor: float = 1.0  # 缩放比例
    opacity: float = 1.0  # 不透明度
    widgets_anchor: LayoutAnchor = LayoutAnchor.TOP_CENTER  # 对齐方式
    widgets_offset_x: int = 0  # 水平偏移
    widgets_offset_y: int = 24  # 垂直偏移
    widgets_layer: ZOrder = ZOrder.TOP  # 小组件置顶/置底
    display: Optional[str] = None  # 指定显示器

    mini_mode: bool = False  # 迷你

    widgets_presets: Dict[str, List[WidgetEntry]] = Field(
        default_factory=lambda: {
            "default": [
                WidgetEntry(type_id="classwidgets.time", instance_id="8ee721ef-ab36-4c23-834d-2c666a6739a3"),
                WidgetEntry(type_id="classwidgets.currentActivity", instance_id="87985398-2844-4c9e-b27d-6ea81cd0a2c6"),
            ]
        }
    )
    current_preset: str = "default"

    class Config:
        use_enum_values = True
        extra = Extra.allow


class InteractionsConfig(ConfigBaseModel):
    """
    交互配置
    """
    hover_fade: bool = False  # 鼠标悬停时淡出
    hide: HideInteractionsConfig = Field(default_factory=HideInteractionsConfig)  # 隐藏配置


class PluginsConfig(ConfigBaseModel):
    enabled: List[str] = ["builtin.classwidgets.widgets"]

class ScheduleConfig(ConfigBaseModel):
    current_schedule: str = QCoreApplication.translate("Configs", "New Schedule 1")
    preparation_time: int = 2  # min
    default_duration: ScheduleDefaultDurationConfig = Field(default_factory=ScheduleDefaultDurationConfig)  # 默认时长
    time_offset: int = 0  # 时差偏移
    reschedule_day: dict = {}  # 调整日程
    
    # 自动时间偏移功能
    auto_time_offset_enabled: bool = False  # 是否启用自动时间偏移
    auto_time_offset_value: int = 0  # 每天的时间偏移增减值（秒）
    auto_time_offset_last_update: str = ""  # 上次更新日期（YYYY-MM-DD格式）
