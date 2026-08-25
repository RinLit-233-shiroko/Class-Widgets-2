"""
RGB颜色效果引擎
独立实现，参考OpenRGB标准效果
"""

import math
import time
import colorsys
import random
from typing import List, Tuple, Callable, Optional
from dataclasses import dataclass, field
from enum import Enum


class EffectType(Enum):
    """效果类型枚举（与OpenRGB标准对齐）"""
    # OpenRGB标准效果
    DIRECT = "Direct"           # 直接控制
    STATIC = "Static"           # 静态
    BREATHING = "Breathing"     # 呼吸
    FLASHING = "Flashing"       # 闪烁
    SPECTRUM_CYCLE = "Spectrum Cycle"  # 光谱循环
    RAINBOW_WAVE = "Rainbow Wave"      # 彩虹波浪
    
    # 扩展效果
    RUNNING_LIGHT = "Running Light"    # 跑马灯
    METEOR = "Meteor"                  # 流星
    GRADIENT = "Gradient"              # 渐变
    SPARKLE = "Sparkle"                # 星火
    HEARTBEAT = "Heartbeat"            # 心跳
    
    @property
    def display_name(self) -> str:
        """获取中文显示名称"""
        names = {
            EffectType.DIRECT: "直接控制",
            EffectType.STATIC: "静态",
            EffectType.BREATHING: "呼吸",
            EffectType.FLASHING: "闪烁",
            EffectType.SPECTRUM_CYCLE: "光谱循环",
            EffectType.RAINBOW_WAVE: "彩虹波浪",
            EffectType.RUNNING_LIGHT: "跑马灯",
            EffectType.METEOR: "流星",
            EffectType.GRADIENT: "渐变",
            EffectType.SPARKLE: "星火",
            EffectType.HEARTBEAT: "心跳",
        }
        return names.get(self, self.value)


@dataclass
class EffectConfig:
    """效果配置"""
    name: str = "Static"
    speed: float = 1.0              # 速度 (0.1 - 10.0)
    brightness: float = 1.0         # 亮度 (0.0 - 1.0)
    color: Tuple[int, int, int] = (255, 0, 0)           # 主颜色
    secondary_color: Tuple[int, int, int] = (0, 0, 255) # 辅颜色
    saturation: float = 1.0         # 饱和度 (0.0 - 1.0)
    # 扩展参数
    direction: int = 1              # 方向: 1=正向, -1=反向
    tail_length: int = 3            # 拖尾长度
    wavelength: float = 3.0         # 波浪波长


