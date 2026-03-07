# SDK 知识

## SDK 概述

Class Widgets 2 SDK 是为插件开发者提供的开发工具包，提供了丰富的API和工具，帮助开发者快速创建功能强大的插件。

## SDK 核心类

### CW2Plugin - 插件基类

所有插件必须继承自 `CW2Plugin` 类，它是插件的核心基类，提供了插件生命周期管理和与系统交互的功能。

#### 生命周期方法

插件有以下生命周期方法：

1. **__init__(plugin_api)**: 构造函数，初始化插件
   - 接收一个 `PluginAPI` 对象，用于与系统交互
   - 初始化插件属性和状态

2. **on_load()**: 插件加载时调用
   - 用来注册配置、Widget、设置页面等
   - 在插件加载完成后执行初始化操作

3. **on_unload()**: 插件卸载时调用
   - 清理资源、取消注册等
   - 在插件卸载前执行清理操作

#### 常用属性

- `pid`: 插件ID
- `api`: 插件API对象，用于访问系统功能
- `meta`: 插件元数据字典

#### 示例

```python
from ClassWidgets.SDK import CW2Plugin

class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
        # 初始化插件状态
        self.message = "Hello from Plugin"
    
    def on_load(self):
        """插件加载时调用"""
        # 注册配置
        self.api.config.register_plugin_model(self.pid, self.config)
        
        # 注册设置页面
        self.api.ui.register_settings_page(
            qml_path="assets/settings.qml",
            title="我的设置"
        )
        
        # 注册Widget
        self.api.widgets.register(
            widget_id="com.example.mywidget",
            name="我的Widget",
            qml_path="assets/widget.qml",
            backend_obj=self
        )
    
    def on_unload(self):
        """插件卸载时调用"""
        # 清理资源
        print("插件卸载")
```

### ConfigBaseModel - 配置模型

`ConfigBaseModel` 是基于 Pydantic 的配置模型基类，可用来实现插件自身的配置功能。

#### 特性

1. **自动验证**: 所有字段都进行类型验证
2. **默认值**: 可以为字段设置默认值
3. **自动保存**: 配置变更自动保存到文件
4. **UI绑定**: 支持与UI组件绑定

#### 示例

```python
from ClassWidgets.SDK import ConfigBaseModel

class MyPluginConfig(ConfigBaseModel):
    """插件配置模型"""
    # 字符串类型
    api_key: str = ""
    
    # 数值类型
    refresh_interval: int = 300
    
    # 布尔类型
    enable_notifications: bool = True
    
    # 颜色值
    primary_color: str = "#007acc"
    
    # 列表类型
    enabled_features: list = ["feature1", "feature2"]
    
    def _on_change(self):
        """配置变更回调"""
        # 在配置变更时执行自定义逻辑
        print(f"配置已更新: {self.model_dump()}")

# 在插件中使用配置
class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
        # 创建配置模型实例
        self.config = MyPluginConfig()
    
    def on_load(self):
        # 注册配置模型
        self.api.config.register_plugin_model(self.pid, self.config)
    
    def update_api_key(self, new_key):
        # 直接修改配置值，会自动触发保存
        self.config.api_key = new_key
```

## PluginAPI - 插件API入口

`PluginAPI` 是插件访问系统功能的入口对象，提供了访问所有系统API的途径。

#### 组件API

- `widgets`: WidgetsAPI - Widget管理
- `notification`: NotificationAPI - 通知功能
- `schedule`: ScheduleAPI - 课程表功能
- `runtime`: RuntimeAPI - 运行时信息
- `config`: ConfigAPI - 配置管理
- `automation`: AutomationAPI - 自动化功能
- `ui`: UiAPI - UI管理

#### 示例

```python
class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
        # 保存API引用
        self.api = api
        
    def use_widgets_api(self):
        # 访问Widget API
        self.api.widgets.register(...)
        
    def use_notification_api(self):
        # 访问通知API
        provider = self.api.notification.register_provider(...)
        provider.notify(...)
        
    def use_runtime_api(self):
        # 访问运行时信息
        current_time = self.api.runtime.current_time
        current_entry = self.api.runtime.current_entry
```

