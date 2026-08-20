"""Class Widgets 2 设置与插件中心独立版入口。

该入口沿用项目的配置、主题、通知和插件后端，但不创建或运行桌面 Widget 窗口。
"""
from __future__ import annotations

import os
import sys
from typing import Literal

# 允许从源码目录和 PyInstaller 解包目录启动。
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from PySide6.QtCore import QTimer
from PySide6.QtWidgets import QApplication

from src.core.central import AppCentral
from src.core.windows.manager import AppWindowManager


class _NoopInstanceGuard:
    """独立版不与完整 Class Widgets 主程序争用单实例锁。"""

    def release(self) -> None:
        return None


class _NoopWidgetsWindow:
    """为 AppCentral 清理流程提供空实现，确保不实例化 Widget QML 窗口。"""

    is_qml_ready = False

    def __init__(self, theme_manager) -> None:
        self.theme_manager = theme_manager

    def release(self) -> None:
        return None


class SettingsPlazaWindowManager(AppWindowManager):
    """当最后一个独立窗口关闭时，退出本程序。"""

    def release(self, name: str) -> None:
        super().release(name)
        QTimer.singleShot(80, self._quit_if_no_window_remains)

    def _quit_if_no_window_remains(self) -> None:
        if self._windows or self._pending_releases:
            return
        app = QApplication.instance()
        if app:
            app.quit()


class SettingsPlazaCentral(AppCentral):
    """删去桌面 Widget 初始化步骤的应用中枢。"""

    def _check_single_instance(self) -> None:
        self.instance_guard = _NoopInstanceGuard()
        self.multi_instances = False

    def _initialize_ui_components(self) -> None:
        # 原 AppCentral 在这里创建 WidgetsWindow；独立版明确不加载该窗口。
        self.widgets_window = _NoopWidgetsWindow(self.theme_manager)


def main(mode: Literal["settings", "plaza", "both"] = "both") -> int:
    app = QApplication(sys.argv)
    window_titles = {
        "settings": "Class Widgets 2 Settings",
        "plaza": "Class Widgets 2 Plugin Plaza",
        "both": "Class Widgets 2 Settings & Plugin Plaza",
    }
    app.setApplicationName(window_titles[mode])
    app.setOrganizationName("Class Widgets")

    central = SettingsPlazaCentral()
    # 使用支持“最后窗口关闭即退出”的窗口管理器替换原管理器。
    central.window_manager = SettingsPlazaWindowManager(central)

    # 完整 Settings 与 Plugin Plaza 页面所需的后端初始化。
    central._load_config()
    central._load_translator()
    central._setup_logging()
    central._load_schedule()
    central._load_class_swap()
    central._load_runtime()

    # 独立入口可只打开设置、只打开插件中心，或保留兼容模式同时打开两者。
    if mode in {"settings", "both"}:
        central.window_manager.open_settings()
    if mode in {"plaza", "both"}:
        QTimer.singleShot(120 if mode == "both" else 0, central.window_manager.open_plugin_plaza)
    exit_code = app.exec()
    central.cleanup()
    return exit_code


if __name__ == "__main__":
    command_modes = {
        "--settings-only": "settings",
        "--plugin-plaza-only": "plaza",
        "--settings-plaza": "both",  # 保留旧参数兼容性
    }
    selected_mode = next(
        (command_modes[arg] for arg in sys.argv[1:] if arg in command_modes),
        "both",
    )
    raise SystemExit(main(selected_mode))
