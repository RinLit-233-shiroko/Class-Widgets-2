from pathlib import Path

from PySide6.QtCore import Slot

from src.core.directories import QML_PATH
from src.core.plugin import CW2Plugin


class Plugin(CW2Plugin):
    def __init__(self, plugin_api):
        super().__init__(plugin_api)
        self.widgets_list = [
            {
                "widget_id": "classwidgets.currentActivity",
                "name": "Current Activity",
                "qml_path": Path(QML_PATH / "widgets" / "currentActivity.qml").as_posix(),
                "backend_obj": self,
            },
            {
                "widget_id": "classwidgets.time",
                "name": "Time",
                "qml_path": Path(QML_PATH / "widgets" / "Time.qml").as_posix(),
                "backend_obj": self,
            },
            {
                "widget_id": "classwidgets.eventCountdown",
                "name": "Event Countdown",
                "qml_path": Path(QML_PATH / "widgets" / "eventCountdown.qml").as_posix(),
                "backend_obj": self,
            },
            {
                "widget_id": "classwidgets.upcomingActivities",
                "name": "Upcoming Activities",
                "qml_path": Path(QML_PATH / "widgets" / "upcomingActivities.qml").as_posix(),
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
        self.register_widgets()

    def register_widgets(self):
        for widget in self.widgets_list:
            self.api.register_widget(
                widget_id=widget["widget_id"],
                name=widget["name"],
                qml_path=widget["qml_path"],
                backend_obj=widget["backend_obj"],
                settings_qml=widget.get("settings_qml"),
                default_settings=widget.get("default_settings"),
            )

    @Slot(result=dict)
    def getDateTime(self):
        current_time = self.api.get_datetime()
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
