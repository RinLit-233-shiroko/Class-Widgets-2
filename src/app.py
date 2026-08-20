import sys
import os

# Add the project root to Python path (parent directory of src)
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
sys.path.insert(0, project_root)

from src.core import AppCentral
from PySide6.QtWidgets import QApplication


if __name__ == "__main__":
    standalone_modes = {
        "--settings-only": "settings",
        "--plugin-plaza-only": "plaza",
        "--settings-plaza": "both",  # 兼容旧的组合启动参数
    }
    selected_mode = next(
        (standalone_modes[arg] for arg in sys.argv[1:] if arg in standalone_modes),
        None,
    )
    if selected_mode:
        # 包内独立入口会调用此模式；不加载桌面 Widget 窗口。
        sys.argv = [arg for arg in sys.argv if arg not in standalone_modes]
        from src.settings_plaza_app import main as settings_plaza_main

        raise SystemExit(settings_plaza_main(selected_mode))

    app = QApplication(sys.argv)
    instance = AppCentral()
    instance.run()
    app.exec()
