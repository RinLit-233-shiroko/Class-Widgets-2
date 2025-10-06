import win32gui
import win32con
import ctypes
from loguru import logger

from .base import AutomationTask

SYSTEM_WINDOW_CLASSES = {
    "Progman",          # 桌面
    "Shell_TrayWnd",    # 任务栏
    "Windows.UI.Core.CoreWindow",  # 输入体验等
}


def is_window_maximized(hwnd) -> bool:
    placement = win32gui.GetWindowPlacement(hwnd)
    return placement[1] == win32con.SW_MAXIMIZE

def is_window_fullscreen(hwnd) -> bool:
    if not win32gui.IsWindowVisible(hwnd):
        return False
    rect = win32gui.GetWindowRect(hwnd)
    screen_width = ctypes.windll.user32.GetSystemMetrics(0)
    screen_height = ctypes.windll.user32.GetSystemMetrics(1)
    margin = 2
    return rect[0] <= margin and rect[1] <= margin and rect[2] >= screen_width - margin and rect[3] >= screen_height - margin


class AutoHideTask(AutomationTask):
    def __init__(self, app_central):
        super().__init__(app_central)

        self.runtime = app_central.runtime
        self.runtime.currentsChanged.connect(self.on_schedule_changed)

        self._window_states = {}
        self.previous_state = False

    def update(self):
        """主循环"""
        if (not self.app_central.configs.interactions.hide.maximized
                and not self.app_central.configs.interactions.hide.fullscreen):
            return

        if self.app_central.configs.interactions.hide.in_class:
            return  # 课堂内隐藏优先级

        # 遍历全部窗口，检查最大化/全屏
        self._window_states.clear()
        win32gui.EnumWindows(self._enum_windows_callback, None)

        any_maximized = False
        any_fullscreen = False

        if self.app_central.configs.interactions.hide.maximized:
            any_maximized = any(state['maximized'] for state in self._window_states.values())

        if self.app_central.configs.interactions.hide.fullscreen:
            any_fullscreen = any(state['fullscreen'] for state in self._window_states.values())

        new_state = any_maximized or any_fullscreen

        if new_state != self.previous_state:
            self.app_central.configs.interactions.hide.state = new_state
        self.previous_state = new_state

    def _enum_windows_callback(self, hwnd, _):
        if not win32gui.IsWindowVisible(hwnd):
            return True

        class_name = win32gui.GetClassName(hwnd)

        # 排除系统窗口
        if class_name in SYSTEM_WINDOW_CLASSES:
            return True

        try:
            maximized = is_window_maximized(hwnd)
            fullscreen = is_window_fullscreen(hwnd)

            self._window_states[hwnd] = {"maximized": maximized, "fullscreen": fullscreen}
        except Exception as e:
            logger.debug(f"Check window {hwnd} failed: {e}")
        return True

    def on_schedule_changed(self):
        """课程发生变化触发"""
        if not self.app_central.configs.interactions.hide.in_class:  # 未开启设置
            return

        self.app_central.configs.interactions.hide.state = True
