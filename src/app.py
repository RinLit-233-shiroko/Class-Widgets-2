import sys
import os

# Add the project root to Python path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from core import AppCentral
from PySide6.QtWidgets import QApplication

if __name__ == "__main__":
    app = QApplication(sys.argv)
    instance = AppCentral()
    instance.run()
    app.exec()