from __future__ import annotations

import shutil
import tempfile
import threading
from pathlib import Path

from PySide6.QtCore import QThread, Signal
from packaging.version import InvalidVersion, Version

from src.core.plaza.client import PlazaClient
from src.core.plugin.archive import (
    PluginArchiveInstaller,
    PluginInstallResult,
)
from src.core.plugin.download import (
    PluginDownloadCancelled,
    PluginDownloadPaused,
    PluginDownloader,
)


class PluginDownloadWorker(QThread):
    """Download one local URL in a worker thread."""

    progress = Signal(float, float, int, int)
    completed = Signal(str)
    failed = Signal(str)
    cancelled = Signal()
    paused = Signal()

    def __init__(self, downloader: PluginDownloader, parent=None):
        super().__init__(parent)
        self.downloader = downloader

    def run(self) -> None:
        try:
            archive_path = self.downloader.download(self.progress.emit)
            self.completed.emit(str(archive_path))
        except PluginDownloadCancelled:
            self.cancelled.emit()
        except PluginDownloadPaused:
            self.paused.emit()
        except Exception as error:
            self.failed.emit(str(error))

    def cancel(self) -> None:
        self.downloader.cancel()

    def pause(self) -> None:
        self.downloader.pause()


class PlazaDownloadWorker(QThread):
    """Resolve a plaza release and download it without touching Qt state."""

    progress = Signal(float, float, int, int)
    pluginResolved = Signal(object)
    completed = Signal(str, object)
    failed = Signal(str)
    cancelled = Signal()
    paused = Signal()

    def __init__(
        self,
        plugin_id: str,
        base_url: str,
        destination: Path,
        *,
        max_size: int = PluginArchiveInstaller.MAX_ARCHIVE_SIZE,
        parent=None,
    ):
        super().__init__(parent)
        self.plugin_id = plugin_id
        self.client = PlazaClient(base_url)
        self.destination = Path(destination)
        self.max_size = max_size
        self._downloader: PluginDownloader | None = None
        self._cancel_event = threading.Event()
        self._pause_event = threading.Event()

    def run(self) -> None:
        try:
            self._raise_if_cancelled()
            self._raise_if_paused()
            plugin = self.client.get_plugin(self.plugin_id, poll=self._poll)
            self.pluginResolved.emit(plugin)
            self._raise_if_cancelled()
            self._raise_if_paused()
            release_url = self.client.release_url(plugin)
            self._raise_if_cancelled()
            self._raise_if_paused()
            self._downloader = PluginDownloader(
                release_url,
                self.destination,
                max_size=self.max_size,
            )
            self._raise_if_cancelled()
            self._raise_if_paused()
            archive_path = self._downloader.download(self.progress.emit)
            self._raise_if_cancelled()
            self.completed.emit(str(archive_path), plugin)
        except PluginDownloadCancelled:
            self.cancelled.emit()
        except PluginDownloadPaused:
            self.paused.emit()
        except Exception as error:
            self.failed.emit(str(error))

    def cancel(self) -> None:
        self._cancel_event.set()
        if self._downloader:
            self._downloader.cancel()

    def pause(self) -> None:
        self._pause_event.set()
        if self._downloader:
            self._downloader.pause()

    def _raise_if_cancelled(self) -> None:
        if self._cancel_event.is_set():
            raise PluginDownloadCancelled()

    def _raise_if_paused(self) -> None:
        if self._pause_event.is_set():
            raise PluginDownloadPaused()

    def _poll(self) -> None:
        self._raise_if_cancelled()
        self._raise_if_paused()


class PluginInstallWorker(QThread):
    """Validate and atomically install one already downloaded archive."""

    completed = Signal(object)
    failed = Signal(str)

    def __init__(
        self,
        archive_path: Path | str,
        installer: PluginArchiveInstaller,
        *,
        expected_plugin_id: str | None = None,
        expected_version: str | None = None,
        replace: bool = True,
        parent=None,
    ):
        super().__init__(parent)
        self.archive_path = Path(archive_path)
        self.installer = installer
        self.expected_plugin_id = expected_plugin_id
        self.expected_version = expected_version
        self.replace = replace

    def run(self) -> None:
        try:
            result = self.installer.install(
                self.archive_path,
                expected_plugin_id=self.expected_plugin_id,
                expected_version=self.expected_version,
                replace=self.replace,
            )
            self.completed.emit(result)
        except Exception as error:
            self.failed.emit(str(error))


class PlazaUpdateWorker(QThread):
    """Check current plaza versions for installed external plugins."""

    completed = Signal(object)

    def __init__(self, records: list[dict], base_url: str, parent=None):
        super().__init__(parent)
        self.records = records
        self.client = PlazaClient(base_url)
        self._cancel_event = threading.Event()

    def run(self) -> None:
        results = []
        for record in self.records:
            if self._cancel_event.is_set():
                return
            plugin_id = str(record.get("id", ""))
            result = {
                "id": plugin_id,
                "latest_version": "",
                "update_available": False,
                "update_error": "",
                "available": False,
            }
            try:
                plugin = self.client.get_plugin(plugin_id, poll=self._raise_if_cancelled)
                result["available"] = True
                latest_version = str(plugin.get("version", ""))
                result["latest_version"] = latest_version
                result["update_available"] = self._is_newer(
                    latest_version,
                    str(record.get("installed_version", "")),
                )
            except Exception as error:
                result["update_error"] = str(error)
            results.append(result)
        self.completed.emit(results)

    def cancel(self) -> None:
        self._cancel_event.set()

    def _raise_if_cancelled(self) -> None:
        if self._cancel_event.is_set():
            raise PluginDownloadCancelled()

    @staticmethod
    def _is_newer(latest: str, installed: str) -> bool:
        try:
            return bool(latest and installed and Version(latest) > Version(installed))
        except InvalidVersion:
            return bool(latest and installed and latest != installed)


def create_plugin_download_directory() -> Path:
    """Create a private temporary directory for a plugin release."""

    return Path(tempfile.mkdtemp(prefix="class-widgets-plugin-"))


def remove_plugin_download_directory(path: Path | None) -> None:
    if path:
        shutil.rmtree(path, ignore_errors=True)
