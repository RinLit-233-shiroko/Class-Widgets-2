from pathlib import Path

from PySide6.QtCore import Slot, QCoreApplication

from src.core.directories import QML_PATH
from src.core.plugin import CW2Plugin


META = {
    "id": "builtin.classwidgets.widgets",
    "name": QCoreApplication.translate("Plugins", "Built-in Widgets"),
    "author": "Class Widgets Official",
    "version": "1.0.0",
    "api_version": "*",
    "entry": "widgets.py"
}


class Plugin(CW2Plugin):
    def __init__(self, plugin_api):
        super().__init__(plugin_api)

    def get_widgets_list(self):
        return [
            {
                "widget_id": "classwidgets.currentActivity",
                "name": QCoreApplication.translate("Widgets", "Current Activity"),
                "qml_path": Path(QML_PATH / "widgets" / "currentActivity.qml").as_posix(),
                "backend_obj": self,
            },
            {
                "widget_id": "classwidgets.time",
                "name": QCoreApplication.translate("Widgets", "Time"),
                "qml_path": Path(QML_PATH / "widgets" / "Time.qml").as_posix(),
                "backend_obj": self,
            },
            {
                "widget_id": "classwidgets.eventCountdown",
                "name": QCoreApplication.translate("Widgets", "Event Countdown"),
                "qml_path": Path(QML_PATH / "widgets" / "eventCountdown.qml").as_posix(),
                "backend_obj": self,
            },
            {
                "widget_id": "classwidgets.upcomingActivities",
                "name": QCoreApplication.translate("Widgets", "Upcoming Activities"),
                "qml_path": Path(QML_PATH / "widgets" / "upcomingActivities.qml").as_posix(),
                "backend_obj": self,
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "upcomingActivities.qml").as_posix(),
                "default_settings": {
                    "marquee": True,
                    "max_activities": 5,
                    "full_name": True
                }
            },
            {
                "widget_id": "classwidgets.dynamicNotification",
                "name": QCoreApplication.translate("Widgets", "Dynamic Notification"),
                "qml_path": Path(QML_PATH / "widgets" / "dynamicNotification.qml").as_posix(),
                "backend_obj": self,
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "upcomingActivities.qml").as_posix(),
                "default_settings": {
                    "marquee": True,
                    "max_activities": 5,
                    "full_name": True
                }
            },
        ]

    def on_load(self):
        super().on_load()  # 调用父类的on_load来设置插件上下文
        self.register_widgets()

    def register_widgets(self):
        for widget in self.get_widgets_list():
            self.api.widgets.register(
                widget_id=widget["widget_id"],
                name=widget["name"],
                qml_path=widget["qml_path"],
                backend_obj=widget["backend_obj"],
                settings_qml=widget.get("settings_qml"),
                default_settings=widget.get("default_settings"),
            )

    @Slot(result=dict)
    def getDateTime(self):
        current_time = self.api.runtime.current_time
        return {
            "hour": f"{current_time.hour:02d}",
            "minute": f"{current_time.minute:02d}",
            "second": f"{current_time.second:02d}",
            "year": current_time.year,
            "month": current_time.month,
            "day": current_time.day,
            "weekday": current_time.isoweekday()
        }

    def on_unload(self):
        print("[HelloWorld] Plugin unloaded!")
