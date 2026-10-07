from dataclasses import dataclass
from pathlib import Path
from typing import NotRequired, Optional, TypedDict

from PySide6.QtCore import QUrl

from src.core.notification.model import NotificationPayload


@dataclass(frozen=True)
class PluginLoadFailure:
    """一个插件在扫描/加载阶段失败的原因。

    以前这些失败只写日志，插件就这么“消失”了：用户看不到，排查也没线索。
    现在统一收集，交给通知和崩溃归因使用。
    """

    plugin_id: str
    name: str = ""
    stage: str = ""
    error: str = ""

    @property
    def display_name(self) -> str:
        return self.name or self.plugin_id


class PluginNotificationPayload(NotificationPayload):
    """插件通知信号负载。"""


class RuntimeMetaPayload(TypedDict):
    id: str
    version: int
    maxWeekCycle: int
    startDate: str


class RuntimeEntryPayload(TypedDict):
    id: str
    type: str
    startTime: str
    endTime: str
    subjectId: Optional[str]
    title: Optional[str]


class RuntimeEntryChangedPayload(TypedDict, total=False):
    """RuntimeAPI.entryChanged 的负载（允许空字典表示无当前课程）。"""
    id: str
    type: str
    startTime: str
    endTime: str
    subjectId: Optional[str]
    title: Optional[str]


class RuntimeSubjectPayload(TypedDict):
    id: str
    name: str
    simplifiedName: Optional[str]
    teacher: Optional[str]
    icon: Optional[str]
    color: Optional[str]
    location: Optional[str]
    isLocalClassroom: bool


class RuntimeRemainingTimePayload(TypedDict):
    minute: int
    second: int


class SettingsPagePayload(TypedDict):
    id: str
    page: str
    title: str
    icon: str


class ShortcutPayload(TypedDict):
    id: str
    name: str
    icon: str
    iconIsSource: bool
    owner: str


class ApplicationInfoPayload(TypedDict):
    name: str
    version: str
    channel: str
    pluginApiVersion: str
    platform: str


class DiagnosticLogPayload(TypedDict):
    time: str
    level: str
    message: str


class PluginMeta(TypedDict, total=False):
    id: str
    name: str
    version: str
    api_version: str
    entry: str
    author: str
    icon: str | QUrl
    _type: str
    _class: type
    _path: Optional[Path]
    _compatible: bool


class PluginConflict(TypedDict):
    id: str
    name: str
    version: str
    existing_version: str
    meta: dict
    zip_path: NotRequired[str]


class PluginImportResult(TypedDict):
    new_plugins: list[str]
    updated_plugins: list[str]
    all_imported: list[str]
