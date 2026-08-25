# RGB颜色效果功能集成指南

## 功能概述

RGB颜色效果功能允许用户选择动态颜色效果，小组件主题颜色会实时跟随效果变化。

## 文件结构

```
src/
├── core/
│   └── rgb_effects/           # RGB效果引擎
│       ├── __init__.py        # 模块导出
│       ├── engine.py          # 颜色效果引擎
│       ├── manager.py         # RGB效果管理器（QML接口）
│       └── theme_sync.py      # 主题同步器
├── themes/
│   ├── __init__.py            # 内置主题定义（已添加RGB主题）
│   └── rgb/                   # RGB主题
│       └── ClassWidgets/
│           └── theme/
│               ├── qmldir     # 模块定义
│               ├── components/ # QML组件
│               └── material/   # 颜色定义
└── qml/
    └── settings/
        └── RGBSettings.qml     # RGB设置界面
```

## 集成步骤

### 1. 注册RGB效果管理器

在 `src/core/central.py` 中添加：

```python
from src.core.rgb_effects import RGBThemeSync

class AppCentral:
    def __init__(self):
        # ... 其他初始化 ...
        
        # RGB主题同步器
        self.rgb_theme_sync = RGBThemeSync()
```

### 2. 在QML中注册类型

在 `src/app.py` 或主QML文件中添加：

```python
from src.core.rgb_effects import RGBThemeSync

# 注册为QML单例
qmlRegisterSingletonType(RGBThemeSync, "ClassWidgets", 1, 0, "ThemeManager", 
                         lambda engine, script_engine: central.rgb_theme_sync)
```

### 3. 在QML中使用

```qml
import ClassWidgets 1.0

// 访问RGB颜色
Rectangle {
    color: ThemeManager.rgbColor
}

// 访问效果管理器
Button {
    text: "启用RGB"
    onClicked: ThemeManager.manager.enabled = !ThemeManager.manager.enabled
}
```

## 颜色效果列表

### OpenRGB标准效果
- **Static** - 静态颜色
- **Breathing** - 呼吸灯
- **Flashing** - 闪烁
- **Spectrum Cycle** - 光谱循环
- **Rainbow Wave** - 彩虹波浪

### 扩展效果
- **Running Light** - 跑马灯
- **Meteor** - 流星
- **Gradient** - 双色渐变
- **Sparkle** - 星火闪烁
- **Heartbeat** - 心跳

## 预设效果

- **Ocean** - 海洋呼吸
- **Sunset** - 日落渐变
- **Forest** - 森林呼吸
- **Aurora** - 极光波浪
- **Fire** - 火焰流星
- **Cyberpunk** - 赛博朋克

## 主题切换逻辑

1. 用户选择"RGB"主题
2. 主题管理器检测到RGB主题激活
3. 启动RGB效果引擎
4. 小组件颜色实时跟随效果变化
5. 用户切换到其他主题时，RGB效果停止

## 配置存储

RGB效果配置存储在 `Configs.data.rgb_effects` 中：

```python
{
    "enabled": True,
    "effect": "Breathing",
    "speed": 1.0,
    "brightness": 1.0,
    "color": [255, 0, 0]
}
```

## 许可证说明

本功能完全独立实现，不依赖OpenRGB代码，无许可证冲突。
