from PySide6.QtWidgets import QApplication
from src.core import AppCentral
import sys

from src.core.utils import ensure_single_instance

if __name__ == "__main__":
    ensure_single_instance()

    app = QApplication(sys.argv)

    instance = AppCentral()
    instance.run()

    app.exec()
