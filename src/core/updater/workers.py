from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING
import platform

import requests
from PySide6.QtCore import QThread, Signal

from src.core.updater.downloader import UpdateDownloader
from src.core.updater.updater import WindowsUpdater

if TYPE_CHECKING:
    from src.core.telemetry import TelemetryService

# UPDATE_URL = "http://localhost:8080/releases.json"
UPDATE_URL = "https://classwidgets.rinlit.cn/2/releases.json"


class CheckUpdateWorker(QThread):
    finished = Signal(str, str, str)  # status, version, url_or_error

    def __init__(
        self,
        channel: str,
        current_version: str,
        *,
        telemetry: TelemetryService | None = None,
    ) -> None:
        super().__init__()
        self.channel = channel
        self.current_version = current_version
        self.url = UPDATE_URL
        self.telemetry = telemetry

    def start(self, url: str | None = None) -> None:
        if url:
            self.url = url
        super().start()

    def run(self) -> None:
        trace = self.telemetry.start_operation("update.check", {
            "component": "update", "stage": "check",
        }) if self.telemetry is not None else None
        status = "internal_error"
        try:
            if not self.url:
                self.url = UPDATE_URL
            resp = requests.get(self.url, timeout=5)
            resp.raise_for_status()
            data = resp.json()
            info = data.get(self.channel)
            if not info:
                if self.telemetry is not None:
                    self.telemetry.capture_failure("update.missing_channel", {
                        "component": "update", "stage": "check",
                    })
                self.finished.emit("Error", "", "Missing channel info")
                return

            version = info.get("version", "")
            sys_name = platform.system().lower()
            url = info.get("url", {}).get(sys_name, "") or ""

            if version != self.current_version:
                self.finished.emit("UpdateAvailable", version, url)
            else:
                self.finished.emit("UpToDate", version, "")
            status = "ok"
        except Exception as e:
            if self.telemetry is not None:
                self.telemetry.capture_failure("update.check", {
                    "component": "update", "stage": "check",
                }, error=e)
            self.finished.emit("Error", "", str(e))
        finally:
            if trace is not None:
                trace.finish(status)


class DownloadWorker(QThread):
    progress = Signal(float, float)
    finished = Signal(bool, str, bool)  # success, error_msg, manual_stop

    def __init__(
        self,
        downloader: UpdateDownloader,
        *,
        telemetry: TelemetryService | None = None,
    ) -> None:
        super().__init__()
        self.downloader = downloader
        self.telemetry = telemetry

    def run(self) -> None:
        trace = self.telemetry.start_operation("update.download", {
            "component": "update", "stage": "download",
        }) if self.telemetry is not None else None
        status = "internal_error"
        try:
            success = self.downloader.download(progress_callback=self.progress.emit)
            if success:
                status = "ok"
                self.finished.emit(True, "", False)
            else:
                status = "cancelled"
                self.finished.emit(False, "Download cancelled or failed.", self.downloader.manual_stop)
        except Exception as e:
            if self.telemetry is not None:
                self.telemetry.capture_failure("update.download", {
                    "component": "update", "stage": "download",
                }, error=e)
            self.finished.emit(False, str(e), False)
        finally:
            if trace is not None:
                trace.finish(status)

    def stop(self, force=False):
        try:
            self.downloader.stop(force)
        except Exception:
            pass


class InstallWorker(QThread):
    finished = Signal(bool, str)  # success, error_msg

    def __init__(
        self,
        updater: WindowsUpdater,
        zip_path: Path,
        target_dir: Path,
        *,
        telemetry: TelemetryService | None = None,
    ) -> None:
        super().__init__()
        self.updater = updater
        self.zip_path = zip_path
        self.target_dir = target_dir
        self.telemetry = telemetry

    def run(self) -> None:
        trace = self.telemetry.start_operation("update.install", {
            "component": "update", "stage": "install",
        }) if self.telemetry is not None else None
        status = "internal_error"

        def before_exit() -> None:
            if trace is not None:
                trace.finish("ok")
            if self.telemetry is not None:
                self.telemetry.shutdown()

        try:
            self.updater.apply_update(self.zip_path, self.target_dir, before_exit=before_exit)
            status = "ok"
            self.finished.emit(True, "")
        except Exception as e:
            if self.telemetry is not None:
                self.telemetry.capture_failure("update.install", {
                    "component": "update", "stage": "install",
                }, error=e)
            self.finished.emit(False, str(e))
        finally:
            if trace is not None:
                trace.finish(status)
