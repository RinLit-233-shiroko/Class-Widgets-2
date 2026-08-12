import json

from PySide6.QtCore import QObject, Signal, Slot, Property
from PySide6.QtNetwork import QNetworkAccessManager, QNetworkRequest, QNetworkReply
from PySide6.QtCore import QUrl, QUrlQuery
from loguru import logger

DEFAULT_PLAZA_URL = "https://plaza.cw.rinlit.cn"


class PlazaBridge(QObject):
    statusChanged = Signal(str)
    bannersChanged = Signal()
    pluginsChanged = Signal()
    errorOccurred = Signal(str)
    baseUrlChanged = Signal()

    def __init__(self, config_manager=None, parent=None):
        super().__init__(parent)
        self._config_manager = config_manager
        self._base_url = self._read_base_url()
        self._status = "Idle"
        self._banners = []
        self._plugins = []
        self._nam = QNetworkAccessManager(self)
        self._pending_replies: list[QNetworkReply] = []
        self._fetching_banners = False
        self._fetching_plugins = False
        if self._config_manager:
            self._config_manager.configChanged.connect(self._on_config_changed)

    def _read_base_url(self):
        url = getattr(getattr(self._config_manager, "network", None), "plaza_url", "")
        return (url or DEFAULT_PLAZA_URL).rstrip("/")

    def _on_config_changed(self):
        base_url = self._read_base_url()
        if base_url != self._base_url:
            self._base_url = base_url
            self.baseUrlChanged.emit()

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

    @Property(str, notify=baseUrlChanged)
    def baseUrl(self):
        return self._base_url

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

    def _read_json_reply(self, reply: QNetworkReply):
        return json.loads(bytes(reply.readAll()).decode("utf-8"))

    def _response_error(self, data, fallback):
        if isinstance(data, dict) and data.get("error"):
            return data.get("error")
        return fallback

    @Slot()
    def fetchBanners(self):
        if self._fetching_banners:
            return
        self._fetching_banners = True
        self._set_status("FetchingBanners")

        url = QUrl(f"{self._base_url}/api/banners")
        query = QUrlQuery()
        query.addQueryItem("name", "home")
        url.setQuery(query)
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
            data = self._read_json_reply(reply)
            if data.get("ok") and "data" in data:
                self._banners = data["data"].get("slides", [])
                self.bannersChanged.emit()
                self._set_status("BannersLoaded")
            else:
                self.errorOccurred.emit(f"Failed to load banners: {self._response_error(data, 'Invalid response format')}")
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

        url = QUrl(f"{self._base_url}/api/plugins")
        query = QUrlQuery()
        query.addQueryItem("page", "1")
        query.addQueryItem("per_page", "50")
        query.addQueryItem("sort", "latest")
        url.setQuery(query)
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
            data = self._read_json_reply(reply)
            if data.get("ok") and "data" in data:
                self._plugins = data["data"]
                self.pluginsChanged.emit()
                self._set_status("PluginsLoaded")
            else:
                self.errorOccurred.emit(f"Failed to load plugins: {self._response_error(data, 'Invalid response format')}")
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
