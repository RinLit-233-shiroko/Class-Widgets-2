import sys
import os

# Add the project root to Python path (parent directory of src)
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
sys.path.insert(0, project_root)

from src.core import AppCentral
from PySide6.QtWidgets import QApplication


if __name__ == "__main__":
    if "--settings-plaza" in sys.argv:
        # 包内启动器会调用此模式；它只启动设置与插件中心，不加载桌面 Widget。
        sys.argv.remove("--settings-plaza")
        from src.settings_plaza_app import main as settings_plaza_main

        raise SystemExit(settings_plaza_main())

    app = QApplication(sys.argv)
    instance = AppCentral()
    instance.run()
    app.exec()
