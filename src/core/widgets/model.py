import uuid
from typing import List, Dict, Union
from PySide6.QtCore import QAbstractListModel, Qt, QModelIndex, QUrl, Signal, Property, Slot, QObject
from loguru import logger

from src.core.config.model import WidgetEntry


class WidgetListModel(QAbstractListModel):
    InstanceIdRole = Qt.UserRole + 1
    TypeIdRole = Qt.UserRole + 2
    NameRole = Qt.UserRole + 3
    IconRole = Qt.UserRole + 4
    QmlPathRole = Qt.UserRole + 5
    BackendRole = Qt.UserRole + 6
    SettingsRole = Qt.UserRole + 7
    SettingsQmlRole = Qt.UserRole + 8

    modelChanged = Signal()
    definitionChanged = Signal()

    def __init__(self, app_central=None):
        super().__init__()
        self._app_central = app_central
        self._definitions: Dict[str, dict] = {}
        self._instances: List[dict] = []
        self._presets: Dict[str, List[WidgetEntry]] = {}
        self._current_preset: str = ""

        self.modelChanged.connect(self.save_config)

    def roleNames(self):
        return {
            self.InstanceIdRole: b"instanceId",
            self.TypeIdRole: b"typeId",
            self.NameRole: b"name",
            self.IconRole: b"icon",
            self.QmlPathRole: b"qmlPath",
            self.BackendRole: b"backendObj",
            self.SettingsRole: b"settings",
            self.SettingsQmlRole: b"settingsQml",
        }

    def rowCount(self, parent=QModelIndex()):
        return len(self._instances)

    def data(self, index, role):
        if not index.isValid() or index.row() >= len(self._instances):
            return None
        w = self._instances[index.row()]
        if role == self.InstanceIdRole:
            return w.get("instance_id", "")
        if role == self.TypeIdRole:
            return w.get("type_id", "")
        if role == self.NameRole:
            return w.get("name", "")
        if role == self.IconRole:
            return w.get("icon", "")
        if role == self.QmlPathRole:
            return w.get("qml_path", "")
        if role == self.BackendRole:
            return w.get("backend_obj", None)
        if role == self.SettingsRole:
            return w.get("settings", {})
        if role == self.SettingsQmlRole:
            return w.get("settings_qml", self._definitions.get(w.get("type_id", ""), {}).get("settings_qml", ""))
        return None

    def _normalize_preset_entries(self, entries: List[Union[str, dict, WidgetEntry]]) -> List[WidgetEntry]:
        normalized = []
        for e in entries:
            if isinstance(e, WidgetEntry):
                normalized.append(e)
            elif isinstance(e, dict):
                normalized.append(WidgetEntry(
                    type_id=e["type_id"],
                    instance_id=e.get("instance_id", str(uuid.uuid4())),
                    settings=e.get("settings", {})
                ))
            elif isinstance(e, str):
                normalized.append(WidgetEntry(
                    type_id=e,
                    instance_id=str(uuid.uuid4())
                ))
        return normalized

    def load_config(self):
        if not self._app_central:
            logger.warning("Cannot load widget presets: AppCentral not available")
            return
        raw_presets = self._app_central.configs.preferences.widgets_presets or {}
        self._presets = {name: self._normalize_preset_entries(entries) for name, entries in raw_presets.items()}
        current_preset = self._app_central.configs.preferences.current_preset or ""
        if current_preset:
            self.load_preset(current_preset)

    def save_config(self):
        if not self._app_central:
            logger.warning("Cannot save widget presets: AppCentral not available")
            return
        # 保存时直接赋值 WidgetEntry 列表，Pydantic 可以处理
        self._app_central.configs.preferences.widgets_presets = self.presets
        self._app_central.configs.preferences.current_preset = self._current_preset
        logger.info("Widget presets saved")

    def syncCurrentPreset(self):
        """同步当前 _instances 到 _presets"""
        if not self._current_preset:
            return
        self._presets[self._current_preset] = [
            WidgetEntry(
                type_id=w["type_id"],
                instance_id=w["instance_id"],
                settings=dict(w.get("settings", {}))
            )
            for w in self._instances
        ]

    @Slot(str, list)
    def updatePreset(self, preset_name: str, enabled_entries: list):
        self._presets[preset_name] = self._normalize_preset_entries(enabled_entries)
        if self._current_preset == preset_name:
            self.load_preset(preset_name)
        self.modelChanged.emit()

    @Slot(str, list)
    def set_preset(self, preset_name: str, entries: list):
        self._presets[preset_name] = self._normalize_preset_entries(entries)

    @Slot(str)
    def load_preset(self, preset_name: str):
        if preset_name not in self._presets:
            return
        entries = self._presets[preset_name]
        new_instances = []
        for entry in entries:
            type_id = entry.type_id
            if type_id not in self._definitions:
                continue
            definition = self._definitions[type_id]
            instance = dict(definition)
            instance["instance_id"] = entry.instance_id or str(uuid.uuid4())
            instance["type_id"] = type_id
            base_settings = dict(definition.get("default_settings", {}))
            base_settings.update(entry.settings or {})
            instance["settings"] = base_settings
            # 保留 backend_obj 给 QML 使用
            if "backend_obj" in definition:
                instance["backend_obj"] = definition["backend_obj"]
            new_instances.append(instance)

        self.beginResetModel()
        self._instances = new_instances
        self._current_preset = preset_name
        self.endResetModel()
        self.modelChanged.emit()

    def add_widget(
            self,
            type_id: str,
            name: str,
            qml_path: str | QUrl,
            backend_obj: QObject | None = None,
            settings_qml: str | QUrl = None,
            default_settings: dict | None = None
    ):
        if not type_id:
            logger.warning(f"Cannot register widget: Invalid type_id \"{type_id}\"")
            return

        definition = {
            "id": type_id,
            "name": name,
            "qml_path": QUrl.fromLocalFile(qml_path).toString() if qml_path else "",
            "backend_obj": backend_obj,
            "settings_qml": settings_qml if isinstance(settings_qml, QUrl) else (
                QUrl.fromLocalFile(settings_qml).toString() if settings_qml else ""),
            "default_settings": default_settings or {}
        }

        # 如果 widget 已存在，更新其名称（用于翻译更新）
        if type_id in self._definitions:
            self._definitions[type_id]["name"] = name
            logger.debug(f"Updated widget name for {type_id}: {name}")
        else:
            self._definitions[type_id] = definition
        
        self.definitionChanged.emit()

    @Slot(str)
    def addInstance(self, type_id: str):
        if type_id not in self._definitions:
            return
        definition = self._definitions[type_id]
        instance = dict(definition)
        instance["instance_id"] = str(uuid.uuid4())
        instance["type_id"] = type_id
        base_settings = dict(definition.get("default_settings", {}))
        instance["settings"] = base_settings
        if "backend_obj" in definition:
            instance["backend_obj"] = definition["backend_obj"]
        self.beginInsertRows(QModelIndex(), len(self._instances), len(self._instances))
        self._instances.append(instance)
        self.endInsertRows()
        self.syncCurrentPreset()
        self.modelChanged.emit()

    @Slot(int, int)
    def moveInstance(self, from_index: int, to_index: int):
        if from_index == to_index or from_index < 0 or to_index < 0 or from_index >= len(
                self._instances) or to_index >= len(self._instances):
            return
        self.beginMoveRows(QModelIndex(), from_index, from_index, QModelIndex(),
                           to_index if to_index < from_index else to_index + 1)
        w = self._instances.pop(from_index)
        self._instances.insert(to_index, w)
        self.endMoveRows()
        self.syncCurrentPreset()
        self.modelChanged.emit()

    @Slot(str)
    def removeInstance(self, instance_id: str):
        for i, w in enumerate(self._instances):
            if w.get("instance_id") == instance_id:
                self.beginRemoveRows(QModelIndex(), i, i)
                self._instances.pop(i)
                self.endRemoveRows()
                self.syncCurrentPreset()
                self.modelChanged.emit()
                return

    @Slot(str, dict)
    def updateSettings(self, instance_id: str, settings: dict):
        for i, w in enumerate(self._instances):
            if w.get("instance_id") == instance_id:
                w_settings = w.get("settings", {})
                w_settings.update(settings)
                w["settings"] = w_settings
                ix = self.index(i)
                self.dataChanged.emit(ix, ix, [self.SettingsRole])
                self.syncCurrentPreset()
                self.modelChanged.emit()
                return

    @Property(str, notify=modelChanged)
    def currentPreset(self):
        return self._current_preset

    @Property(dict, notify=modelChanged)
    def presets(self):
        return self._presets

    @Property(dict, notify=definitionChanged)
    def definitions(self):
        return self._definitions

    @Property('QVariantList', notify=definitionChanged)
    def definitionsList(self):
        return list(self._definitions.values())