class ColorEffectEngine:
    """颜色效果引擎"""
    
    def __init__(self, led_count: int = 1):
        self.led_count = max(led_count, 1)
        self.current_effect: Optional[EffectType] = None
        self.config = EffectConfig()
        self._start_time = time.time()
        self._callback: Optional[Callable] = None
        self._running = False
    
    def set_effect(self, effect: EffectType, config: EffectConfig = None):
        """切换效果"""
        self.current_effect = effect
        if config:
            self.config = config
        else:
            self.config.name = effect.value
        self._start_time = time.time()
    
    def stop(self):
        """停止效果"""
        self.current_effect = None
    
    def on_update(self, callback: Callable[[List[Tuple[int, int, int]]], None]):
        """设置颜色更新回调"""
        self._callback = callback
    
    def get_colors(self) -> List[Tuple[int, int, int]]:
        """获取当前帧的颜色"""
        if self.current_effect is None:
            return [(0, 0, 0)] * self.led_count
        
        t = time.time() - self._start_time
        
        # 根据效果类型计算颜色
        effect_map = {
            EffectType.DIRECT: self._static,
            EffectType.STATIC: self._static,
            EffectType.BREATHING: self._breathing,
            EffectType.FLASHING: self._flashing,
            EffectType.SPECTRUM_CYCLE: self._spectrum_cycle,
            EffectType.RAINBOW_WAVE: self._rainbow_wave,
            EffectType.RUNNING_LIGHT: self._running_light,
            EffectType.METEOR: self._meteor,
            EffectType.GRADIENT: self._gradient,
            EffectType.SPARKLE: self._sparkle,
            EffectType.HEARTBEAT: self._heartbeat,
        }
        
        colors = effect_map.get(self.current_effect, self._static)(t)
        
        # 应用亮度
        if self.config.brightness < 1.0:
            colors = [
                (int(r * self.config.brightness), 
                 int(g * self.config.brightness), 
                 int(b * self.config.brightness))
                for r, g, b in colors
            ]
        
        return colors
    
    def get_dominant_color(self) -> Tuple[int, int, int]:
        """获取主色调（用于主题同步）"""
        colors = self.get_colors()
        if not colors:
            return (0, 0, 0)
        
        # 计算加权平均颜色（排除纯黑）
        non_black = [c for c in colors if c != (0, 0, 0)]
        if not non_black:
            return colors[0]
        
        r = sum(c[0] for c in non_black) // len(non_black)
        g = sum(c[1] for c in non_black) // len(non_black)
        b = sum(c[2] for c in non_black) // len(non_black)
        
        return (r, g, b)
    
    def get_average_brightness(self) -> float:
        """获取平均亮度"""
        colors = self.get_colors()
        if not colors:
            return 0.0
        
        total = sum(max(c) for c in colors)
        return total / (len(colors) * 255)
    
    # ========== OpenRGB标准效果实现 ==========
    
    def _static(self, t: float) -> List[Tuple[int, int, int]]:
        """Static - 静态"""
        return [self.config.color] * self.led_count
    
    def _breathing(self, t: float) -> List[Tuple[int, int, int]]:
        """Breathing - 呼吸灯（与OpenRGB一致的正弦渐变）"""
        r, g, b = self.config.color
        # 正弦波：0→1→0，最小亮度0.05避免完全熄灭
        brightness = (math.sin(t * self.config.speed * 2 * math.pi) + 1) / 2
        brightness = 0.05 + brightness * 0.95
        
        return [(int(r * brightness), int(g * brightness), int(b * brightness))] * self.led_count
    
    def _flashing(self, t: float) -> List[Tuple[int, int, int]]:
        """Flashing - 闪烁（突然亮突然灭）"""
        cycle = t * self.config.speed
        # 30%时间亮，70%时间灭
        if cycle % 1.0 < 0.3:
            return [self.config.color] * self.led_count
        else:
            return [(0, 0, 0)] * self.led_count
    
    def _spectrum_cycle(self, t: float) -> List[Tuple[int, int, int]]:
        """Spectrum Cycle - 光谱循环（所有LED同色）"""
        hue = (t * self.config.speed * 0.3) % 1.0
        r, g, b = colorsys.hsv_to_rgb(hue, self.config.saturation, 1.0)
        color = (int(r * 255), int(g * 255), int(b * 255))
        return [color] * self.led_count
    
    def _rainbow_wave(self, t: float) -> List[Tuple[int, int, int]]:
        """Rainbow Wave - 彩虹波浪（LED形成彩虹，整体移动）"""
        colors = []
        for i in range(self.led_count):
            hue = (i / max(self.led_count, 1) + t * self.config.speed * 0.3) % 1.0
            r, g, b = colorsys.hsv_to_rgb(hue, self.config.saturation, 1.0)
            colors.append((int(r * 255), int(g * 255), int(b * 255)))
        return colors
    
    # ========== 扩展效果 ==========
    
    def _running_light(self, t: float) -> List[Tuple[int, int, int]]:
        """Running Light - 跑马灯"""
        colors = [(0, 0, 0)] * self.led_count
        pos = int(t * self.config.speed * 5 * self.config.direction) % self.led_count
        
        for i in range(self.config.tail_length):
            idx = (pos - i * self.config.direction) % self.led_count
            fade = 1 - (i / max(self.config.tail_length, 1))
            r, g, b = self.config.color
            colors[idx] = (int(r * fade), int(g * fade), int(b * fade))
        
        return colors
    
    def _meteor(self, t: float) -> List[Tuple[int, int, int]]:
        """Meteor - 流星"""
        colors = [(0, 0, 0)] * self.led_count
        head = (t * self.config.speed * 3) % (self.led_count + 10)
        
        tail = 8
        for i in range(tail):
            idx = int(head - i)
            if 0 <= idx < self.led_count:
                fade = 1 - (i / tail)
                fade = fade * fade  # 平方衰减
                r, g, b = self.config.color
                colors[idx] = (int(r * fade), int(g * fade), int(b * fade))
        
        return colors
    
    def _gradient(self, t: float) -> List[Tuple[int, int, int]]:
        """Gradient - 双色渐变"""
        r1, g1, b1 = self.config.color
        r2, g2, b2 = self.config.secondary_color
        
        t_norm = (math.sin(t * self.config.speed * 2 * math.pi) + 1) / 2
        
        r = int(r1 + (r2 - r1) * t_norm)
        g = int(g1 + (g2 - g1) * t_norm)
        b = int(b1 + (b2 - b1) * t_norm)
        
        return [(r, g, b)] * self.led_count
    
    def _sparkle(self, t: float) -> List[Tuple[int, int, int]]:
        """Sparkle - 星火闪烁"""
        colors = [(0, 0, 0)] * self.led_count
        
        # 随机点亮约20%的LED
        count = max(1, self.led_count // 5)
        r, g, b = self.config.color
        
        for _ in range(count):
            idx = random.randint(0, self.led_count - 1)
            brightness = random.uniform(0.3, 1.0)
            colors[idx] = (int(r * brightness), int(g * brightness), int(b * brightness))
        
        return colors
    
    def _heartbeat(self, t: float) -> List[Tuple[int, int, int]]:
        """Heartbeat - 心跳效果"""
        r, g, b = self.config.color
        # 模拟心跳：快速双脉冲
        cycle = (t * self.config.speed) % 1.0
        
        if cycle < 0.1:
            brightness = cycle / 0.1
        elif cycle < 0.2:
            brightness = 1 - (cycle - 0.1) / 0.1
        elif cycle < 0.3:
            brightness = (cycle - 0.2) / 0.1 * 0.7
        elif cycle < 0.4:
            brightness = 0.7 * (1 - (cycle - 0.3) / 0.1)
        else:
            brightness = 0
        
        brightness = 0.05 + brightness * 0.95
        return [(int(r * brightness), int(g * brightness), int(b * brightness))] * self.led_count


class ThemeSynchronizer:
    """主题同步器 - 将颜色效果同步到小组件主题"""
    
    def __init__(self, engine: ColorEffectEngine):
        self.engine = engine
        self._running = False
        self._theme_callback: Optional[Callable[[int, int, int], None]] = None
        self._fps = 30
    
    def on_theme_update(self, callback: Callable[[int, int, int], None]):
        """设置主题更新回调"""
        self._theme_callback = callback
    
    def start(self, fps: int = 30):
        """开始同步"""
        self._fps = fps
        self._running = True
        self._loop()
    
    def stop(self):
        """停止同步"""
        self._running = False
    
    def _loop(self):
        """主循环"""
        import time as time_module
        
        interval = 1.0 / self._fps
        while self._running:
            try:
                # 获取当前主色调
                dominant = self.engine.get_dominant_color()
                
                # 更新主题
                if self._theme_callback:
                    self._theme_callback(*dominant)
                
                time_module.sleep(interval)
            except Exception:
                break


# ========== 效果预设 ==========

EFFECT_PRESETS = {
    "Ocean": {
        "effect": EffectType.BREATHING,
        "speed": 0.5,
        "color": (0, 100, 200),
        "name": "海洋",
        "description": "海洋呼吸效果"
    },
    "Sunset": {
        "effect": EffectType.GRADIENT,
        "speed": 0.3,
        "color": (255, 100, 0),
        "secondary_color": (255, 200, 0),
        "name": "日落",
        "description": "日落渐变效果"
    },
    "Forest": {
        "effect": EffectType.BREATHING,
        "speed": 0.7,
        "color": (0, 180, 0),
        "name": "森林",
        "description": "森林呼吸效果"
    },
    "Aurora": {
        "effect": EffectType.RAINBOW_WAVE,
        "speed": 0.5,
        "name": "极光",
        "description": "极光波浪效果"
    },
    "Fire": {
        "effect": EffectType.METEOR,
        "speed": 2.0,
        "color": (255, 100, 0),
        "name": "火焰",
        "description": "火焰流星效果"
    },
    "Lava": {
        "effect": EffectType.SPECTRUM_CYCLE,
        "speed": 0.2,
        "color": (255, 50, 0),
        "name": "熔岩",
        "description": "熔岩光谱循环"
    },
    "Cyberpunk": {
        "effect": EffectType.SPARKLE,
        "speed": 5.0,
        "color": (255, 0, 255),
        "name": "赛博朋克",
        "description": "赛博朋克星火"
    },
    "Heartbeat": {
        "effect": EffectType.HEARTBEAT,
        "speed": 1.2,
        "color": (255, 0, 0),
        "name": "心跳",
        "description": "心跳效果"
    },
}

# 预设中文名映射
EFFECT_PRESET_NAMES = {k: v["name"] for k, v in EFFECT_PRESETS.items()}
