import platform
import sys

from src import __app_name__
from src.core.storage.directories import SRC_PATH

APP_NAME = __app_name__
APP_SCRIPT = SRC_PATH / "app.py"
APP_PATH = (
    f'"{sys.executable}"' if getattr(sys, "frozen", False) 
    else f'"{sys.executable}" "{APP_SCRIPT}"'
)
IS_WINDOWS = platform.system() == "Windows"

if IS_WINDOWS:
    import winreg


def autostart_supported() -> bool:
    """Check if autostart is supported on this platform"""
    return IS_WINDOWS


def enable_autostart():
    """Enable autostart"""
    if not IS_WINDOWS:
        print("Autostart is only supported on Windows")
        return

    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        print(APP_PATH)
        winreg.SetValueEx(key, APP_NAME, 0, winreg.REG_SZ, APP_PATH)
        key.Close()
        print(f"{APP_NAME} autostart enabled")
    except Exception as e:
        print("Failed to enable autostart:", e)


def disable_autostart():
    """Disable autostart"""
    if not IS_WINDOWS:
        print("Autostart is only supported on Windows")
        return

    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        try:
            winreg.DeleteValue(key, APP_NAME)
            print(f"{APP_NAME} autostart disabled")
        except FileNotFoundError:
            pass
        key.Close()
    except Exception as e:
        print("Failed to disable autostart:", e)


def is_autostart_enabled() -> bool:
    """Check if autostart is enabled"""
    if not IS_WINDOWS:
        return False

    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_READ
        )
        try:
            val = winreg.QueryValueEx(key, APP_NAME)
            return val[0] == APP_PATH
        except FileNotFoundError:
            return False
        finally:
            key.Close()
    except Exception as e:
        print("Failed to check autostart status:", e)
        return False
