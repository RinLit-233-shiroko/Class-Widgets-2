# Class Widgets 2：设置与插件中心独立版

本构建产物将 [Class Widgets 2](https://github.com/MMCKB/Class-Widgets-2) 的 **设置窗口** 与 **插件中心窗口** 提取为一个独立的 Windows 可执行文件。程序复用原项目的 QML 页面、主题、配置、插件管理和插件广场接口，并遵循上游项目随附的 MIT 许可证。

## 运行方式

在 64 位 Windows 上双击 `ClassWidgets2-Settings-Plaza.exe` 即可运行。首次启动时会同时打开“设置”和“插件中心”两个窗口。该版本为 PyInstaller 单文件程序，启动时会在临时目录自动解包运行所需资源，不需要安装 Python。

| 功能范围 | 状态 |
|---|---|
| 设置窗口及其导航页面 | 已保留 |
| 插件中心：首页、插件列表、搜索、详情与下载页 | 已保留 |
| 主题、语言、通知和配置页面 | 已保留 |
| 插件广场网络访问 | 已保留；需要网络连接 |
| 桌面 Widget 透明窗、Widget 刷新和鼠标监测 | 明确不启动 |
| 原软件其他辅助窗口 | 不作为独立版启动界面 |

## 源码再次构建

若需自行生成 EXE，请在 64 位 Windows 中安装 Python 3.12，然后双击 `build_settings_plaza_windows.bat`。构建结果将写入 `dist\ClassWidgets2-Settings-Plaza.exe`。

> 本独立版并未加载 `MainInterface.qml`，也不会调用桌面 Widget 的启动方法。因此，即便完整 Class Widgets 2 正在运行，它也不会创建第二个桌面 Widget 画布。

## 上游来源与许可证

源代码基于上游仓库，原始版权和 MIT 许可证文本保留在 `LICENSE` 文件中。插件中心展示的远程内容由其服务端提供，内容可用性与网络连接状态有关。
