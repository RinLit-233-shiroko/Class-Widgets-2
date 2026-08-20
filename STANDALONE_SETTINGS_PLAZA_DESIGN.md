# 设置与插件中心包内启动器设计

## 目标

Windows 发布包在保留完整 Class Widgets 2 的基础上，额外提供“设置与插件中心”独立启动入口。用户可以不显示桌面 Widget，直接进入设置和插件中心；这两个窗口仍使用主程序包体内的配置、主题、插件、翻译和 QML 资源。

| 组件 | 职责 |
|---|---|
| `Class Widgets 2.exe` | 主程序。收到 `--settings-plaza` 参数时，仅运行设置和插件中心模式。 |
| `Class Widgets 2 Settings & Plugin Plaza.exe` | 轻量启动器。查找同目录主程序，并以 `--settings-plaza` 参数启动它。 |
| `settings_plaza_app.py` | 复用原应用的配置、主题、通知、插件与插件广场后端，不调用桌面 Widget 启动路径。 |
| `ClassWidgets-2-Windows.zip` | 最终发布包，同时包含主程序与启动器。 |

## Windows 工作流

构建工作流固定运行在 `windows-latest`。它先生成目录式主程序包体，再将单文件启动器写入同一输出目录，随后压缩整个目录为单个 Windows 发布包。工作流只接受 `v*` 版本标签触发自动发布，因此“设置与插件中心”这种功能标签不会被误当成应用版本。

签名默认关闭；即使手动启用，工作流也只在 SignPath 令牌、组织、项目和策略均已配置时提交签名请求。缺少任何一项时，构建会继续输出未签名的 Windows 包，而不是失败。