## 信号与槽通信

Class Widgets 2 使用PySide6的信号与槽机制实现Python和QML之间的通信。

#### Python中的信号

```python
from PySide6.QtCore import Signal, QObject

class PluginBackend(QObject, CW2Plugin):
    # 定义信号
    data_updated = Signal(str)
    value_changed = Signal(int)
    
    def __init__(self, api):
        super().__init__(api)
    
    def update_data(self, new_data):
        # 更新数据后发射信号
        self.data_updated.emit(new_data)
    
    def set_value(self, new_value):
        # 更新值并发射信号
        self.value_changed.emit(new_value)
```

#### QML中的信号连接

```qml
// QML中使用Connections组件连接信号
Connections {
    target: pluginBackend // 指向后端对象
    function onDataUpdated(data) {
        console.log("数据已更新:", data)
    }
    
    function onValueChanged(value) {
        console.log("值已更改:", value)
    }
}
```

#### 使用@Slot装饰器暴露方法给QML

```python
from PySide6.QtCore import Slot

class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
        self.api = api
    
    # 无参数方法
    @Slot()
    def refresh_data():
        print("刷新数据")
    
    # 有参数方法
    @Slot(str)
    def process_text(text):
        print(f"处理文本: {text}")
    
    # 有返回值的方法
    @Slot(result=str)
    def get_text():
        return "这是来自Python的文本"
    
    # 复杂参数类型
    @Slot(int, str, result=bool)
    def process_data(id, name):
        print(f"处理数据: ID={id}, Name={name}")
        return True
```

在QML中调用Python方法：

```qml
// 直接调用
Button {
    text: "刷新"
    onClicked: pluginBackend.refresh_data()
}

// 调用带参数的方法
TextField {
    id: textInput
    placeholderText: "输入文本"
}

Button {
    text: "处理"
    onClicked: pluginBackend.process_text(textInput.text)
}

// 获取返回值
Button {
    text: "获取文本"
    onClicked: {
        var text = pluginBackend.get_text()
        console.log("获取的文本:", text)
    }
}
```

## 常用工具函数

### 路径处理

插件可以使用相对路径，系统会自动解析到插件目录：

```python
from pathlib import Path
from ClassWidgets.SDK import CW2Plugin

class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
    
    def get_resource_path(self, relative_path):
        """获取资源文件的绝对路径"""
        # 使用Path对象
        plugin_dir = Path(__file__).parent
        return plugin_dir / relative_path
    
    def get_asset_path(self, filename):
        """获取assets目录下的文件路径"""
        return self.get_resource_path(f"assets/{filename}")
```

### 日志记录

使用Loguru库进行日志记录：

```python
from loguru import logger
from ClassWidgets.SDK import CW2Plugin

class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
        # 配置日志
        logger.add(
            "plugin.log",
            format="{time} {level} {name}: {message}",
            level="INFO",
            rotation="10 MB",
            retention="7 days"
        )
    
    def on_load(self):
        logger.info("插件加载")
        self.api.widgets.register(...)
        
        try:
            # 某些可能出错的操作
            result = self.process_data()
            logger.info(f"处理数据成功: {result}")
        except Exception as e:
            logger.error(f"处理数据出错: {e}")
```

## 错误处理

处理常见错误和异常：

```python
from ClassWidgets.SDK import CW2Plugin

class Plugin(CW2Plugin):
    def __init__(self, api):
        super().__init__(api)
    
    def safe_register_widget(self):
        """安全注册Widget"""
        try:
            self.api.widgets.register(
                widget_id="com.example.widget",
                name="我的Widget",
                qml_path="assets/widget.qml",
                backend_obj=self
            )
        except ValueError as e:
            # 捕获参数错误
            print(f"参数错误: {e}")
        except Exception as e:
            # 捕获其他错误
            print(f"注册Widget时出错: {e}")
    
    def safe_load_config(self):
        """安全加载配置"""
        try:
            self.api.config.register_plugin_model(self.pid, self.config)
        except KeyError as e:
            print(f"配置加载失败，缺少键: {e}")
        except Exception as e:
            print(f"配置加载出错: {e}")
```