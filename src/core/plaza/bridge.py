import requests
from PySide6.QtCore import QObject, Signal, Slot, Property, QThread
from loguru import logger

PLAZA_BASE_URL = "https://plaza.cw.rinlit.cn"


class FetchBannersWorker(QThread):
    finished = Signal(bool, list, str)

    def __init__(self, base_url=PLAZA_BASE_URL):
        super().__init__()
        self.base_url = base_url

    def run(self):
        try:
            url = f"{self.base_url}/api/banners?name=home"
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            data = resp.json()
            if data.get("ok") and "data" in data:
                slides = data["data"].get("slides", [])
                self.finished.emit(True, slides, "")
            else:
                self.finished.emit(False, [], "Invalid response format")
        except Exception as e:
            logger.error(f"Failed to fetch banners: {e}")
            self.finished.emit(False, [], str(e))


class FetchPluginsWorker(QThread):
    finished = Signal(bool, list, str)

    def __init__(self, per_page=50, base_url=PLAZA_BASE_URL):
        super().__init__()
        self.per_page = per_page
        self.base_url = base_url

    def run(self):
        try:
            url = f"{self.base_url}/api/plugins?per_page={self.per_page}"
            resp = requests.get(url, timeout=10)
            resp.raise_for_status()
            data = resp.json()
            if data.get("ok") and "data" in data:
                plugins = data["data"]
                self.finished.emit(True, plugins, "")
            else:
                self.finished.emit(False, [], "Invalid response format")
        except Exception as e:
            logger.error(f"Failed to fetch plugins: {e}")
            self.finished.emit(False, [], str(e))


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
        self._fetch_banners_worker = None
        self._fetch_plugins_worker = None

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
        self._set_status("FetchingBanners")
        if self._fetch_banners_worker and self._fetch_banners_worker.isRunning():
            return

        self._fetch_banners_worker = FetchBannersWorker()
        self._fetch_banners_worker.finished.connect(self._on_banners_finished)
        self._fetch_banners_worker.start()

    def _on_banners_finished(self, success, data, error):
        if success:
            self._banners = data
            self.bannersChanged.emit()
            self._set_status("BannersLoaded")
        else:
            self.errorOccurred.emit(f"Failed to load banners: {error}")
            self._set_status("Error")

    @Slot()
    def fetchPlugins(self):
        self._set_status("FetchingPlugins")
        if self._fetch_plugins_worker and self._fetch_plugins_worker.isRunning():
            return

        self._fetch_plugins_worker = FetchPluginsWorker()
        self._fetch_plugins_worker.finished.connect(self._on_plugins_finished)
        self._fetch_plugins_worker.start()

    def _on_plugins_finished(self, success, data, error):
        if success:
            self._plugins = data
            self.pluginsChanged.emit()
            self._set_status("PluginsLoaded")
        else:
            self.errorOccurred.emit(f"Failed to load plugins: {error}")
            self._set_status("Error")

    @Slot()
    def refreshAll(self):
        self.fetchBanners()
        self.fetchPlugins()
