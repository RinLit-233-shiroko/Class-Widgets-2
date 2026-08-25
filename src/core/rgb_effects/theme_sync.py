"""
RGB主题同步器
将RGB效果与主题系统连接，实现颜色实时同步
"""

from __future__ import annotations

from typing import Optional

from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtGui import QColor
from loguru import logger

from .manager import RGBEffectManager


class RGBThemeSync(QObject):
    """RGB主题同步器 - 桥接RGB效果和QML主题"""
    
    # 信号
    rgbColorChanged = Signal()  # RGB颜色变化
    
    def __init__(self, parent: Optional[QObject] = None):
        super().__init__(parent)
        
        # RGB效果管理器
        self._manager = RGBEffectManager(self)
        
        # 当前RGB颜色
        self._rgb_color = QColor(64, 153, 178)  # 默认颜色
        
        # 连接信号
        self._manager.colorChanged.connect(self._on_color_changed)
        
        logger.info("RGB Theme Sync initialized")
    
    @Property(str, notify=rgbColorChanged)
    def rgbColor(self) -> str:
        """RGB颜色（十六进制字符串，供QML使用）"""
        return self._rgb_color.name()
    
    @Property(int, notify=rgbColorChanged)
    def rgbColorInt(self) -> int:
        """RGB颜色（整数，供QML使用）"""
        return self._rgb_color.rgb()
    
    @Property('QVariant', notify=rgbColorChanged)
    def rgbColorList(self) -> list:
        """RGB颜色 [r, g, b]"""
        return [self._rgb_color.red(), self._rgb_color.green(), self._rgb_color.blue()]
    
    @Property(QObject, notify=rgbColorChanged)
    def manager(self) -> RGBEffectManager:
        """RGB效果管理器（供QML访问）"""
        return self._manager
    
    @Slot(int, int, int)
    def updateColor(self, r: int, g: int, b: int):
        """更新颜色"""
        self._rgb_color.setRgb(r, g, b)
        self.rgbColorChanged.emit()
    
    def _on_color_changed(self):
        """RGB管理器颜色变化回调"""
        color = self._manager.currentColor
        self._rgb_color.setRgb(color[0], color[1], color[2])
        self.rgbColorChanged.emit()
    
    def cleanup(self):
        """清理资源"""
        self._manager.cleanup()
