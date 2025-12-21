from enum import Enum
from typing import Union
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot

from src.core.schedule.model import EntryType


class NotificationLevel(Enum):
    INFO = 0  # 插件推送等一般消息
    ANNOUNCEMENT = 1  # 上下课提醒...
    WARNING = 2  # 比如软件更新
    SYSTEM = 3  # 内部使用


class Notification(QObject):
    notify = Signal(str, int, str, str)  # icon, level, title, message

    def __init__(self):
        super().__init__()

    def push_activity(self, entry_type, subject: dict, event_title):
        sub_title = event_title if event_title else subject.get("name")
        title = self.tr("Class begins") if entry_type in [EntryType.ACTIVITY.value, EntryType.CLASS.value] else \
            self.tr("School is over") if entry_type == EntryType.FREE.value else self.tr("Class is over")
        message: str = sub_title if entry_type in [EntryType.ACTIVITY.value, EntryType.CLASS.value] else None

        self.push(icon="ic_fluent_alert_20_regular", level=NotificationLevel.INFO, title=title, message=message)

    @Slot(str, int, str, str)
    def push(self, icon: Union[str, Path], level: NotificationLevel, title: str, message: str):
        """
        Push a notification to the Class Widgets.
        :param icon: str or Path, icon name or path: "ic_fluent_symbols_20_regular" or Path("path/to/icon.png")
        :param level:
        :param title:
        :param message:
        :return:
        """
        level = level.value if type(level) is Enum else level
        self.notify.emit(icon, level, title, message)
