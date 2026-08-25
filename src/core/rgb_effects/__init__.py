# RGB Effects Engine for Class Widgets 2
"""
RGB颜色效果引擎
提供多种颜色效果，可同步到小组件主题
"""

from .engine import (
    ColorEffectEngine,
    EffectType,
    EffectConfig,
    ThemeSynchronizer,
    EFFECT_PRESETS,
    EFFECT_PRESET_NAMES,
)

from .manager import RGBEffectManager
from .theme_sync import RGBThemeSync

__all__ = [
    "ColorEffectEngine",
    "EffectType",
    "EffectConfig",
    "ThemeSynchronizer",
    "EFFECT_PRESETS",
    "RGBEffectManager",
    "RGBThemeSync",
]
