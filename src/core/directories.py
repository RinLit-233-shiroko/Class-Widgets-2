from __future__ import annotations

import sys
from pathlib import Path

from PySide6.QtCore import QObject, Slot


def _resolve_install_root() -> Path:
    """Return the application directory in both source and frozen portable builds."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parents[2]


def _resolve_source_root(install_root: Path) -> Path:
    """Return the directory containing QML and built-in plugin resources."""
    if getattr(sys, "frozen", False):
        return install_root / "src"
    return Path(__file__).resolve().parents[1]


# Application resources and writable portable data are all resolved relative to
# the directory containing the executable. This keeps the ZIP distribution fully
# self-contained and movable.
ROOT_PATH = _resolve_install_root()
SRC_PATH = _resolve_source_root(ROOT_PATH)
ASSETS_PATH = ROOT_PATH / "assets"
QML_PATH = SRC_PATH / "qml"
CW_PATH = QML_PATH / "ClassWidgets"
DEFAULT_THEME = QML_PATH
BUILTIN_PLUGINS_PATH = SRC_PATH / "plugins"
EXAMPLES_PATH = ROOT_PATH / "examples"

DATA_PATH = ROOT_PATH
CONFIGS_PATH = DATA_PATH / "configs"
SCHEDULES_PATH = CONFIGS_PATH / "schedules"
THEMES_PATH = DATA_PATH / "themes"
PLUGINS_PATH = DATA_PATH / "plugins"
LOGS_PATH = DATA_PATH / "logs"

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
