"""Prepare the writable workspace and copy legacy data without changing its source."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import tempfile
from pathlib import Path

from loguru import logger
from PySide6.QtCore import QLockFile

from .directories import INSTALL_PATH, PORTABLE_WORK_PATH, RESOURCE_PATH, USER_WORK_PATH, WORK_PATH

_JOURNAL = ".data-migration-v1.json"
_STAGING = ".data-migration-v1-staging"
_STAGE_MARKER = ".migration-source"
_LEGACY_DIRS = ("configs", "plugins", "themes")


class DataMigrationError(RuntimeError):
    """Migration needs attention; do not start the application with empty data."""


def _is_link(path: Path) -> bool:
    return path.is_symlink() or path.is_junction()


def _digest_tree(path: Path, *, skip_legacy_cache: bool = False) -> str:
    """Fingerprint all entries, including empty directories, and reject links."""
    digest = hashlib.sha256()
    if _is_link(path) or not path.is_dir():
        raise DataMigrationError(f"Expected a regular data directory: {path}")

    for entry in sorted(path.rglob("*"), key=lambda item: item.relative_to(path).as_posix()):
        relative = entry.relative_to(path)
        if skip_legacy_cache and relative.parts[0] == "plugin-cache":
            continue
        if _is_link(entry):
            raise DataMigrationError(f"Cannot migrate a linked data entry: {entry}")
        name = relative.as_posix().encode("utf-8")
        digest.update(len(name).to_bytes(8, "big"))
        digest.update(name)
        if entry.is_dir():
            digest.update(b"D")
        elif entry.is_file():
            digest.update(b"F")
            digest.update(entry.stat().st_size.to_bytes(8, "big"))
            with entry.open("rb") as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    digest.update(block)
        else:
            raise DataMigrationError(f"Unsupported data entry: {entry}")
    return digest.hexdigest()


def _digest_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _write_journal(path: Path, journal: dict) -> None:
    temporary: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent,
            prefix=f"{path.name}.", suffix=".tmp", delete=False,
        ) as stream:
            temporary = Path(stream.name)
            json.dump(journal, stream, ensure_ascii=False, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        temporary.replace(path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def _legacy_source(installation_path: Path, resource_path: Path) -> Path | None:
    candidates = [installation_path]
    if resource_path != installation_path:
        candidates.append(resource_path)
    found = [
        root for root in candidates
        if any((root / name).exists() or _is_link(root / name) for name in _LEGACY_DIRS)
    ]
    if len(found) > 1:
        raise DataMigrationError(f"Multiple legacy data locations found: {found}")
    return found[0] if found else None


def _already_imported_in_other_mode(other_work_path: Path | None, source: Path) -> bool:
    if other_work_path is None:
        return False
    journal_path = other_work_path / _JOURNAL
    if _is_link(journal_path) or not journal_path.is_file():
        return False
    try:
        journal = json.loads(journal_path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return False
    return (
        isinstance(journal, dict)
        and journal.get("state") == "complete"
        and isinstance(journal.get("source"), str)
        and Path(journal["source"]).resolve() == source.resolve()
    )


def _copy_legacy_directory(source: Path, destination: Path, *, configs: bool = False) -> str:
    original = _digest_tree(source, skip_legacy_cache=configs)

    def ignore(directory: str, names: list[str]) -> set[str]:
        return {"plugin-cache"} if configs and Path(directory) == source and "plugin-cache" in names else set()

    shutil.copytree(source, destination, ignore=ignore, symlinks=True)
    if (
        _digest_tree(source, skip_legacy_cache=configs) != original
        or _digest_tree(destination) != original
    ):
        raise DataMigrationError(f"Legacy data changed during copying: {source}")
    return original


def _regular_descendant(root: Path, relative: Path) -> Path:
    """Do not follow a symlink in an app-owned file reference."""
    if relative.drive or relative.root or not relative.parts or ".." in relative.parts:
        raise DataMigrationError(f"Unsafe legacy file reference: {relative}")
    if _is_link(root):
        raise DataMigrationError(f"Legacy data path is a symbolic link: {root}")
    candidate = root
    for part in relative.parts:
        candidate = candidate / part
        if _is_link(candidate):
            raise DataMigrationError(f"Legacy file path is a symbolic link: {candidate}")
    return candidate


def _owned_staging(staging: Path, source: Path) -> bool:
    if _is_link(staging) or not staging.is_dir():
        return False
    marker = staging / _STAGE_MARKER
    return (
        not _is_link(marker)
        and marker.is_file()
        and marker.read_text(encoding="utf-8") == str(source.resolve())
    )


def _validate_legacy_config(config: dict) -> None:
    """Fail rather than let ConfigManager replace unreadable migrated data with defaults."""
    from src.core.config.manager import RootConfig

    RootConfig.model_validate(config)


def _validate_work_config(work_path: Path) -> None:
    """Never let ConfigManager overwrite a damaged existing config with defaults."""
    config_file = work_path / "configs" / "configs.json"
    if _is_link(config_file) or (config_file.exists() and not config_file.is_file()):
        raise DataMigrationError(f"Application configuration is not a regular file: {config_file}")
    if not config_file.exists():
        return

    from src.core.config.manager import RootConfig

    try:
        RootConfig.model_validate_json(config_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as error:
        raise DataMigrationError(
            f"Cannot read application configuration without risking data loss: {config_file}"
        ) from error


def _copy_referenced_files(
    source_root: Path, resource_path: Path, work_path: Path, staging: Path,
) -> dict[str, str]:
    """Only move known app-owned references, never arbitrary plugin settings."""
    config_file = staging / "configs" / "configs.json"
    if not config_file.is_file():
        return {}
    try:
        config = json.loads(config_file.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise DataMigrationError(f"Cannot inspect legacy configuration: {config_file}") from error
    if not isinstance(config, dict):
        raise DataMigrationError(f"Invalid legacy configuration: {config_file}")

    modified = False
    source_files: dict[str, str] = {}
    plugins = config.get("plugins")
    if isinstance(plugins, dict) and isinstance(plugins.get("pending_operations"), list):
        old_cache = source_root / "configs" / "plugin-cache"
        if _is_link(old_cache):
            raise DataMigrationError(f"Legacy plugin cache is a symbolic link: {old_cache}")
        for operation in plugins["pending_operations"]:
            if not isinstance(operation, dict) or not isinstance(operation.get("archive_path"), str):
                continue
            archive = Path(operation["archive_path"])
            if not archive.is_absolute() or not archive.is_relative_to(old_cache):
                continue
            relative = archive.relative_to(old_cache)
            archive = _regular_descendant(source_root, Path("configs/plugin-cache") / relative)
            if not archive.is_file():
                raise DataMigrationError(f"Pending plugin archive is missing: {archive}")
            staged_archive = staging / "cache" / "plugin-cache" / relative
            staged_archive.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(archive, staged_archive)
            if _digest_file(staged_archive) != _digest_file(archive):
                raise DataMigrationError(f"Pending plugin archive changed during copying: {archive}")
            source_files[str(archive)] = _digest_file(staged_archive)
            operation["archive_path"] = str(work_path / "cache" / "plugin-cache" / relative)
            modified = True

    notifications = config.get("notifications")
    if isinstance(notifications, dict) and isinstance(notifications.get("level_sounds"), dict):
        audio_roots = list(dict.fromkeys((source_root, resource_path)))
        for key, sound in notifications["level_sounds"].items():
            if not isinstance(sound, str) or not sound:
                continue
            candidate = Path(sound)
            audio_root: Path | None = None
            if candidate.is_absolute():
                matched_roots = [
                    root for root in audio_roots
                    if candidate.is_relative_to(root / "assets" / "audio")
                ]
                if not matched_roots:
                    continue  # User-selected file outside the app is not ours to move.
                audio_root = matched_roots[0]
                relative = candidate.relative_to(audio_root / "assets" / "audio")
            else:
                relative = candidate
            if relative.drive or relative.root or ".." in relative.parts:
                continue
            sources = (
                [_regular_descendant(audio_root, Path("assets/audio") / relative)] if audio_root is not None
                else [_regular_descendant(root, Path("assets/audio") / relative) for root in audio_roots]
            )
            source = next((item for item in sources if item.is_file()), None)
            if source is None:
                continue
            staged_sound = staging / "audio" / relative
            staged_sound.parent.mkdir(parents=True, exist_ok=True)
            if staged_sound.exists() and _digest_file(staged_sound) != _digest_file(source):
                raise DataMigrationError(f"Two different selected sounds share the same name: {relative}")
            shutil.copy2(source, staged_sound)
            if _digest_file(staged_sound) != _digest_file(source):
                raise DataMigrationError(f"Selected audio changed during copying: {source}")
            source_files[str(source)] = _digest_file(staged_sound)
            if candidate.is_absolute():
                notifications["level_sounds"][key] = str(relative)
                modified = True

    _validate_legacy_config(config)
    if modified:
        config_file.write_text(json.dumps(config, ensure_ascii=False, indent=4), encoding="utf-8")
    return source_files


def _commit(staging: Path, work_path: Path, journal_path: Path, journal: dict) -> None:
    # Validate *all* destinations before moving the first directory.
    source = Path(journal["source"])
    if not _owned_staging(staging, source):
        raise DataMigrationError(f"Migration staging is missing or unrecognized: {staging}")
    for name, expected in journal["legacy_directories"].items():
        if _digest_tree(source / name, skip_legacy_cache=name == "configs") != expected:
            raise DataMigrationError(f"Legacy data changed before migration completed: {source / name}")
    for name, expected in journal["source_files"].items():
        path = Path(name)
        if _is_link(path) or not path.is_file() or _digest_file(path) != expected:
            raise DataMigrationError(f"Legacy referenced file changed before migration completed: {path}")
    for name, expected in journal["directories"].items():
        destination = work_path / name
        staged = staging / name
        if _is_link(destination) or _is_link(staged):
            raise DataMigrationError(f"Linked migration path at {destination} or {staged}")
        if destination.exists():
            if staged.exists():
                raise DataMigrationError(f"Data conflict at {destination}; no existing files were overwritten")
            if _digest_tree(destination) != expected:
                raise DataMigrationError(f"Data conflict at {destination}; no existing files were overwritten")
        elif name in journal["committed"] or _digest_tree(staged) != expected:
            raise DataMigrationError(f"Staged migration data is incomplete: {staged}")

    for name in journal["directories"]:
        destination = work_path / name
        if not destination.exists():
            (staging / name).replace(destination)
        if name not in journal["committed"]:
            journal["committed"].append(name)
            _write_journal(journal_path, journal)

    journal["state"] = "complete"
    _write_journal(journal_path, journal)
    (staging / _STAGE_MARKER).unlink()
    staging.rmdir()


def prepare_work_directory(
    *,
    installation_path: Path = INSTALL_PATH,
    resource_path: Path = RESOURCE_PATH,
    work_path: Path = WORK_PATH,
    other_work_path: Path | None = None,
) -> None:
    """Run once at the start of AppCentral, before any user data is created."""
    if other_work_path is None and work_path == WORK_PATH:
        other_work_path = USER_WORK_PATH if WORK_PATH == PORTABLE_WORK_PATH else PORTABLE_WORK_PATH
    if work_path.resolve() in (installation_path.resolve(), resource_path.resolve()):
        raise DataMigrationError("The writable workspace cannot be the installation directory")
    if _is_link(work_path):
        raise DataMigrationError(f"The application data directory is a link: {work_path}")
    try:
        work_path.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryFile(dir=work_path):
            pass
    except OSError as error:
        raise DataMigrationError(f"Cannot write application data to {work_path}: {error}") from error

    lock = QLockFile(str(work_path / ".data-migration.lock"))
    if not lock.tryLock(5000):
        raise DataMigrationError(f"Another instance is preparing application data in {work_path}")
    try:
        journal_path = work_path / _JOURNAL
        staging = work_path / _STAGING
        if journal_path.exists() or _is_link(journal_path):
            if _is_link(journal_path):
                raise DataMigrationError(f"Migration journal is a link: {journal_path}")
            try:
                journal = json.loads(journal_path.read_text(encoding="utf-8"))
            except (OSError, ValueError) as error:
                raise DataMigrationError(f"Invalid migration journal: {journal_path}") from error
            if not isinstance(journal, dict) or journal.get("version") != 1:
                raise DataMigrationError(f"Unsupported migration journal: {journal_path}")
            directories = journal.get("directories")
            legacy_directories = journal.get("legacy_directories")
            if (
                not isinstance(directories, dict)
                or not directories
                or not directories.keys() <= {*_LEGACY_DIRS, "audio", "cache"}
                or not all(isinstance(value, str) and len(value) == 64 for value in directories.values())
                or not isinstance(legacy_directories, dict)
                or not legacy_directories
                or not legacy_directories.keys() <= set(_LEGACY_DIRS)
                or not legacy_directories.keys() <= directories.keys()
                or not all(isinstance(value, str) and len(value) == 64 for value in legacy_directories.values())
                or not isinstance(journal.get("source"), str)
                or not journal["source"]
                or not isinstance(journal.get("source_files"), dict)
                or not all(
                    isinstance(name, str) and isinstance(value, str) and len(value) == 64
                    for name, value in journal["source_files"].items()
                )
                or not isinstance(journal.get("committed"), list)
                or not all(isinstance(name, str) for name in journal["committed"])
                or len(set(journal["committed"])) != len(journal["committed"])
                or not set(journal["committed"]) <= directories.keys()
                or not isinstance(journal.get("has_config"), bool)
            ):
                raise DataMigrationError(f"Invalid migration journal contents: {journal_path}")
            if journal.get("state") == "pending":
                _commit(staging, work_path, journal_path, journal)
            elif journal.get("state") != "complete":
                raise DataMigrationError(f"Invalid migration state: {journal_path}")
            if journal["state"] == "complete":
                for name in legacy_directories:
                    if not (work_path / name).is_dir() or _is_link(work_path / name):
                        raise DataMigrationError(f"Migrated data directory is missing: {work_path / name}")
                if journal["has_config"] and not (work_path / "configs" / "configs.json").is_file():
                    raise DataMigrationError(f"Migrated configuration file is missing: {work_path / 'configs/configs.json'}")
            if journal["state"] == "complete" and (staging.exists() or _is_link(staging)):
                if _is_link(staging) or not staging.is_dir():
                    raise DataMigrationError(f"Invalid completed migration staging: {staging}")
                contents = list(staging.iterdir())
                if contents == [staging / _STAGE_MARKER] and _owned_staging(staging, Path(journal["source"])):
                    contents[0].unlink()
                if any(staging.iterdir()):
                    raise DataMigrationError(f"Unexpected data in completed migration staging: {staging}")
                staging.rmdir()
        else:
            source = _legacy_source(installation_path, resource_path)
            if source is not None and _already_imported_in_other_mode(other_work_path, source):
                logger.info("Legacy data was migrated in the other mode; starting fresh at {}", work_path)
                source = None
            if source is None and (staging.exists() or _is_link(staging)):
                raise DataMigrationError(f"Unfinished migration staging needs attention: {staging}")
            if source is not None:
                names = [name for name in _LEGACY_DIRS if (source / name).exists() or _is_link(source / name)]
                conflicts = [
                    name for name in _LEGACY_DIRS
                    if (work_path / name).exists() or _is_link(work_path / name)
                ]
                if conflicts:
                    raise DataMigrationError(
                        f"Existing data in {work_path} conflicts with legacy {', '.join(conflicts)}; "
                        "import it manually rather than overwriting it"
                    )
                if staging.exists() or _is_link(staging):
                    if _is_link(staging) or not staging.is_dir():
                        raise DataMigrationError(f"Invalid migration staging directory: {staging}")
                    if any(staging.iterdir()) and not _owned_staging(staging, source):
                        raise DataMigrationError(f"Unrecognized migration staging data: {staging}")
                    shutil.rmtree(staging)
                staging.mkdir()
                try:
                    (staging / _STAGE_MARKER).write_text(str(source.resolve()), encoding="utf-8")
                    legacy_directories = {}
                    for name in names:
                        legacy_directories[name] = _copy_legacy_directory(
                            source / name, staging / name, configs=name == "configs"
                        )
                    source_files = _copy_referenced_files(source, resource_path, work_path, staging)
                    generated_conflicts = [
                        path.name for path in staging.iterdir()
                        if (work_path / path.name).exists() or _is_link(work_path / path.name)
                    ]
                    if generated_conflicts:
                        raise DataMigrationError(
                            f"Existing data in {work_path} conflicts with migration: "
                            f"{', '.join(generated_conflicts)}"
                        )
                    directories = {
                        path.name: _digest_tree(path)
                        for path in staging.iterdir() if path.is_dir()
                    }
                    journal = {
                        "version": 1,
                        "source": str(source.resolve()),
                        "state": "pending",
                        "directories": directories,
                        "legacy_directories": legacy_directories,
                        "source_files": source_files,
                        "has_config": (staging / "configs" / "configs.json").is_file(),
                        "committed": [],
                    }
                    _write_journal(journal_path, journal)
                except Exception:
                    if not journal_path.exists():
                        shutil.rmtree(staging, ignore_errors=True)
                    raise
                _commit(staging, work_path, journal_path, journal)

        for relative in ("configs/schedules", "plugins", "themes", "logs", "cache/plugin-cache", "temp", "audio"):
            destination = work_path
            for part in Path(relative).parts:
                destination = destination / part
                if _is_link(destination):
                    raise DataMigrationError(f"Application data directory is a link: {destination}")
                destination.mkdir(exist_ok=True)
        _validate_work_config(work_path)
    except (OSError, shutil.Error, ValueError) as error:
        raise DataMigrationError(f"Cannot prepare application data in {work_path}: {error}") from error
    finally:
        lock.unlock()
