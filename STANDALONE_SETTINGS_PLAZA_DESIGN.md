# 设置与插件中心独立版设计

## 目标

本独立版复用 Class Widgets 2 现有的 QML 页面、主题、配置、插件管理和插件广场数据接口，仅启动“设置”和“插件中心”两个辅助窗口。应用不会调用 `WidgetsWindow.run()`，因此不会创建、显示或刷新桌面 Widget 画布。

| 范围 | 处理方式 |
|---|---|
| 设置窗口 | 保留原生 `Settings.qml`、侧边栏和各设置页面。配置、主题、语言、通知、插件管理及更新页面继续使用现有后端。 |
| 插件中心 | 保留原生 `PluginPlaza.qml` 及首页、列表、搜索、详情和下载页面；继续访问项目默认的插件广场服务。 |
| 桌面 Widget | 不加载 `MainInterface.qml`，不启动 Widget 定时器、鼠标监测、桌面透明窗或 Widget 运行时刷新。 |
| 课程表编辑器等额外窗口 | 不作为启动界面；原设置页中可能存在的入口保留为原项目行为，且仍在同一 EXE 进程内。 |
| 可执行文件 | 使用 PyInstaller 的 Windows `--onefile` 模式，目标产物为一个 `ClassWidgets2-Settings-Plaza.exe` 文件。 |

## 启动序列

独立入口将创建 `AppCentral` 来复用项目的配置、主题、翻译、通知、插件与插件广场后端，但不调用原 `run()` 方法。取而代之的是加载配置与翻译、加载课表和主题/插件数据，然后直接打开设置窗口和插件中心窗口。这样既能满足设置页和插件中心对 `Configs`、`CWThemeManager`、`PluginManager`、`PlazaBridge` 等 QML 上下文对象的依赖，又不会执行桌面 Widget 的启动路径。

## 许可证与资源

独立版保留上游项目的 MIT 许可证文件，并在 Windows 打包时将 `src/qml`、`src/plugins`、`src/themes`、`themes`、`assets` 和许可证一并收集，使 QML 模块、主题预览、语言文件、图标和插件中心页面可以在单文件 EXE 解包后的运行目录中正常加载。
