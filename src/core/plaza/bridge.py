import json

from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkRequest, QNetworkReply
from PySide6.QtCore import QUrl
from loguru import logger

PLAZA_BASE_URL = "https://plaza.cw.rinlit.cn"


class PlazaBridge(QObject):
    statusChanged = Signal(str)
    bannersChanged = Signal()
    pluginsChanged = Signal()
    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._status = "Idle"
        self._banners = []
        self._plugins = []
        self._nam = QNetworkAccessManager(self)
        self._pending_replies: list[QNetworkReply] = []
        self._fetching_banners = False
        self._fetching_plugins = False

    def shutdown(self):
        """Clean up all pending network requests."""
        for reply in self._pending_replies:
            if reply.isRunning():
                reply.abort()
            reply.deleteLater()
        self._pending_replies.clear()
        self._fetching_banners = False
        self._fetching_plugins = False
        self._set_status("Idle")

    @Property(str, notify=statusChanged)
    def status(self):
        return self._status

    @Property(list, notify=bannersChanged)
    def banners(self):
        return self._banners

    @Property(list, notify=pluginsChanged)
    def plugins(self):
        return self._plugins

    def _set_status(self, s):
        if self._status != s:
            self._status = s
            self.statusChanged.emit(s)

    @Slot()
    def fetchBanners(self):
        if self._fetching_banners:
            return
        self._fetching_banners = True
        self._set_status("FetchingBanners")

        url = QUrl(f"{PLAZA_BASE_URL}/api/banners?name=home")
        request = QNetworkRequest(url)
        request.setTransferTimeout(10000)
        reply = self._nam.get(request)
        self._pending_replies.append(reply)
        reply.finished.connect(lambda: self._on_banners_finished(reply))

    def _on_banners_finished(self, reply: QNetworkReply):
        self._pending_replies.remove(reply)
        self._fetching_banners = False

        if reply.error() != QNetworkReply.NoError:
            error_msg = reply.errorString()
            logger.error(f"Failed to fetch banners: {error_msg}")
            self.errorOccurred.emit(f"Failed to load banners: {error_msg}")
            self._set_status("Error")
            reply.deleteLater()
            return

        try:
            data = json.loads(bytes(reply.readAll()).decode("utf-8"))
            if data.get("ok") and "data" in data:
                self._banners = data["data"].get("slides", [])
                self.bannersChanged.emit()
                self._set_status("BannersLoaded")
            else:
                self.errorOccurred.emit("Failed to load banners: Invalid response format")
                self._set_status("Error")
        except Exception as e:
            logger.error(f"Failed to parse banners: {e}")
            self.errorOccurred.emit(f"Failed to load banners: {e}")
            self._set_status("Error")
        finally:
            reply.deleteLater()

    @Slot()
    def fetchPlugins(self):
        if self._fetching_plugins:
            return
        self._fetching_plugins = True
        self._set_status("FetchingPlugins")

        url = QUrl(f"{PLAZA_BASE_URL}/api/plugins?per_page=50")
        request = QNetworkRequest(url)
        request.setTransferTimeout(10000)
        reply = self._nam.get(request)
        self._pending_replies.append(reply)
        reply.finished.connect(lambda: self._on_plugins_finished(reply))

    def _on_plugins_finished(self, reply: QNetworkReply):
        self._pending_replies.remove(reply)
        self._fetching_plugins = False

        if reply.error() != QNetworkReply.NoError:
            error_msg = reply.errorString()
            logger.error(f"Failed to fetch plugins: {error_msg}")
            self.errorOccurred.emit(f"Failed to load plugins: {error_msg}")
            self._set_status("Error")
            reply.deleteLater()
            return

        try:
            data = json.loads(bytes(reply.readAll()).decode("utf-8"))
            if data.get("ok") and "data" in data:
                self._plugins = data["data"]
                self.pluginsChanged.emit()
                self._set_status("PluginsLoaded")
            else:
                self.errorOccurred.emit("Failed to load plugins: Invalid response format")
                self._set_status("Error")
        except Exception as e:
            logger.error(f"Failed to parse plugins: {e}")
            self.errorOccurred.emit(f"Failed to load plugins: {e}")
            self._set_status("Error")
        finally:
            reply.deleteLater()

    @Slot()
    def refreshAll(self):
        self.fetchBanners()
        self.fetchPlugins()