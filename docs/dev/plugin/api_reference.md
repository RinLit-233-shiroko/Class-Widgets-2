# API 参考

## SDK 组件

- **CW2Plugin**: 插件基类，提供生命周期管理
- **ConfigBaseModel**: 配置模型，自动数据验证和保存
- **PluginAPI**: 主 API 接口，包含所有功能模块

## 核心 API 组件

Class Widgets 2 提供了丰富的API供插件使用，所有API接口都通过 `PluginAPI` 对象提供：

```python
class PluginAPI:
    widgets: WidgetsAPI           # Widget相关功能
    notification: NotificationAPI  # 通知功能
    schedule: ScheduleAPI         # 课程表功能
    runtime: RuntimeAPI           # 运行时信息
    config: ConfigAPI            # 配置管理
    automation: AutomationAPI    # 自动化功能
    ui: UiAPI                    # UI相关功能
```

## API 详细说明

### 1. WidgetsAPI - Widget 管理

Widget是插件中最核心的功能，允许插件在界面上显示自定义内容。

#### 方法

##### register(widget_id, name, qml_path, backend_obj=None, settings_qml=None, default_settings=None)

注册一个Widget组件。

**参数：**
- `widget_id`: Widget唯一标识符，格式为 `vendor.name`，如 `com.example.mywidget`
- `name`: Widget的显示名称
- `qml_path`: QML界面文件的相对路径
- `backend_obj`: 后端Python对象，用于与QML通信（可选）
- `settings_qml`: Widget设置页面的QML文件路径（可选）
- `default_settings`: Widget的默认配置（可选）

**示例：**
```python
# 在插件的on_load方法中注册Widget
self.api.widgets.register(
    widget_id="com.example.weather",
    name="天气 Widget",
    qml_path="assets/weather.qml",
    backend_obj=self  # 将Python对象暴露给QML
)
```

### 2. NotificationAPI - 通知功能

通知API允许插件发送系统通知。

#### 信号

- `pushed`: 通知信号，当有其他插件或系统发送通知时会触发，携带通知文本

#### 方法

##### register_provider(provider_id, name=None, icon=None, use_system_notify=False)
##### get_provider(provider_id, name=None, icon=None, use_system_notify=False)

注册或获取一个通知提供者。两个方法功能相同，提供了不同的调用方式。

**参数：**
- `provider_id`: 提供者ID
- `name`: 显示名称，默认使用 "Plugin Provider (provider_id)"
- `icon`: 图标路径（可选）
- `use_system_notify`: 是否使用系统通知，默认False

**返回值：**
- `NotificationProvider`: 可用于发送通知的 Provider 实例

**示例：**
```python
# 注册通知提供者
provider = self.api.notification.register_provider(
    provider_id="my_plugin",
    name="我的插件",
    icon="assets/notification_icon.png"
)

# 或者使用get_provider
provider = self.api.notification.get_provider(
    provider_id="my_plugin",
    name="我的插件",
    icon="assets/notification_icon.png"
)
```

#### NotificationProvider 方法

##### push(level, title, message, duration, closable)

发送通知。

**参数：**
- `level`: 通知级别，使用NotificationLevel枚举：INFO(0), ANNOUNCEMENT(1), WARNING(2), SYSTEM(3)
- `title`: 通知标题
- `message`: 通知内容（可选）
- `duration`: 显示时长（毫秒），0表示常驻
- `closable`: 是否可关闭，默认True

**示例：**
```python
from ClassWidgets.SDK import NotificationLevel

provider.push(
    level=NotificationLevel.ANNOUNCEMENT,
    title="课程提醒",
    message="下一节是数学课",
    duration=5000,
    closable=True
)
```

### 3. ScheduleAPI - 课程表功能

ScheduleAPI提供访问和管理课程表数据的功能。

#### 方法

##### get()

获取课程表对象。

**返回值：** 课程表对象

##### reload()

重新加载课程表。

### 4. RuntimeAPI - 运行时信息

RuntimeAPI提供当前时间、日程、状态等运行时信息。

#### 属性

- `current_time`: 当前时间
- `current_day_of_week`: 当前星期几 (0-6)
- `current_week`: 当前周数
- `current_week_of_cycle`: 当前循环周
- `time_offset`: 时间偏移
- `schedule_meta`: 课程表元数据
- `current_day_entries`: 当日所有课程
- `current_entry`: 当前课程
- `next_entries`: 后续课程
- `remaining_time`: 剩余时间
- `progress`: 当前课程进度百分比
- `current_status`: 当前状态 (课程或休息)
- `current_subject`: 当前科目
- `current_title`: 当前课程标题

#### 信号

- `updated`: 课表/时间更新信号
- `statusChanged`: 当前日程状态变化信号
- `entryChanged`: 当前 Entry 更新信号

**示例：**
```python
# 获取当前课程信息
current_entry = self.api.runtime.current_entry
if current_entry:
    print(f"当前课程: {current_entry['title']}")
    print(f"开始时间: {current_entry['start_time']}")
    print(f"结束时间: {current_entry['end_time']}")
    print(f"进度: {self.api.runtime.progress:.1f}%")
```

### 5. ConfigAPI - 配置管理

ConfigAPI提供配置模型的注册和管理功能。

#### 方法

##### register_plugin_model(plugin_id, model)

注册插件配置模型。

**参数：**
- `plugin_id`: 插件唯一ID
- `model`: 配置模型实例

**示例：**
```python
# 在插件的__init__方法中
self.config = WeatherConfig()
self.api.config.register_plugin_model(self.pid, self.config)
```

##### get_plugin_model(plugin_id)

获取插件配置模型。

**参数：**
- `plugin_id`: 插件唯一ID

**返回值：** 配置模型实例

##### save()

保存所有配置到文件。

**示例：**
```python
# 保存配置
self.api.config.save()
```

### 6. AutomationAPI - 自动化功能

AutomationAPI允许插件注册自动化任务。

#### 方法

##### register(task)

注册自动化任务。

**参数：**
- `task`: 任务对象

### 7. UiAPI - UI 管理

UiAPI提供设置页面注册和管理功能。

#### 信号

- `settingsPageRegistered`: 设置页面注册信号

#### 属性

- `pages`: 已注册的设置页面列表

#### 方法

##### register_settings_page(qml_path, title=None, icon=None)

注册插件设置页面。

**参数：**
- `qml_path`: QML文件路径
- `title`: 页面标题，默认使用插件名称
- `icon`: 图标名称，使用RinUI图标库中的图标名称

**示例：**
```python
# 注册设置页面
self.api.ui.register_settings_page(
    qml_path="assets/settings.qml",
    title="天气设置",
    icon="ic_fluent_weather_sunny_20_regular"
)
```

##### unregister_settings_page(qml_path)

注销设置页面。

**参数：**
- `qml_path`: QML文件路径

## 路径解析

所有API中的路径参数都支持相对路径，会自动解析到插件目录。例如：

```python
# 相对路径
qml_path = "assets/settings.qml"  # 会被解析为插件目录下的assets/settings.qml
```

也可以使用绝对路径或Python的Path对象。