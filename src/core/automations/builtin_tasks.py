from __future__ import annotations

from typing import TYPE_CHECKING

from loguru import logger

from .base import AutomationTask
from ..schedule import EntryType
from ..config.model import TapAction

import platform

if TYPE_CHECKING:
    from src.core.central import AppCentral

IS_WINDOWS = platform.system() == "Windows"

if IS_WINDOWS:
    import win32gui
    import win32con
    import ctypes

    SYSTEM_WINDOW_CLASSES = {
        "Progman",  # 桌面
        "Shell_TrayWnd",  # 任务栏
        "Windows.UI.Core.CoreWindow",  # 输入体验等
    }

    def is_window_maximized(hwnd) -> bool:
        placement = win32gui.GetWindowPlacement(hwnd)
        return placement[1] == win32con.SW_MAXIMIZE

    def is_window_fullscreen(hwnd) -> bool:
        if not win32gui.IsWindowVisible(hwnd):
            return False
        # A standard maximized window can have the same bounds as the monitor,
        # but borderless fullscreen applications may also report SW_MAXIMIZE.
        style = win32gui.GetWindowLong(hwnd, win32con.GWL_STYLE)
        has_standard_frame = style & (win32con.WS_CAPTION | win32con.WS_THICKFRAME)
        if is_window_maximized(hwnd) and has_standard_frame:
            return False
        rect = win32gui.GetWindowRect(hwnd)
        screen_width = ctypes.windll.user32.GetSystemMetrics(0)
        screen_height = ctypes.windll.user32.GetSystemMetrics(1)
        margin = 2
        return rect[0] <= margin and rect[1] <= margin and rect[2] >= screen_width - margin and rect[3] >= screen_height - margin


class AutoHideTask(AutomationTask):
    def __init__(self, app_central: "AppCentral") -> None:
        super().__init__(app_central)

        self.runtime = app_central.runtime
        self.runtime.currentsChanged.connect(self.on_schedule_changed)

        self._window_states: dict[int, dict[str, bool]] = {}
        self.previous_state: bool = False
        self._fullscreen_window: int | None = None
        self._os_hiding: bool = False  # 当前是否因最大化/全屏而被自动隐藏
        
        # Check initial state on startup
        if self.app_central.configs.interactions.hide.in_class:
            self.on_schedule_changed(self.runtime.current_status)

        # Check initial maximize/fullscreen state on startup
        self.update()

    def _subject_name(self, entry) -> str:
        """取条目对应的课程名称（用于豁免名单匹配）。"""
        if entry is None:
            return ""
        subject_id = getattr(entry, "subjectId", None)
        name = ""
        if subject_id:
            try:
                schedule = getattr(self.runtime, "schedule", None)
                subjects = getattr(schedule, "subjects", None) if schedule else None
                if subjects:
                    subject = self.runtime.services.get_subject(subject_id, subjects)
                    if subject:
                        name = getattr(subject, "name", None) or ""
                        if not name:
                            name = getattr(subject, "simplifiedName", None) or ""
            except Exception as e:
                logger.debug(f"Failed to resolve subject name: {e}")
        if not name:
            name = getattr(entry, "title", None) or ""
        return name

    def _is_exempt(self, entry) -> bool:
        """该课程是否在“不自动隐藏”豁免名单（按课程名称）。"""
        if entry is None:
            return False
        names = self.app_central.configs.interactions.hide.no_hide_subjects or []
        if not names:
            return False
        return self._subject_name(entry) in names

    def _hide(self, state: bool) -> None:
        """隐藏窗口"""
        action = self.app_central.configs.interactions.hide.action
        if action == TapAction.MINI_MODE:  # mini模式
            # if not self.app_central.configs.isKeyLocked("preferences.mini_mode"):
            self.app_central.configs.preferences.mini_mode = state
        elif action in (TapAction.HIDE, TapAction.FLOATING_WIDGET):
            # if not self.app_central.configs.isKeyLocked("interactions.hide.state"):
            self.app_central.configs.interactions.hide.state = state

    def update(self) -> None:
        """主循环"""
        if (not self.app_central.configs.interactions.hide.maximized
                and not self.app_central.configs.interactions.hide.fullscreen):
            return

        if (self.app_central.configs.interactions.hide.in_class and (
                self.app_central.runtime.current_status == EntryType.CLASS
                or self.app_central.runtime.current_status == EntryType.ACTIVITY)):
            return  # 课堂内隐藏优先级

        any_maximized = False
        any_fullscreen = False

        if self.app_central.configs.interactions.hide.maximized:
            # Maximum state is global and still checks all visible windows.
            self._window_states.clear()
            win32gui.EnumWindows(self._enum_windows_callback, None)

        if self.app_central.configs.interactions.hide.maximized:
            any_maximized = any(state['maximized'] for state in self._window_states.values())

        if self.app_central.configs.interactions.hide.fullscreen:
            foreground_window = win32gui.GetForegroundWindow()
            try:
                class_name = win32gui.GetClassName(foreground_window)
                if class_name not in SYSTEM_WINDOW_CLASSES:
                    if is_window_fullscreen(foreground_window):
                        self._fullscreen_window = foreground_window

                # Moving focus to another window does not make the fullscreen
                # window leave fullscreen. Clear the state only when the
                # tracked window actually leaves fullscreen or disappears.
                if self._fullscreen_window is not None:
                    if is_window_fullscreen(self._fullscreen_window):
                        any_fullscreen = True
                    else:
                        self._fullscreen_window = None
            except Exception as e:
                logger.debug(f"Check foreground window {foreground_window} failed: {e}")

        new_state = any_maximized or any_fullscreen

        if new_state != self.previous_state:
            self._hide(new_state)
            self._os_hiding = new_state
        self.previous_state = new_state

    def _enum_windows_callback(self, hwnd: int, _) -> bool:
        if not win32gui.IsWindowVisible(hwnd):
            return True

        class_name = win32gui.GetClassName(hwnd)

        # 排除系统窗口
        if class_name in SYSTEM_WINDOW_CLASSES:
            return True

        try:
            maximized = is_window_maximized(hwnd)
            fullscreen = is_window_fullscreen(hwnd)

            self._window_states[hwnd] = {"maximized": maximized, "fullscreen": fullscreen, "name": class_name}
        except Exception as e:
            logger.debug(f"Check window {hwnd} failed: {e}")
        return True

    def on_schedule_changed(self, current_type: EntryType) -> None:
        """课程发生变化触发"""
        cfg = self.app_central.configs.interactions.hide
        if not cfg.in_class:  # 未开启设置
            return

        hide_now = current_type == EntryType.CLASS or current_type == EntryType.ACTIVITY
        # 豁免课程（按名称）：上课期间不自动隐藏；若正被隐藏则恢复显示。
        # 若隐藏由全屏/最大化触发，则不强行恢复。
        if hide_now and cfg.action == TapAction.HIDE and not self._os_hiding \
                and self._is_exempt(self.runtime.current_entry):
            cfg.state = False
            return

        self._hide(hide_now)
