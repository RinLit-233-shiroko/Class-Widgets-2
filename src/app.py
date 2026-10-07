import multiprocessing
import os
import sys
import time


def wait_for_process_exit(arguments: list[str]) -> list[str]:
    """Wait for the previous CW2 process before initializing Qt and plugins."""
    if "--wait-for-pid" not in arguments:
        return arguments

    index = arguments.index("--wait-for-pid")
    try:
        pid = int(arguments[index + 1])
    except (IndexError, ValueError):
        return arguments[:index] + arguments[index + 2:]

    remaining = arguments[:index] + arguments[index + 2:]
    if pid == os.getpid():
        return remaining

    while True:
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return remaining
        except PermissionError:
            pass
        time.sleep(0.1)

# Add the project root to Python path (parent directory of src)
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
sys.path.insert(0, project_root)

from src.core import AppCentral
from PySide6.QtWidgets import QApplication

if __name__ == "__main__":
    multiprocessing.freeze_support()
    sys.argv[1:] = wait_for_process_exit(sys.argv[1:])
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    instance = AppCentral()
    try:
        instance.run()
    except Exception as error:
        # 启动流程中 init() 之外的步骤出错时，也要交给崩溃处理：
        # 这样报告窗口能显示，事件循环也仍然会启动。
        instance.crash_handler.report_exception(
            type(error), error, error.__traceback__, source="startup"
        )
    app.exec()
