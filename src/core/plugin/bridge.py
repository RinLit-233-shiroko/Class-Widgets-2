from PySide6.QtCore import QObject, Slot
from loguru import logger


class PluginBackendBridge(QObject):
    _registry: dict[str, QObject] = {}

    @Slot(str, result=QObject)
    def get_backend(self, plugin_id: str):
        return self._registry.get(plugin_id)

    @classmethod
    def register_backend(cls, plugin_id: str, backend_obj: QObject):
        cls._registry[plugin_id] = backend_obj
        logger.debug(f"Registered backend for plugin {plugin_id}")
