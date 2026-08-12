from __future__ import annotations

from copy import deepcopy

from PySide6.QtCore import QObject, Signal


class PlazaActivityStore(QObject):
    """Keep a small, in-memory history of Plugin Plaza transfers."""

    changed = Signal()

    def __init__(self, *, limit: int = 30, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._limit = limit
        self._entries: list[dict[str, object]] = []

    @property
    def entries(self) -> list[dict[str, object]]:
        return deepcopy(self._entries)

    def start(
        self,
        *,
        plugin_id: str,
        name: str,
        author: str,
        icon: object,
        version: str,
        kind: str,
    ) -> None:
        self._entries.insert(0, {
            "id": plugin_id,
            "name": name or plugin_id,
            "author": author,
            "icon": icon,
            "version": version,
            "kind": kind,
            "status": "Downloading",
            "progress": 0.0,
            "downloaded_bytes": 0,
            "total_bytes": 0,
            "speed": 0.0,
            "error": "",
        })
        del self._entries[self._limit:]
        self.changed.emit()

    def update_metadata(
        self,
        plugin_id: str,
        *,
        name: str,
        author: str,
        icon: object,
        version: str,
    ) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["name"] = name or entry["name"]
        entry["author"] = author
        entry["icon"] = icon
        entry["version"] = version or entry["version"]
        self.changed.emit()

    def set_progress(
        self,
        plugin_id: str,
        progress: float,
        downloaded_bytes: int = 0,
        total_bytes: int = 0,
        speed: float = 0.0,
    ) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["progress"] = progress
        entry["downloaded_bytes"] = downloaded_bytes
        entry["total_bytes"] = total_bytes
        entry["speed"] = speed
        self.changed.emit()

    def set_paused(self, plugin_id: str) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["status"] = "Paused"
        entry["speed"] = 0.0
        self.changed.emit()

    def set_downloading(self, plugin_id: str) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["status"] = "Downloading"
        entry["error"] = ""
        self.changed.emit()

    def set_installing(self, plugin_id: str) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["status"] = "Installing"
        self.changed.emit()

    def complete(self, plugin_id: str, version: str) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["version"] = version or entry["version"]
        entry["status"] = "Installed"
        entry["progress"] = 100.0
        self.changed.emit()

    def fail(self, plugin_id: str, error: str) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["status"] = "Error"
        entry["error"] = error
        self.changed.emit()

    def cancel(self, plugin_id: str) -> None:
        entry = self._active_entry(plugin_id)
        if not entry:
            return
        entry["status"] = "Cancelled"
        entry["progress"] = 0.0
        self.changed.emit()

    def _active_entry(self, plugin_id: str) -> dict[str, object] | None:
        for entry in self._entries:
            if entry["id"] == plugin_id and entry["status"] in {"Downloading", "Paused", "Installing"}:
                return entry
        return None
