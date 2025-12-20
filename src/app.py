from PySide6.QtWidgets import QApplication
from PySide6.QtGui import QGuiApplication
from PySide6.QtCore import Qt
from src.core import AppCentral
import sys

from src.core.utils import ensure_single_instance

if __name__ == "__main__":
    QGuiApplication.setAttribute(Qt.AA_EnableHighDpiScaling)
    QGuiApplication.setAttribute(Qt.AA_UseHighDpiPixmaps)

    ensure_single_instance()

    app = QApplication(sys.argv)

    instance = AppCentral()
    instance.run()

    app.exec()
