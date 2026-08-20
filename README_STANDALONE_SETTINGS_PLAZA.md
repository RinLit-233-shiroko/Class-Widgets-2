# Class Widgets 2：设置与插件中心包内启动器

Windows 发布包会额外包含 `Class Widgets 2 Settings & Plugin Plaza.exe`。该文件是一个轻量启动器，位于 `Class Widgets 2.exe` 同一目录，用于直接打开 **设置窗口** 与 **插件中心窗口**。

> 此启动器不会携带第二份 Qt、主题、配置或插件资源；它会调用同目录的 `Class Widgets 2.exe --settings-plaza`，因此始终复用同一个 Class Widgets 2 包体。

## 使用方式

下载并解压 `ClassWidgets-2-Windows.zip` 后，双击以下任一文件：

| 文件 | 行为 |
|---|---|
| `Class Widgets 2.exe` | 启动完整应用，包括桌面 Widget。 |
| `Class Widgets 2 Settings & Plugin Plaza.exe` | 仅启动设置与插件中心，不加载桌面 Widget 画布。 |

启动器必须与主程序保留在同一文件夹中。若移动或单独复制启动器，因找不到 `Class Widgets 2.exe` 而无法运行。

## 构建策略

GitHub Actions 仅在 `windows-latest` 上构建一个 Windows 包。构建流程先生成主程序的目录式包体，再将单文件启动器输出到同一目录，最后统一压缩为 `ClassWidgets-2-Windows.zip`。上游许可证文件会随主包一并分发。
