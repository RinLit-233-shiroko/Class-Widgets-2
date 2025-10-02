from PySide6.QtWidgets import QApplication
from RinUI import RinUIWindow

from src.core import QML_PATH


class DebuggerWindow(RinUIWindow):
    def __init__(self, instance):
        super().__init__()

        self.engine.rootContext().setContextProperty("AppCentral", instance)
        self.engine.rootContext().setContextProperty("UtilsBackend", instance.utils_backend)

        self.engine.addImportPath(QML_PATH)
        self.load(QML_PATH / "debugger" / "MainWindow.qml")


if __name__ == "__main__":
    app = QApplication()
    # central = DebuggerCentral(None)
    window = DebuggerWindow(None)
    # es_window = EditScheduleWindow(None)
    app.exec()
