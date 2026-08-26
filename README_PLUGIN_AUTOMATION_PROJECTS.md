# 插件自动化项目开发指南

ClassWidgets 允许插件在“设置 → 自动化”页面中注册**插件自动化项目**。项目以独立卡片显示，用户可以单独启用或停用，并可在插件提供回调时打开插件自己的设置界面。

> 插件自动化项目是插件能力的**受控入口**，而不是向 CW 内置规则引擎注入任意触发器或命令的接口。插件应自行实现其业务逻辑，并仅在用户启用项目后启动相应能力。

## 适用场景

插件项目适用于“专注模式”“考试模式”“课堂统计”“课程提示”等有独立启用状态的插件功能。用户能够在统一的自动化页面查看这些项目，而插件仍保有自己的设置、数据和运行逻辑。

| 能力 | 支持情况 |
|---|---|
| 在自动化页面显示插件项目卡片 | 支持。 |
| 用户单独启用或停用项目 | 支持，启用状态会持久化。 |
| 插件接收启用状态变化 | 支持，通过 `on_enabled_changed` 回调。 |
| 从项目卡片打开插件设置 | 支持，通过可选 `on_open_settings` 回调。 |
| 注册任意内置触发器或动作 | 不支持。 |
| 远程下发 Shell 命令或高权限操作 | 不支持。 |

## 快速开始

插件在 `on_load()` 中调用 `self.api.automation.register_project()`。项目 ID 在插件内必须唯一；CW 会自动使用插件 ID 为其加命名空间，因此不同插件可以使用相同的本地项目 ID。

```python
from src.core.plugin import CW2Plugin


class ExamModePlugin(CW2Plugin):
    def on_load(self):
        super().on_load()

        self._automation_enabled = False
        self.project_id = self.api.automation.register_project(
            project_id="exam-mode",
            title="考试模式",
            description="启用后，插件会按自身设置进入考试提醒模式。",
            icon="ic_fluent_shield_task_20_regular",
            on_enabled_changed=self.on_automation_enabled_changed,
            on_open_settings=self.open_exam_mode_settings,
        )

    def on_automation_enabled_changed(self, enabled: bool) -> None:
        self._automation_enabled = enabled
        if enabled:
            self.start_exam_mode()
        else:
            self.stop_exam_mode()

    def open_exam_mode_settings(self) -> None:
        # 在这里打开插件自己的窗口、对话框或设置入口。
        # 此回调由用户点击自动化页面中的“设置”按钮时调用。
        self.show_settings_window()

    def start_exam_mode(self) -> None:
        pass

    def stop_exam_mode(self) -> None:
        pass

    def on_unload(self):
        # 请主动停止插件自己的后台工作。
        # CW 会自动移除本插件在自动化页面中的项目卡片。
        self.stop_exam_mode()
```

注册成功后，返回的 `project_id` 类似如下形式：

```text
org.example.exam.exam-mode
```

其中 `org.example.exam` 是插件元数据中的 ID，`exam-mode` 是插件调用时提供的本地项目 ID。

## API 参考

```python
self.api.automation.register_project(
    project_id: str,
    title: str,
    description: str = "",
    icon: str = "ic_fluent_plug_connected_20_regular",
    on_enabled_changed: Callable[[bool], object] | None = None,
    on_open_settings: Callable[[], object] | None = None,
) -> str
```

| 参数 | 说明 |
|---|---|
| `project_id` | 插件内的本地项目 ID，只能包含字母、数字、`.`、`_` 和 `-`，最长 80 个字符。CW 自动添加插件 ID 命名空间。 |
| `title` | 自动化页面显示的项目名称，不能为空，最长 80 个字符。 |
| `description` | 项目用途说明，最长 240 个字符。 |
| `icon` | RinUI 图标名称；未填写时使用插件连接图标。 |
| `on_enabled_changed` | 可选回调。注册时会立即收到当前用户保存的启用状态；之后每次用户切换开关也会收到新的布尔值。 |
| `on_open_settings` | 可选回调。提供后，项目卡片显示“设置”按钮；用户点击时调用该回调。 |

若插件不提供 `on_enabled_changed`，项目仍可显示和保存开关状态，但插件无法依据该状态启动或停止业务逻辑。因此，对于有实际运行行为的项目，应始终提供此回调。

## 状态保存与生命周期

CW 将项目开关状态保存到本地配置目录下的 `automation_plugin_projects.json`。保存内容仅包含项目全局 ID 与布尔启用状态，不包含插件的业务设置或敏感数据。

| 生命周期事件 | CW 行为 | 插件应做的事 |
|---|---|---|
| 插件加载并注册项目 | 恢复已保存状态并立即调用 `on_enabled_changed`。 | 根据回调参数启动或保持停止。 |
| 用户切换项目开关 | 原子保存状态并调用 `on_enabled_changed`。 | 立即启动或停止插件自身的自动化逻辑。 |
| 用户点击“设置” | 调用 `on_open_settings`（若提供）。 | 打开插件自己的设置入口。 |
| 插件卸载或替换 | 从自动化页面移除该插件的运行时项目卡片；已保存开关状态会保留。 | 停止线程、定时器、监听器和其他后台工作。 |
| 同 ID 插件重新安装 | 恢复此前保存的开关状态。 | 在首次回调中正确处理恢复状态。 |

## 安全边界

CW 的内置自动化规则与插件自动化项目相互隔离。插件项目接口不会授予下列权限：

- 不会允许插件向 CW 的内置规则编辑器添加任意触发器、动作或远程指令。
- 不会提供远程 Shell 执行、远程重启、硬件控制或绕过用户确认的高权限路径。
- 不会将项目状态同步到集控；项目状态仅保存在本机。
- 不会替插件管理其后台线程、网络连接或定时器；插件必须在 `on_unload()` 中自行清理。

插件如需执行本地业务，应在 `on_enabled_changed(True)` 后自行创建受控任务，并在收到 `False` 或 `on_unload()` 时停止。对于网络、文件、进程或设备相关能力，插件还应在自身设置页向用户明确说明用途与权限。

## 常见问题

### 项目没有出现在自动化页面

请确认 `register_project()` 在插件的 `on_load()` 或其后调用，并且先调用了 `super().on_load()`。只有处于有效插件上下文中的调用才能获得插件 ID 并完成注册。

### 为什么首次注册就收到一次启用状态回调

这是为了使插件在重启后恢复正确状态。用户之前若已开启项目，插件无需等待用户再次切换开关；它会在注册时直接收到 `True`。

### 可以在回调中直接执行耗时操作吗

不建议。启用状态回调发生在应用主线程。耗时计算、网络请求或阻塞式 I/O 应由插件转交给自身受控的工作线程或异步任务；停用和卸载时必须能够取消或停止这些任务。

### 可以删除用户保存的项目状态吗

通常不需要。CW 在插件卸载时保留状态，便于同 ID 插件重新安装后恢复用户选择。若插件需要迁移自身 ID，应在插件更新逻辑中主动向用户说明变化，而不是静默复用无关项目状态。
