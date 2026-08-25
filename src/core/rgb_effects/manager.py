"""
RGB效果管理器
管理颜色效果引擎，将颜色同步到QML主题
"""

from __future__ import annotations

import time
from typing import Optional, TYPE_CHECKING

from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QThread
from loguru import logger

from .engine import (
    ColorEffectEngine,
    EffectType,
    EffectConfig,
    EFFECT_PRESETS,
    EFFECT_PRESET_NAMES,
)

if TYPE_CHECKING:
    from src.core.central import AppCentral


class RGBEffectWorker(QThread):
    """RGB效果工作线程"""
    
    color_updated = Signal(int, int, int)  # r, g, b
    
    def __init__(self, engine: ColorEffectEngine, fps: int = 30):
        super().__init__()
        self.engine = engine
        self.fps = fps
        self._running = False
    
    def run(self):
        """主循环"""
        self._running = True
        interval = 1.0 / self.fps
        
        while self._running:
            try:
                # 获取当前主色调
                dominant = self.engine.get_dominant_color()
                self.color_updated.emit(*dominant)
                time.sleep(interval)
            except Exception as e:
                logger.error(f"RGB worker error: {e}")
                break
    
    def stop(self):
        """停止工作线程"""
        self._running = False


class RGBEffectManager(QObject):
    """RGB效果管理器 - 供QML调用"""
    
    # 信号
    colorChanged = Signal()  # 颜色变化通知
    effectChanged = Signal()  # 效果变化通知
    enabledChanged = Signal()  # 启用状态变化
    
    def __init__(self, parent: Optional[QObject] = None):
        super().__init__(parent)
        
        # 效果引擎
        self._engine = ColorEffectEngine(led_count=1)
        
        # 当前状态
        self._enabled = False
        self._current_effect = EffectType.STATIC
        self._current_color = (255, 0, 0)
        self._speed = 1.0
        self._brightness = 1.0
        
        # 工作线程
        self._worker: Optional[RGBEffectWorker] = None
        
        # 颜色更新定时器（用于QML绑定）
        self._update_timer = QTimer(self)
        self._update_timer.setInterval(33)  # ~30fps
        self._update_timer.timeout.connect(self._on_update_timeout)
        
        logger.info("RGB Effect Manager initialized")
    
    # ========== QML 属性 ==========
    
    @Property(bool, notify=enabledChanged)
    def enabled(self) -> bool:
        """是否启用RGB效果"""
        return self._enabled
    
    @enabled.setter
    def enabled(self, value: bool):
        if self._enabled != value:
            self._enabled = value
            self.enabledChanged.emit()
            if value:
                self._start_effect()
            else:
                self._stop_effect()
    
    @Property('QVariant', notify=colorChanged)
    def currentColor(self) -> list:
        """当前颜色 [r, g, b]"""
        r, g, b = self._current_color
        return [r, g, b]
    
    @Property(str, notify=effectChanged)
    def currentEffect(self) -> str:
        """当前效果名称"""
        return self._current_effect.value
    
    @Property(float, notify=effectChanged)
    def speed(self) -> float:
        """效果速度"""
        return self._speed
    
    @speed.setter
    def speed(self, value: float):
        self._speed = max(0.1, min(10.0, value))
        self._update_effect()
    
    @Property(float, notify=effectChanged)
    def brightness(self) -> float:
        """亮度"""
        return self._brightness
    
    @brightness.setter
    def brightness(self, value: float):
        self._brightness = max(0.0, min(1.0, value))
        self._update_effect()
    
    @Property('QVariant', notify=effectChanged)
    def currentColorRGB(self) -> int:
        """当前颜色作为整数（用于QML）"""
        r, g, b = self._current_color
        return (r << 16) | (g << 8) | b
    
    # ========== QML 方法 ==========
    
    @Slot(str)
    def setEffect(self, effect_name: str):
        """设置效果"""
        try:
            effect = EffectType(effect_name)
            self._current_effect = effect
            self._update_effect()
            self.effectChanged.emit()
            logger.info(f"RGB effect set to: {effect_name}")
        except ValueError:
            logger.warning(f"Unknown effect: {effect_name}")
    
    @Slot(int, int, int)
    def setColor(self, r: int, g: int, b: int):
        """设置主颜色"""
        self._current_color = (r, g, b)
        self._update_effect()
        self.colorChanged.emit()
    
    @Slot(str)
    def applyPreset(self, preset_name: str):
        """应用预设"""
        if preset_name not in EFFECT_PRESETS:
            logger.warning(f"Unknown preset: {preset_name}")
            return
        
        preset = EFFECT_PRESETS[preset_name]
        effect = preset.get("effect", EffectType.STATIC)
        self._current_effect = effect
        self._speed = preset.get("speed", 1.0)
        self._current_color = preset.get("color", (255, 0, 0))
        
        self._update_effect()
        self.effectChanged.emit()
        self.colorChanged.emit()
        logger.info(f"Applied RGB preset: {preset_name}")
    
    @Slot(result=list)
    def getEffectList(self) -> list:
        """获取所有可用效果列表（含中文名）"""
        return [
            {
                "name": e.value,
                "value": e.value,
                "display": e.display_name,
            }
            for e in EffectType
        ]
    
    @Slot(result=list)
    def getPresetList(self) -> list:
        """获取所有预设列表（含中文名）"""
        return [
            {
                "name": name,
                "display": EFFECT_PRESET_NAMES.get(name, name),
                "description": preset.get("description", ""),
                "effect": preset.get("effect", EffectType.STATIC).value,
            }
            for name, preset in EFFECT_PRESETS.items()
        ]
    
    @Slot(result=str)
    def getEffectDisplayName(self, effect_value: str) -> str:
        """获取效果的中文显示名称"""
        try:
            effect = EffectType(effect_value)
            return effect.display_name
        except ValueError:
            return effect_value
    
    @Slot(result=str)
    def getPresetDisplayName(self, preset_name: str) -> str:
        """获取预设的中文显示名称"""
        return EFFECT_PRESET_NAMES.get(preset_name, preset_name)
    
    @Slot()
    def start(self):
        """启动RGB效果"""
        if not self._enabled:
            self.enabled = True
    
    @Slot()
    def stop(self):
        """停止RGB效果"""
        if self._enabled:
            self.enabled = False
    
    # ========== 内部方法 ==========
    
    def _update_effect(self):
        """更新效果配置"""
        config = EffectConfig(
            name=self._current_effect.value,
            speed=self._speed,
            brightness=self._brightness,
            color=self._current_color,
        )
        self._engine.set_effect(self._current_effect, config)
    
    def _start_effect(self):
        """启动效果引擎"""
        self._update_effect()
        self._update_timer.start()
        logger.info("RGB effect started")
    
    def _stop_effect(self):
        """停止效果引擎"""
        self._update_timer.stop()
        self._current_color = (64, 153, 178)  # 恢复默认颜色
        self.colorChanged.emit()
        logger.info("RGB effect stopped")
    
    def _on_update_timeout(self):
        """定时器回调 - 更新颜色"""
        if not self._enabled:
            return
        
        dominant = self._engine.get_dominant_color()
        if dominant != self._current_color:
            self._current_color = dominant
            self.colorChanged.emit()
    
    def cleanup(self):
        """清理资源"""
        self._stop_effect()
        if self._worker:
            self._worker.stop()
            self._worker.wait()
