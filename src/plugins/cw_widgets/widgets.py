from pathlib import Path

from PySide6.QtCore import Slot, QCoreApplication

from src.core.storage.directories import QML_PATH
from src.core.plugin import CW2Plugin
from .overlay_backend import OverlayBackend


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
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "currentActivity.qml").as_posix(),
                "default_settings": {
                    "display_mode": "alternate",
                    "alternate_interval": 3
                }
            },
            {
                "widget_id": "classwidgets.time",
                "name": QCoreApplication.translate("Widgets", "Time"),
                "qml_path": Path(QML_PATH / "widgets" / "Time.qml").as_posix(),
                "backend_obj": self,
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "Time.qml").as_posix(),
                "default_settings": {
                    "digit_animation": True,
                    "show_seconds": True,
                    "show_date": False,
                    "show_year": True,
                    "show_month": True,
                    "show_day": True,
                    "show_weekday": False,
                    "title_mode": "side_by_side",
                    "alternate_interval": 3000,
                    "alternate_animation": False
                }
            },
            {
                "widget_id": "classwidgets.eventCountdown",
                "name": QCoreApplication.translate("Widgets", "Event Countdown"),
                "qml_path": Path(QML_PATH / "widgets" / "eventCountdown.qml").as_posix(),
                "backend_obj": self,
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "eventCountdown.qml").as_posix(),
                "default_settings": {
                    "digit_animation": True
                }
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
                "backend_obj": self
            },
            {
                "widget_id": "classwidgets.customText",
                "name": QCoreApplication.translate("Widgets", "Text"),
                "qml_path": Path(QML_PATH / "widgets" / "Text.qml").as_posix(),
                "backend_obj": self,
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "Text.qml").as_posix(),
                "default_settings": {
                    "marquee": False,
                    "max_width": 150,
                    "text": ""
                }
            },
            {
                "widget_id": "classwidgets.overlay",
                "name": QCoreApplication.translate("Widgets", "Overlay"),
                "qml_path": Path(QML_PATH / "widgets" / "overlay.qml").as_posix(),
                "backend_obj": self.overlayBackend(),
                "settings_qml": Path(QML_PATH / "widgets" / "settings" / "overlay.qml").as_posix(),
                "default_settings": {
                    "interval_ms": 5000,
                    "lyric_gate": False,
                    "frame_mode": "max",
                    "show_switch_bar": True
                }
            },
        ]

    def overlayBackend(self):
        """堆叠组件的后端（惰性创建，所有实例共用一份）。

        成员选择窗口会直接从这个组件的 backend_obj 上调用 addMember，
        所以这里返回的必须是 OverlayBackend 本身，而不是插件对象。
        """
        if not hasattr(self, "_overlay_backend"):
            self._overlay_backend = OverlayBackend(self)
        return self._overlay_backend

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
