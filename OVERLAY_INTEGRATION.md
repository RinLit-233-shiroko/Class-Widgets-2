# 堆叠组件内嵌改造 —— 进度与规格

> 目标：把 `com.kryon.more_settings` 插件的「堆叠组件」(`kryon.overlay`) 融进主程序，
> 不再依赖补丁注入。源码目录 `src/`，全英文 + `qsTr()`。

## 已完成

- [x] `src/qml/ClassWidgets/Components/dialogs/AddOverlayMemberDialog.qml`
      成员选择对话框。已把组件 id 从插件版的 `com.overlay` 改为宿主命名规范
      `classwidgets.overlay`（两处：`defs` 里的排除判断、`onOpened` 里取后端）。

## 待完成

### 1. 布局层属性 `overlayEditingId`

`src/qml/ClassWidgets/Components/WidgetsLayout.qml` 需要新增一个属性，
用于标记「当前正在编辑哪个堆叠组件实例」。

```qml
property string overlayEditingId: ""
```

对应插件补丁组 `_OVERLAY_LAYOUT_OPS`（见
`More_Settings-Features/features_src/kryon.overlay/patches.py`）。
**改造时应直接读该文件里这几个 op 的实际字符串内容**，它是补丁的唯一真相来源：

- `_OVERLAY_LAYOUT_OPS`    → `WidgetsLayout.qml`
- `_OVERLAY_DELEGATE_OPS`  → `WidgetsLayoutDelegate.qml`（右键菜单入口 + 编辑行 + 对话框引用）
- `_OVERLAY_CONTAINER_V2_OPS` → `WidgetsContainer.qml`（可见性判断）

> ⚠️ `_OVERLAY_DELEGATE_OPS` 原本是 `atomic=True` 应用的：菜单项、编辑行、对话框引用
> 三样必须成套加，少一半会让 QML 加载失败。

### 2. 组件本体

- `More_Settings-Features/qml/overlay.qml`（902 行）
  → `src/qml/widgets/overlay.qml`
- `More_Settings-Features/qml/overlay-settings.qml`（225 行）
  → `src/qml/widgets/settings/overlay.qml`
- `More_Settings-Features/overlay_backend.py`（314 行）
  → `src/plugins/cw_widgets/overlay_backend.py`

**不能照搬，必须逐段改写掉插件耦合：**

| 插件写法 | 改成 |
|---|---|
| `Configs.data.plugins.configs["com.kryon.more_settings"]` | 读组件自己的 `settings` 对象 |
| `backend.setXxx()` 这类插件 `@Slot` | `WidgetsModel.updateSettings(instanceId, {...})` |
| 300ms / 1s 轮询 Timer | 配置变更信号直接绑定 |

### 3. 注册为内置组件

`src/plugins/cw_widgets/widgets.py` 的 `get_widgets_list()` 里加一项：

```python
{
    "widget_id": "classwidgets.overlay",
    "name": QCoreApplication.translate("Widgets", "Overlay"),
    "qml_path": Path(QML_PATH / "widgets" / "overlay.qml").as_posix(),
    "backend_obj": self,
    "settings_qml": Path(QML_PATH / "widgets" / "settings" / "overlay.qml").as_posix(),
    "default_settings": {
        "interval_ms": 5000,
        "lyric_gate": False
    }
},
```

后端 `OverlayBackend` 需要以 `@Slot` 暴露 `addMember(instance_id, widget_id)`
等方法（对话框会直接调用），并挂到 `backend_obj` 上。

## 已经内嵌完成的三项（本轮完成，源码环境已验证）

- 事件倒计时动画开关：`widgets/eventCountdown.qml` + `widgets/settings/eventCountdown.qml`
- 时间组件增强：`widgets/Time.qml` + `widgets/settings/Time.qml`
  （默认保持官方外观：不显示日期/星期副标题，`text:` 每 3 秒交替日期与星期）
- 隐藏深度：`core/config/model.py` 的 `widgets_hide_depth` +
  `pages/settings/General/Widgets.qml` 的滑杆

## 开发环境

```powershell
cd "F:\Class Widgets 2 开发\主程序修改\Class-Widgets-2"
.venv\Scripts\python.exe src\app.py
```

- `.venv` 用 `--system-site-packages` 建，复用全局 PySide6 6.11.2
- 启动前先关掉打包版的 ClassWidgets2
- 改了 `qsTr()` 字符串后重新提取翻译：

```powershell
pyside6-lupdate (src 下所有 .py/.qml) -ts assets/locales/<lang>.ts
pyside6-lrelease assets/locales/<lang>.ts
```
