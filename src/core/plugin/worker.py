from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import QThread, Signal, Slot

from src.core.plugin.archive import PluginArchiveInstaller


class PluginImportWorker(QThread):
    """Compatibility worker for the existing local-import API.

    Archive installation is delegated to ``PluginArchiveInstaller``. The
    manager owns scanning and therefore no manager callback is invoked here.
    """

    completed = Signal(object)
    error = Signal(str)

    def __init__(self, zip_path, external_path, scan_func=None, metas_ref=None):
        super().__init__()
        self.zip_path = Path(zip_path)
        self.installer = PluginArchiveInstaller(Path(external_path))

    @Slot()
    def run(self):
        try:
            result = self.installer.install(self.zip_path)
            self.completed.emit(result)
        except Exception as error:
            self.error.emit(str(error))
