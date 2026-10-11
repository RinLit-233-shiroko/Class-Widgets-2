"""Prepare the writable workspace and move legacy data without overwriting files."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

from PySide6.QtCore import QLockFile

from .directories import INSTALL_PATH, RESOURCE_PATH, WORK_PATH, USE_LEGACY_WORK_LAYOUT

_LEGACY_DIRS = ("plugins", "themes", "configs")


class DataMigrationError(RuntimeError):
    """Migration needs attention; do not start with incomplete data."""


def _is_link(path: Path) -> bool:
    return path.is_symlink() or path.is_junction()


def _legacy_source(installation_path: Path, resource_path: Path) -> Path | None:
    candidates = list(dict.fromkeys((installation_path, resource_path)))
    found = [root for root in candidates if any(
        (root / name).exists() or _is_link(root / name) for name in _LEGACY_DIRS
    )]
    if len(found) > 1:
        raise DataMigrationError(f"Multiple legacy data locations found: {found}")
    return found[0] if found else None


def _validate_work_config(work_path: Path) -> None:
    config_file = work_path / "configs" / "configs.json"
    if _is_link(config_file) or (config_file.exists() and not config_file.is_file()):
        raise DataMigrationError(f"Application configuration is not a regular file: {config_file}")
    if not config_file.exists():
        return
    from src.core.config.manager import RootConfig
    try:
        RootConfig.model_validate_json(config_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as error:
        raise DataMigrationError(f"Cannot read application configuration: {config_file}") from error


def _update_references(source: Path, resource_path: Path, work_path: Path) -> None:
    """Update moved archive paths and preserve selected app-owned audio."""
    config_file = work_path / "configs" / "configs.json"
    if not config_file.is_file():
        return
    config = json.loads(config_file.read_text(encoding="utf-8"))
    modified = False
    old_cache = source / "configs" / "plugin-cache"
    for operation in config.get("plugins", {}).get("pending_operations", []):
        if not isinstance(operation, dict) or not isinstance(operation.get("archive_path"), str):
            continue
        archive = Path(operation["archive_path"])
        if archive.is_absolute() and archive.is_relative_to(old_cache):
            relative = archive.relative_to(old_cache)
            if ".." in relative.parts:
                raise DataMigrationError(f"Unsafe legacy archive reference: {archive}")
            # The entire cache moved with configs; its files can stay there.
            operation["archive_path"] = str(work_path / "configs/plugin-cache" / relative)
            modified = True

    audio_roots = list(dict.fromkeys((source, resource_path)))
    for key, sound in config.get("notifications", {}).get("level_sounds", {}).items():
        if not isinstance(sound, str) or not sound:
            continue
        candidate = Path(sound)
        roots = audio_roots
        relative = candidate
        if candidate.is_absolute():
            roots = [root for root in audio_roots if candidate.is_relative_to(root / "assets/audio")]
            if not roots:
                continue  # Leave external user-selected files alone.
            relative = candidate.relative_to(roots[0] / "assets/audio")
        if relative.drive or relative.root or ".." in relative.parts:
            raise DataMigrationError(f"Unsafe legacy audio reference: {sound}")
        audio = next((root / "assets/audio" / relative for root in roots
                      if (root / "assets/audio" / relative).is_file()), None)
        if audio is None:
            continue
        destination = work_path / "audio" / relative
        for path in (audio, destination):
            if any(_is_link(entry) for entry in (path, *path.parents)):
                raise DataMigrationError(f"Linked audio path: {path}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        if not destination.exists():
            shutil.copy2(audio, destination)  # Preserve built-in installation resources.
        if candidate.is_absolute():
            config["notifications"]["level_sounds"][key] = str(relative)
            modified = True
    if modified:
        temporary = config_file.with_suffix(".json.tmp")
        with temporary.open("x", encoding="utf-8") as stream:
            json.dump(config, stream, ensure_ascii=False, indent=4)
        temporary.replace(config_file)


def _prepare_data_directories(work_path: Path) -> None:
    for relative in ("configs/schedules", "plugins", "themes", "logs", "cache/plugin-cache", "temp", "audio"):
        destination = work_path
        for part in Path(relative).parts:
            destination = destination / part
            if _is_link(destination):
                raise DataMigrationError(f"Application data directory is a link: {destination}")
            destination.mkdir(exist_ok=True)
    _validate_work_config(work_path)


def prepare_work_directory(
    *,
    installation_path: Path = INSTALL_PATH,
    resource_path: Path = RESOURCE_PATH,
    work_path: Path = WORK_PATH,
) -> None:
    """Move legacy directories before AppCentral creates any user data."""
    legacy_layout = USE_LEGACY_WORK_LAYOUT and work_path == WORK_PATH and installation_path == INSTALL_PATH
    if not legacy_layout and work_path.resolve() in (installation_path.resolve(), resource_path.resolve()):
        raise DataMigrationError("The writable workspace cannot be the installation directory")
    if any(_is_link(path) for path in (work_path, *work_path.parents)):
        raise DataMigrationError(f"The application data directory is a link: {work_path}")
    lock = QLockFile(str(work_path / ".data-migration.lock"))
    try:
        work_path.mkdir(parents=True, exist_ok=True)
        if not lock.tryLock(5000):
            raise DataMigrationError(f"Another instance is preparing application data in {work_path}")
        if not legacy_layout:
            source = _legacy_source(installation_path, resource_path)
            if source is not None:
                names = [name for name in _LEGACY_DIRS if (source / name).exists() or _is_link(source / name)]
                # Check every destination before moving; never merge or overwrite.
                for name in names:
                    origin, destination = source / name, work_path / name
                    if destination.exists() or _is_link(destination):
                        raise DataMigrationError(f"Existing data conflicts with migration: {destination}")
                    if _is_link(origin) or not origin.is_dir():
                        raise DataMigrationError(f"Legacy data is not a regular directory: {origin}")
                    if any(_is_link(entry) for entry in origin.rglob("*")):
                        raise DataMigrationError(f"Legacy data contains links: {origin}")
                _validate_work_config(source)
                for name in names:
                    shutil.move(str(source / name), str(work_path / name))
                _update_references(source, resource_path, work_path)
        _prepare_data_directories(work_path)
    except (OSError, shutil.Error, ValueError) as error:
        raise DataMigrationError(f"Cannot prepare application data in {work_path}: {error}") from error
    finally:
        if lock.isLocked():
            lock.unlock()