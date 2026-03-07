from pathlib import Path

from PySide6.QtCore import QObject, Slot

# Define paths
SRC_PATH = Path(__file__).parents[1]
ROOT_PATH = SRC_PATH.parent

ASSETS_PATH = SRC_PATH.parent / "assets"
QML_PATH = SRC_PATH / "qml"
CW_PATH = QML_PATH / "ClassWidgets"
# DEFAULT_THEME = SRC_PATH / "themes" / "com.classwidgets.theme.default"
DEFAULT_THEME = CW_PATH / "themes" / "default"

CONFIGS_PATH = ROOT_PATH / "configs"
SCHEDULES_PATH = CONFIGS_PATH / "schedules"
THEMES_PATH = ROOT_PATH / "themes"
PLUGINS_PATH = ROOT_PATH / "plugins"
BUILTIN_PLUGINS_PATH = SRC_PATH / "plugins"
LOGS_PATH = ROOT_PATH / "logs"

EXAMPLES_PATH = ROOT_PATH / "examples"

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
