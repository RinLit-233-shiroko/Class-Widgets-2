from __future__ import annotations

import json
import shutil
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any

from loguru import logger
from packaging.version import InvalidVersion, Version

from src.core.plugin.loader import PluginLoader


class PluginArchiveError(ValueError):
    """Raised when a plugin archive cannot be safely installed."""


@dataclass(frozen=True)
class PluginArchiveInfo:
    plugin_id: str
    name: str
    version: str
    api_version: str
    manifest: dict[str, Any]


@dataclass(frozen=True)
class PluginInstallResult:
    plugin_id: str
    version: str
    previous_version: str | None
    replaced: bool


class PluginArchiveInstaller:
    """Validate and atomically install one ``.cwplugin`` archive.

    This class has no Qt or manager state. Local imports and plaza downloads use
    the same implementation, so the archive security rules stay consistent.
    """

    MAX_ARCHIVE_SIZE = 100 * 1024 * 1024
    MAX_EXTRACTED_SIZE = 500 * 1024 * 1024
    MAX_FILE_COUNT = 10_000
    MAX_COMPRESSION_RATIO = 200

    def __init__(self, plugins_path: Path):
        self.plugins_path = Path(plugins_path)
        self.staging_path = self.plugins_path / ".staging"
        self.backup_path = self.plugins_path / ".backups"

    def inspect(self, archive_path: Path | str) -> PluginArchiveInfo:
        archive = self._check_archive_path(archive_path)
        with zipfile.ZipFile(archive, "r") as archive_file:
            members = self._validate_members(archive_file)
            manifest_member = self._find_manifest_member(members)
            manifest = self._read_manifest(archive_file, manifest_member)
            self._validate_manifest(manifest)
            return PluginArchiveInfo(
                plugin_id=manifest["id"],
                name=manifest["name"],
                version=manifest["version"],
                api_version=manifest["api_version"],
                manifest=manifest,
            )

    def install(
        self,
        archive_path: Path | str,
        *,
        expected_plugin_id: str | None = None,
        expected_version: str | None = None,
        replace: bool = True,
    ) -> PluginInstallResult:
        archive = self._check_archive_path(archive_path)
        archive_info = self.inspect(archive)

        if expected_plugin_id and archive_info.plugin_id != expected_plugin_id:
            raise PluginArchiveError(
                f"Archive contains '{archive_info.plugin_id}', expected '{expected_plugin_id}'."
            )
        if expected_version and not self._same_version(archive_info.version, expected_version):
            raise PluginArchiveError(
                f"Archive version '{archive_info.version}' does not match release version "
                f"'{expected_version}'."
            )

        target = self._plugin_target(archive_info.plugin_id)
        previous_version = self._read_existing_version(target)
        if target.exists() and not replace:
            raise PluginArchiveError(f"Plugin '{archive_info.plugin_id}' is already installed.")

        self.staging_path.mkdir(parents=True, exist_ok=True)
        staging_dir = Path(tempfile.mkdtemp(prefix="install-", dir=self.staging_path))
        extracted_plugin = staging_dir / archive_info.plugin_id
        backup_dir: Path | None = None
        target_moved = False
        target_installed = False

        try:
            with zipfile.ZipFile(archive, "r") as archive_file:
                members = self._validate_members(archive_file)
                manifest_member = self._find_manifest_member(members)
                self._extract_plugin(archive_file, members, manifest_member, extracted_plugin)

            installed_info = self.inspect_extracted(extracted_plugin)
            if installed_info.plugin_id != archive_info.plugin_id:
                raise PluginArchiveError("Extracted manifest ID changed during installation.")

            self.plugins_path.mkdir(parents=True, exist_ok=True)
            if target.exists():
                self.backup_path.mkdir(parents=True, exist_ok=True)
                backup_dir = Path(tempfile.mkdtemp(prefix=f"{archive_info.plugin_id}-", dir=self.backup_path))
                backup_target = backup_dir / archive_info.plugin_id
                target.rename(backup_target)
                target_moved = True

            extracted_plugin.rename(target)
            target_installed = True
        except Exception:
            if target_installed and target.exists():
                shutil.rmtree(target, ignore_errors=True)
            if target_moved and backup_dir is not None:
                backup_target = backup_dir / archive_info.plugin_id
                if backup_target.exists() and not target.exists():
                    backup_target.rename(target)
            raise
        finally:
            shutil.rmtree(staging_dir, ignore_errors=True)

        if backup_dir is not None:
            shutil.rmtree(backup_dir, ignore_errors=True)

        logger.info(
            f"Installed plugin {archive_info.plugin_id} v{archive_info.version}"
            f"{' over ' + previous_version if previous_version else ''}"
        )
        return PluginInstallResult(
            plugin_id=archive_info.plugin_id,
            version=archive_info.version,
            previous_version=previous_version,
            replaced=previous_version is not None,
        )

    def inspect_extracted(self, plugin_dir: Path) -> PluginArchiveInfo:
        manifest_path = plugin_dir / "cwplugin.json"
        if not manifest_path.is_file():
            raise PluginArchiveError("Installed archive does not contain cwplugin.json at its root.")
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
            raise PluginArchiveError(f"Invalid cwplugin.json: {error}") from error
        self._validate_manifest(manifest)

        entry = self._safe_relative_path(manifest["entry"], "entry")
        if not (plugin_dir / entry).is_file():
            raise PluginArchiveError(f"Plugin entry file does not exist: {manifest['entry']}")

        if not PluginLoader.validate_meta(manifest, plugin_dir):
            raise PluginArchiveError("Plugin manifest is missing required fields.")
        return PluginArchiveInfo(
            plugin_id=manifest["id"],
            name=manifest["name"],
            version=manifest["version"],
            api_version=manifest["api_version"],
            manifest=manifest,
        )

    def _check_archive_path(self, archive_path: Path | str) -> Path:
        archive = Path(archive_path)
        if not archive.is_file():
            raise PluginArchiveError(f"Plugin archive does not exist: {archive}")
        if archive.stat().st_size > self.MAX_ARCHIVE_SIZE:
            raise PluginArchiveError("Plugin archive is too large.")
        if not zipfile.is_zipfile(archive):
            raise PluginArchiveError("Plugin archive is not a valid ZIP file.")
        return archive

    def _validate_members(self, archive: zipfile.ZipFile) -> list[zipfile.ZipInfo]:
        members = archive.infolist()
        if not members:
            raise PluginArchiveError("Plugin archive is empty.")
        if len(members) > self.MAX_FILE_COUNT:
            raise PluginArchiveError("Plugin archive contains too many files.")

        total_size = 0
        compressed_size = 0
        for member in members:
            if self._is_symlink(member):
                raise PluginArchiveError(f"Symbolic links are not allowed: {member.filename}")
            if self._safe_archive_path(member.filename) is None:
                raise PluginArchiveError(f"Unsafe path in plugin archive: {member.filename}")
            total_size += member.file_size
            compressed_size += max(member.compress_size, 1)

        if total_size > self.MAX_EXTRACTED_SIZE:
            raise PluginArchiveError("Extracted plugin is too large.")
        if total_size and total_size / compressed_size > self.MAX_COMPRESSION_RATIO:
            raise PluginArchiveError("Plugin archive has an unsafe compression ratio.")
        return members

    @staticmethod
    def _is_symlink(member: zipfile.ZipInfo) -> bool:
        mode = (member.external_attr >> 16) & 0xFFFF
        return (mode & 0o170000) == 0o120000

    @staticmethod
    def _safe_archive_path(name: str) -> PurePosixPath | None:
        if not name or "\x00" in name:
            return None
        normalized = name.replace("\\", "/")
        path = PurePosixPath(normalized)
        if path.is_absolute() or any(part in ("", ".", "..") for part in path.parts):
            return None
        return path

    def _find_manifest_member(self, members: list[zipfile.ZipInfo]) -> str:
        manifests = [
            member.filename
            for member in members
            if not member.is_dir() and PurePosixPath(member.filename).name == "cwplugin.json"
        ]
        if len(manifests) != 1:
            raise PluginArchiveError("Plugin archive must contain exactly one cwplugin.json.")
        return manifests[0]

    @staticmethod
    def _read_manifest(archive: zipfile.ZipFile, member_name: str) -> dict[str, Any]:
        try:
            manifest = json.loads(archive.read(member_name).decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError, KeyError) as error:
            raise PluginArchiveError(f"Invalid cwplugin.json: {error}") from error
        if not isinstance(manifest, dict):
            raise PluginArchiveError("cwplugin.json must contain an object.")
        return manifest

    @classmethod
    def _validate_manifest(cls, manifest: dict[str, Any]) -> None:
        required = ("id", "name", "version", "api_version", "entry", "author")
        if any(not isinstance(manifest.get(field), str) or not manifest[field].strip() for field in required):
            raise PluginArchiveError("cwplugin.json is missing required string fields.")
        cls._plugin_target_name(manifest["id"])
        cls._safe_relative_path(manifest["entry"], "entry")
        try:
            Version(manifest["version"])
        except InvalidVersion as error:
            raise PluginArchiveError(f"Invalid plugin version: {manifest['version']}") from error

    @staticmethod
    def _safe_relative_path(value: str, field: str) -> PurePosixPath:
        normalized = value.replace("\\", "/")
        path = PurePosixPath(normalized)
        if path.is_absolute() or any(part in ("", ".", "..") for part in path.parts):
            raise PluginArchiveError(f"Unsafe {field} path in plugin manifest: {value}")
        return path

    @classmethod
    def _plugin_target_name(cls, plugin_id: str) -> str:
        if plugin_id != plugin_id.strip() or plugin_id in ("", ".", ".."):
            raise PluginArchiveError(f"Invalid plugin ID: {plugin_id}")
        if cls._safe_archive_path(plugin_id) is None or "/" in plugin_id or "\\" in plugin_id:
            raise PluginArchiveError(f"Invalid plugin ID: {plugin_id}")
        if any(ord(char) < 32 for char in plugin_id):
            raise PluginArchiveError(f"Invalid plugin ID: {plugin_id}")
        if any(char in '<>:"|?*' for char in plugin_id):
            raise PluginArchiveError(f"Invalid plugin ID: {plugin_id}")
        if plugin_id.rstrip(" .").upper().split(".", 1)[0] in {
            "CON",
            "PRN",
            "AUX",
            "NUL",
            *(f"COM{index}" for index in range(1, 10)),
            *(f"LPT{index}" for index in range(1, 10)),
        }:
            raise PluginArchiveError(f"Invalid plugin ID: {plugin_id}")
        return plugin_id

    def _plugin_target(self, plugin_id: str) -> Path:
        return self.plugins_path / self._plugin_target_name(plugin_id)

    @staticmethod
    def _read_existing_version(plugin_dir: Path) -> str | None:
        manifest_path = plugin_dir / "cwplugin.json"
        if not manifest_path.is_file():
            return None
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            return data.get("version") if isinstance(data.get("version"), str) else None
        except (OSError, UnicodeDecodeError, json.JSONDecodeError):
            return None

    @staticmethod
    def _same_version(left: str, right: str) -> bool:
        try:
            return Version(left) == Version(right)
        except InvalidVersion:
            return left == right

    def _extract_plugin(
        self,
        archive: zipfile.ZipFile,
        members: list[zipfile.ZipInfo],
        manifest_member: str,
        destination: Path,
    ) -> None:
        manifest_path = PurePosixPath(manifest_member)
        plugin_root = manifest_path.parent
        destination.mkdir(parents=True, exist_ok=True)

        for member in members:
            member_path = self._safe_archive_path(member.filename)
            if member_path is None:
                raise PluginArchiveError(f"Unsafe path in plugin archive: {member.filename}")
            try:
                relative_path = member_path.relative_to(plugin_root)
            except ValueError as error:
                raise PluginArchiveError("Plugin archive contains files outside its plugin root.") from error
            if relative_path == PurePosixPath(".") or member.is_dir():
                continue

            output = destination.joinpath(*relative_path.parts)
            output.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(member, "r") as source, output.open("wb") as target:
                shutil.copyfileobj(source, target, length=1024 * 1024)
