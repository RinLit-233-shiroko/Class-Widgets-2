from typing import Optional, TypedDict

from class_widgets_2.core.notification.model import NotificationPayload


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
