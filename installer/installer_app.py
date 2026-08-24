from __future__ import annotations

import os
import re
import sys
from pathlib import Path

from PySide6.QtCore import QObject, Property, QProcess, QTimer, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication, QFileDialog

APP_NAME = "Class Widgets 2"
MAIN_EXECUTABLE = "Class Widgets 2.exe"
ENGINE_EXECUTABLE = "ClassWidgets2Engine.exe"
MIGRATION_SOURCE_MARKER = ".cw2-portable-source"


def resource_root() -> Path:
    """Return the PyInstaller extraction root or the source asset directory."""
    return Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parent))


def read_version() -> str:
    metadata_file = resource_root() / "metadata" / "__init__.py"
    try:
        content = metadata_file.read_text(encoding="utf-8")
    except OSError:
        return "2"
    match = re.search(r'^__version__\s*=\s*["\']([^"\']+)["\']', content, re.MULTILINE)
    return match.group(1) if match else "2"


def default_install_path() -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        return Path(local_app_data) / "Programs" / APP_NAME
    return Path.home() / "AppData" / "Local" / "Programs" / APP_NAME


class InstallerBridge(QObject):
    progressChanged = Signal()
    phaseChanged = Signal()
    installingChanged = Signal()
    errorChanged = Signal()
    installationFinished = Signal(bool, str)

    def __init__(self) -> None:
        super().__init__()
        self._resources = resource_root()
        self._target_path = default_install_path()
        self._progress = 0.0
        self._phase = "正在准备安装…"
        self._installing = False
        self._error_text = ""
        self._process: QProcess | None = None
        self._progress_timer = QTimer(self)
        self._progress_timer.setInterval(80)
        self._progress_timer.timeout.connect(self._advance_progress)

    @Property(str, constant=True)
    def defaultInstallPath(self) -> str:
        return str(default_install_path())

    @Property(str, constant=True)
    def logoUrl(self) -> str:
        return QUrl.fromLocalFile(str(self._resources / "assets" / "logo.png")).toString()

    @Property(str, constant=True)
    def version(self) -> str:
        return read_version()

    @Property(float, notify=progressChanged)
    def progress(self) -> float:
        return self._progress

    @Property(str, notify=phaseChanged)
    def phase(self) -> str:
        return self._phase

    @Property(bool, notify=installingChanged)
    def installing(self) -> bool:
        return self._installing

    @Property(str, notify=errorChanged)
    def errorText(self) -> str:
        return self._error_text

    @Slot(str, result=str)
    def chooseInstallPath(self, current_path: str) -> str:
        selected = QFileDialog.getExistingDirectory(
            None,
            "选择 Class Widgets 2 安装位置",
            current_path or str(default_install_path()),
        )
        return selected or ""

    @Slot(str)
    def install(self, target_path: str) -> None:
        if self._installing:
            return

        target = Path(target_path).expanduser()
        if not str(target).strip():
            self._fail("安装路径不能为空。")
            return

        engine_path = self._resources / "payload" / ENGINE_EXECUTABLE
        if not engine_path.is_file():
            self._fail("安装引擎文件缺失，无法继续。")
            return

        self._target_path = target
        self._progress = 0.03
        self._phase = "正在启动安装引擎…"
        self._error_text = ""
        self._installing = True
        self.progressChanged.emit()
        self.phaseChanged.emit()
        self.errorChanged.emit()
        self.installingChanged.emit()

        self._process = QProcess(self)
        self._process.setProgram(str(engine_path))
        self._process.setArguments(
            [
                f"/DIR={target}",
                "/SILENT",
                "/SUPPRESSMSGBOXES",
                "/NOCANCEL",
                "/SP-",
            ]
        )
        self._process.setWorkingDirectory(str(Path(sys.executable).resolve().parent))
        self._process.finished.connect(self._on_install_finished)
        self._process.errorOccurred.connect(self._on_install_error)
        self._process.start()
        self._progress_timer.start()

    @Slot()
    def launchInstalledApplication(self) -> None:
        executable = self._target_path / MAIN_EXECUTABLE
        if executable.is_file():
            QProcess.startDetached(str(executable), [], str(self._target_path))
        QGuiApplication.quit()

    def _advance_progress(self) -> None:
        if not self._installing:
            self._progress_timer.stop()
            return
        if self._progress < 0.28:
            self._progress += 0.018
            self._phase = "正在准备应用文件…"
        elif self._progress < 0.76:
            self._progress += 0.007
            self._phase = "正在部署 Class Widgets…"
        elif self._progress < 0.91:
            self._progress += 0.003
            self._phase = "正在创建快捷方式与卸载信息…"
        self._progress = min(self._progress, 0.91)
        self.progressChanged.emit()
        self.phaseChanged.emit()

    def _on_install_finished(self, exit_code: int, _exit_status: QProcess.ExitStatus) -> None:
        self._progress_timer.stop()
        if exit_code != 0:
            self._fail(f"安装引擎返回错误代码 {exit_code}。")
            return

        try:
            self._target_path.mkdir(parents=True, exist_ok=True)
            (self._target_path / MIGRATION_SOURCE_MARKER).write_text(
                str(Path(sys.executable).resolve().parent),
                encoding="utf-8",
            )
        except OSError as error:
            self._fail(f"安装完成后无法保存迁移信息：{error}")
            return

        self._progress = 1.0
        self._phase = "安装完成。"
        self._installing = False
        self.progressChanged.emit()
        self.phaseChanged.emit()
        self.installingChanged.emit()
        self.installationFinished.emit(True, "")

    def _on_install_error(self, _error: QProcess.ProcessError) -> None:
        if self._process and self._process.state() == QProcess.ProcessState.NotRunning:
            self._fail("安装引擎无法启动。")

    def _fail(self, message: str) -> None:
        self._progress_timer.stop()
        self._installing = False
        self._error_text = message
        self.installingChanged.emit()
        self.errorChanged.emit()
        self.installationFinished.emit(False, message)


def main() -> int:
    application = QApplication(sys.argv)
    application.setApplicationName(APP_NAME)
    application.setWindowIcon(QIcon(str(resource_root() / "assets" / "logo.ico")))

    engine = QQmlApplicationEngine()
    bridge = InstallerBridge()
    bridge.setParent(engine)
    engine.rootContext().setContextProperty("InstallerBridge", bridge)
    engine.load(QUrl.fromLocalFile(str(resource_root() / "qml" / "InstallerWindow.qml")))

    if not engine.rootObjects():
        return 1
    return application.exec()


if __name__ == "__main__":
    raise SystemExit(main())
