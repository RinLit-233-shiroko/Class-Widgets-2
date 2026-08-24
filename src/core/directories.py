from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

from PySide6.QtCore import QObject, Slot

APP_DATA_DIRECTORY_NAME = "Class Widgets 2"
INSTALLATION_MARKER_NAME = ".cw2-installed"
PORTABLE_MIGRATION_MARKER_NAME = ".portable-data-migrated"
PORTABLE_SOURCE_MARKER_NAME = ".cw2-portable-source"


def _resolve_install_root() -> Path:
    """Return the immutable program directory in both source and frozen builds."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parents[2]


def _resolve_source_root(install_root: Path) -> Path:
    """Return the directory containing QML and built-in plugin resources."""
    if getattr(sys, "frozen", False):
        return install_root / "src"
    return Path(__file__).resolve().parents[1]


def _resolve_windows_user_data_root() -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        return Path(local_app_data) / APP_DATA_DIRECTORY_NAME
    return Path.home() / "AppData" / "Local" / APP_DATA_DIRECTORY_NAME


def is_installed_windows_build() -> bool:
    """Whether this build was installed by the CW2 Windows installer.

    The marker is written only by the installer. A ZIP extraction has no marker,
    so its settings, themes and plugins remain next to the executable as expected
    for a portable distribution.
    """
    return sys.platform == "win32" and (ROOT_PATH / INSTALLATION_MARKER_NAME).is_file()


def _copy_portable_item(source: Path, destination: Path) -> None:
    """Copy a portable data item without overwriting an existing user profile."""
    if not source.exists() or destination.exists():
        return
    if source.is_dir():
        shutil.copytree(source, destination)
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def _resolve_portable_migration_source() -> Path:
    """Read the optional portable source recorded by the installer.

    The installer records the folder containing Setup.exe. When a user runs the
    installer from a previous portable folder, this lets the installed app carry
    over that folder's settings without asking them to manually copy files.
    """
    source_marker = ROOT_PATH / PORTABLE_SOURCE_MARKER_NAME
    if not source_marker.is_file():
        return ROOT_PATH
    try:
        source_path = Path(source_marker.read_text(encoding="utf-8").strip())
        if source_path.is_dir():
            return source_path
    except OSError:
        pass
    return ROOT_PATH


def migrate_portable_data_if_needed() -> None:
    """Perform a one-time best-effort migration from an existing portable folder.

    This is intentionally non-destructive. It only copies data into a new user
    profile and never replaces files that already exist in LocalAppData. The
    original portable data remains untouched as a rollback path.
    """
    if not is_installed_windows_build():
        return

    USER_DATA_PATH.mkdir(parents=True, exist_ok=True)
    migration_marker = USER_DATA_PATH / PORTABLE_MIGRATION_MARKER_NAME
    if migration_marker.exists():
        return

    portable_source = _resolve_portable_migration_source()
    for directory_name in ("configs", "themes", "plugins"):
        _copy_portable_item(portable_source / directory_name, USER_DATA_PATH / directory_name)

    migration_marker.touch(exist_ok=True)
    source_marker = ROOT_PATH / PORTABLE_SOURCE_MARKER_NAME
    try:
        source_marker.unlink(missing_ok=True)
    except OSError:
        pass


# Read-only application resources. The frozen application resolves them from the
# directory containing the main executable; source runs resolve them from the repo.
ROOT_PATH = _resolve_install_root()
SRC_PATH = _resolve_source_root(ROOT_PATH)
ASSETS_PATH = ROOT_PATH / "assets"
QML_PATH = SRC_PATH / "qml"
CW_PATH = QML_PATH / "ClassWidgets"
DEFAULT_THEME = QML_PATH
BUILTIN_PLUGINS_PATH = SRC_PATH / "plugins"
EXAMPLES_PATH = ROOT_PATH / "examples"

# User-writable data. ZIP users retain the established adjacent-directory layout;
# a marker written by the installer switches only installed Windows builds to the
# per-user LocalAppData location.
USER_DATA_PATH = _resolve_windows_user_data_root()
DATA_PATH = USER_DATA_PATH if is_installed_windows_build() else ROOT_PATH
CONFIGS_PATH = DATA_PATH / "configs"
SCHEDULES_PATH = CONFIGS_PATH / "schedules"
THEMES_PATH = DATA_PATH / "themes"
PLUGINS_PATH = DATA_PATH / "plugins"
LOGS_PATH = DATA_PATH / "logs"

migrate_portable_data_if_needed()

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
