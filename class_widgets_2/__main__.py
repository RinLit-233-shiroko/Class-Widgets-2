import sys
import os

# Add the project root to Python path (parent directory of src)
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
sys.path.insert(0, project_root)

from class_widgets_2.core import AppCentral
from PySide6.QtWidgets import QApplication


def main():
    app = QApplication(sys.argv)
    instance = AppCentral()
    instance.run()
    app.exec()


if __name__ == "__main__":
    main()