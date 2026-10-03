import sys
from pathlib import Path

from platformdirs import user_data_path
from PySide6.QtCore import QObject, Slot

# Resource paths remain inside the application, even when it is installed read-only.
RESOURCE_PATH = Path(getattr(sys, "_MEIPASS", Path(__file__).parents[3])).resolve()
ROOT_PATH = RESOURCE_PATH
SRC_PATH = RESOURCE_PATH / "src"

ASSETS_PATH = RESOURCE_PATH / "assets"
QML_PATH = SRC_PATH / "qml"
CW_PATH = QML_PATH / "ClassWidgets"
DEFAULT_THEME = QML_PATH


def _installation_path() -> Path:
    if not getattr(sys, "frozen", False):
        return RESOURCE_PATH

    executable = Path(sys.executable).resolve()
    # macOS app resources live *inside* the bundle; portable data lives beside it.
    if (
        executable.parent.name == "MacOS"
        and executable.parent.parent.name == "Contents"
        and executable.parent.parent.parent.suffix == ".app"
    ):
        return executable.parent.parent.parent.parent
    return executable.parent


INSTALL_PATH = _installation_path()
PORTABLE_PATH = INSTALL_PATH / "PORTABLE"
USER_WORK_PATH = Path(user_data_path("Class_Widgets_2", appauthor=False, roaming=False))
PORTABLE_WORK_PATH = INSTALL_PATH / "data"
WORK_PATH = PORTABLE_WORK_PATH if PORTABLE_PATH.is_file() else USER_WORK_PATH

CONFIGS_PATH = WORK_PATH / "configs"
SCHEDULES_PATH = CONFIGS_PATH / "schedules"
THEMES_PATH = WORK_PATH / "themes"
PLUGINS_PATH = WORK_PATH / "plugins"
CACHE_PATH = WORK_PATH / "cache"
PLUGIN_CACHE_PATH = CACHE_PATH / "plugin-cache"
TEMP_PATH = WORK_PATH / "temp"
CUSTOM_AUDIO_PATH = WORK_PATH / "audio"
BUILTIN_PLUGINS_PATH = SRC_PATH / "plugins"
LOGS_PATH = WORK_PATH / "logs"

EXAMPLES_PATH = RESOURCE_PATH / "examples"

PATHS = [
    SRC_PATH,
    ASSETS_PATH,
    QML_PATH,
    THEMES_PATH,
    PLUGINS_PATH,
    BUILTIN_PLUGINS_PATH,
    EXAMPLES_PATH,
]


class PathManager(QObject):
    def __init__(self):
        super().__init__()

    @Slot(str, result=str)
    def root(self, path_name: str) -> str:
        return ROOT_PATH.joinpath(path_name).resolve().as_uri()

    @Slot(str, result=str)
    def assets(self, path_name: str) -> str:
        return ASSETS_PATH.joinpath(path_name).resolve().as_uri()

    @Slot(str, result=str)
    def qml(self, path_name: str) -> str:
        return CW_PATH.joinpath(path_name).resolve().as_uri()

    @Slot(str, result=str)
    def images(self, path_name: str) -> str:
        return ASSETS_PATH.joinpath("images", path_name).resolve().as_uri()


if __name__ == "__main__":
    for path in PATHS:
        print(path)
