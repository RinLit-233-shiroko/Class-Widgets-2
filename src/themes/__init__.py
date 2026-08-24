# Built-in themes definition
from PySide6.QtCore import QCoreApplication

from src.core import ASSETS_PATH, QML_PATH, SRC_PATH

BUILTIN_THEMES = [
    {
        "path": QML_PATH,
        "meta": {
            "id": "com.classwidgets.default",
            "name": QCoreApplication.translate("Theme", "Default"),
            "description": QCoreApplication.translate("Theme", "Class Widgets Builtin Default Theme"),
            "author": "Class Widgets Official",
            "version": "1.0.0",
            "api_version": "*",
            "preview": ASSETS_PATH / "images" / "themes" / "default.png",
            "color": "#4099b2",
        }
    },
    {
        "path": SRC_PATH / "themes" / "cw1",
        "meta": {
            "id": "com.classwidgets.cw1",
            "name": "Class Widgets 1",
            "description": "Class Widgets 1 Classic Theme",
            "author": "Class Widgets Official",
            "version": "1.0.0",
            "api_version": "*",
            "preview": ASSETS_PATH / "images" / "themes" / "cw1.png",
            "color": "#58CED7",
        }
    },
    {
        "path": SRC_PATH / "themes" / "win10",
        "meta": {
            "id": "com.classwidgets.win10",
            "name": "Windows 10",
            "description": "Windows 10 Fluent 1 Style Theme",
            "author": "Class Widgets Official",
            "version": "1.0.0",
            "api_version": "*",
            "preview": ASSETS_PATH / "images" / "themes" / "win10.png",
            "color": "#0078d7",
        }
    },
    {
        "path": SRC_PATH / "themes" / "material",
        "meta": {
            "id": "com.classwidgets.material",
            "name": "Material You",
            "description": "Material You 3 Style Theme",
            "author": "Class Widgets Official",
            "version": "1.0.0",
            "api_version": "*",
            "preview": ASSETS_PATH / "images" / "themes" / "material.png",
            "color": "#6750A4",
        }
    },
]
