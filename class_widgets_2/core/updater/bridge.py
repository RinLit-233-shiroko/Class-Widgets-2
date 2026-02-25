import platform
import tempfile
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtWidgets import QApplication
from loguru import logger
from class_widgets_2 import __version__

from .downloader import UpdateDownloader
from .updater import WindowsUpdater
from .workers import CheckUpdateWorker, DownloadWorker, InstallWorker


class UpdaterBridge(QObject):
    # --- QML 信号 ---
    statusChanged = Signal(str)
    progressChanged = Signal(float, float)
    errorDetailsChanged = Signal(str)
    updateAvailable = Signal(str, str)
    installReady = Signal(str)
    errorOccurred = Signal(str)

    def __init__(self, app_central, parent=None):
        super().__init__(parent)
        self.app_central = app_central
        self.configs = app_central.configs

        self.temp_dir = Path(tempfile.gettempdir()) / "cw2_update"
        self._status = "Idle"
        self._progress = 0.0
        self._speed = 0.0
        self._error_details = ""

        self._check_worker = None
        self._download_worker = None
        self._downloader = None

        self._latest_version = ""
        self._latest_url = ""
        self._downloaded_file = None

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Property(float, notify=progressChanged)
    def progress(self):
        return self._progress

    @Property(float, notify=progressChanged)
    def speed(self):
        return self._speed

    @Property(str, notify=errorDetailsChanged)
    def errorDetails(self):
        return self._error_details

    def _set_status(self, s):
        if self._status != s:
            self._status = s
            self.statusChanged.emit(s)
            # logger.info(f"[UpdaterBridge] Status -> {s}")

    def _set_progress(self, percent, speed):
        self._progress = max(0.0, min(100.0, percent))
        self._speed = speed
        self.progressChanged.emit(percent, speed)

    def _set_error(self, msg):
        self._error_details = msg
        self.errorDetailsChanged.emit(msg)
        self.errorOccurred.emit(msg)
        logger.error(f"[UpdaterBridge] {msg}")

    def update_complete(self):
        if self.temp_dir.exists():
            try:
                import shutil
                shutil.rmtree(self.temp_dir)
                logger.info("Temporary directory removed.")
            except FileNotFoundError:
                pass
            except Exception as e:
                logger.warning(f"Failed to remove temporary directory: {e}")
        text_template = QApplication.translate(
            "UpdateNotification", "Class Widgets has been updated to the latest version: {version}"
        )

        self.app_central.tray_icon.push_up_to_date_notification(
            title=QApplication.translate("UpdateNotification", "Update Completed ヾ(≧▽≦*)o"),
            text=text_template.format(version=__version__),
        )

    @Slot()
    def checkUpdate(self):
        """检查更新：所有平台通用"""
        self._set_status("Checking")
        channel = self.configs.app.channel
        current_version = self.configs.app.version

        if self._check_worker and self._check_worker.isRunning():
            self._check_worker.terminate()

        self._check_worker = CheckUpdateWorker(channel, current_version)
        self._check_worker.finished.connect(self._on_check_finished)
        self._check_worker.start(self.app_central.configs.network.releases_url)

    def _on_check_finished(self, status, version, url_or_err):
        if status == "Error":
            self._set_status("Error")
            self._set_error(f"Check update failed: {url_or_err}")
            return

        if status == "UpdateAvailable":
            self._latest_version = version
            self._latest_url = url_or_err
            self._set_status("UpdateAvailable")
            self.updateAvailable.emit(version, url_or_err)
        else:
            self._set_status("UpToDate")

    @Slot()
    def startDownload(self):
        """仅 Windows 支持下载"""
        if platform.system().lower() != "windows":
            self._set_status("UnsupportedPlatform")
            return

        if not self._latest_url:
            self._set_status("Error")
            self._set_error("No download URL available.")
            return

        if self._download_worker and self._download_worker.isRunning():
            try:
                self._download_worker.stop()
                self._download_worker.wait(500)
            except Exception:
                pass
            self._download_worker = None
            self._downloader = None

        self._set_status("Downloading")
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        self._downloaded_file = self.temp_dir / "update.zip"

        self._downloader = UpdateDownloader(self._latest_url, self._downloaded_file, self.app_central.configs)
        self._download_worker = DownloadWorker(self._downloader)
        self._download_worker.progress.connect(self._set_progress)
        self._download_worker.finished.connect(self._on_download_finished)
        self._download_worker.start()

    def _on_download_finished(self, success: bool, msg: str, manual_stop: bool = False):
        if not success:
            if manual_stop:
                self._set_status("Idle")
            else:
                self._set_status("Error")
                self._set_error(msg)
            return

        self.app_central.tray_icon.push_notification(
            title=QApplication.translate("UpdateNotification", "Update Downloaded"),
            text=QApplication.translate(
                "UpdateNotification",
                "Ready to install anytime. Go to \"Settings\" → \"Update\" to proceed with installation."
            )
        )

        self._set_status("Downloaded")
        self.installReady.emit(self._latest_version)

    @Slot()
    def stopDownload(self):
        self._set_progress(0.0, 0.0)
        if self._download_worker and self._download_worker.isRunning():
            self._download_worker.stop(force=True)
            self._download_worker.wait(500)
        if self._downloader:
            try:
                self._downloader.stop()
            except Exception as e:
                logger.warning(f"Failed to stop download: {e}")

    @Slot()
    def startInstall(self):
        if not self._downloaded_file or not self._downloaded_file.exists():
            self._set_status("Error")
            self._set_error("Downloaded file not found.")
            return

        self._set_status("Installing")
        self._install_worker = InstallWorker(
            WindowsUpdater(self.temp_dir),
            self._downloaded_file,
            Path.cwd()
        )
        self._install_worker.finished.connect(self._on_install_finished)
        self._install_worker.start()

    def _on_install_finished(self, success, msg):
        if success:
            self._set_status("Installed")
            self.app_central.tray_icon.push_notification(
                title=QApplication.translate("UpdateNotification", "Applying Update Soon"),
                text=QApplication.translate(
                    "UpdateNotification", "The update may take several seconds to complete. (●'◡'●)"
                )
            )
            self.app_central.restart()
        else:
            self._set_status("Error")
            self._set_error(f"Install failed: {msg}")

