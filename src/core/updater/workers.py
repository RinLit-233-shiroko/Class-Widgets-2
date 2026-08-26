from pathlib import Path
import platform
from urllib.parse import urlparse

import requests
from PySide6.QtCore import QThread, Signal

from src.core.updater.downloader import UpdateDownloader
from src.core.updater.updater import WindowsUpdater


# UPDATE_URL = "http://localhost:8080/releases.json"
UPDATE_URL = "https://classwidgets.rinlit.cn/2/releases.json"
GITHUB_API_ROOT = "https://api.github.com/repos"


class CheckUpdateWorker(QThread):
    finished = Signal(str, str, str)  # status, version, url_or_error

    def __init__(self, channel: str, current_version: str, github_releases_url: str = ""):
        super().__init__()
        self.channel = channel
        self.current_version = current_version
        self.url = UPDATE_URL
        self.github_releases_url = github_releases_url.strip()

    def start(self, url: str | None = None, github_releases_url: str | None = None):
        if url:
            self.url = url
        if github_releases_url is not None:
            self.github_releases_url = github_releases_url.strip()
        super().start()

    @staticmethod
    def _github_releases_api_url(releases_url: str) -> str:
        """将 GitHub Release 页面地址转换为公开 Releases API 地址。"""
        parsed = urlparse(releases_url.strip())
        if parsed.scheme not in {"http", "https"} or parsed.netloc.lower() not in {
            "github.com",
            "www.github.com",
        }:
            raise ValueError("自定义更新源必须是 GitHub Releases 页面地址")

        path_parts = [part for part in parsed.path.split("/") if part]
        if len(path_parts) < 3 or path_parts[2] != "releases":
            raise ValueError("GitHub Releases 地址应为 https://github.com/所有者/仓库/releases")

        owner, repository = path_parts[0], path_parts[1]
        return f"{GITHUB_API_ROOT}/{owner}/{repository}/releases?per_page=100"

    def _select_github_release(self, releases: list[dict]) -> dict:
        available_releases = [release for release in releases if not release.get("draft", False)]
        if self.channel == "release":
            available_releases = [
                release for release in available_releases if not release.get("prerelease", False)
            ]

        if not available_releases:
            channel_name = "稳定版" if self.channel == "release" else "可用"
            raise ValueError(f"未找到{channel_name} GitHub Release")
        return available_releases[0]

    @staticmethod
    def _select_release_asset(release: dict) -> str:
        """选择与当前系统匹配的安装包，Windows 优先选择 ZIP 以复用原安装流程。"""
        assets = release.get("assets", [])
        if not isinstance(assets, list):
            assets = []

        system_name = platform.system().lower()
        preferred_suffixes = {
            "windows": (".zip",),
            "darwin": (".dmg", ".zip"),
            "linux": (".appimage", ".tar.gz", ".zip"),
        }.get(system_name, (".zip",))

        for suffix in preferred_suffixes:
            for asset in assets:
                name = str(asset.get("name", "")).lower()
                download_url = str(asset.get("browser_download_url", ""))
                if name.endswith(suffix) and download_url:
                    return download_url

        raise ValueError(f"Release 未提供适用于 {platform.system()} 的更新包")

    def _check_github_releases(self) -> tuple[str, str]:
        api_url = self._github_releases_api_url(self.github_releases_url)
        response = requests.get(
            api_url,
            timeout=10,
            headers={
                "Accept": "application/vnd.github+json",
                "User-Agent": "ClassWidgetsUpdateChecker/2",
            },
        )
        response.raise_for_status()
        releases = response.json()
        if not isinstance(releases, list):
            raise ValueError("GitHub Releases API 返回了无效数据")

        release = self._select_github_release(releases)
        version = str(release.get("tag_name", "")).lstrip("vV")
        if not version:
            raise ValueError("GitHub Release 缺少版本标签")
        return version, self._select_release_asset(release)

    def _check_default_update_source(self) -> tuple[str, str]:
        update_url = self.url or UPDATE_URL
        response = requests.get(update_url, timeout=5)
        response.raise_for_status()
        data = response.json()
        info = data.get(self.channel)
        if not info:
            raise ValueError("Missing channel info")

        version = info.get("version", "")
        system_name = platform.system().lower()
        download_url = info.get("url", {}).get(system_name, "") or ""
        return version, download_url

    def run(self):
        try:
            if self.github_releases_url:
                version, download_url = self._check_github_releases()
            else:
                version, download_url = self._check_default_update_source()

            if version != self.current_version:
                self.finished.emit("UpdateAvailable", version, download_url)
            else:
                self.finished.emit("UpToDate", version, "")
        except Exception as exc:
            self.finished.emit("Error", "", str(exc))


class DownloadWorker(QThread):
    progress = Signal(float, float)
    finished = Signal(bool, str, bool)  # success, error_msg, manual_stop

    def __init__(self, downloader: UpdateDownloader):
        super().__init__()
        self.downloader = downloader

    def run(self):
        try:
            success = self.downloader.download(progress_callback=self.progress.emit)
            if success:
                self.finished.emit(True, "", False)
            else:
                self.finished.emit(False, "Download cancelled or failed.", self.downloader.manual_stop)
        except Exception as e:
            self.finished.emit(False, str(e), False)

    def stop(self, force=False):
        try:
            self.downloader.stop(force)
        except Exception:
            pass


class InstallWorker(QThread):
    finished = Signal(bool, str)  # success, error_msg

    def __init__(self, updater: WindowsUpdater, zip_path: Path, target_dir: Path):
        super().__init__()
        self.updater = updater
        self.zip_path = zip_path
        self.target_dir = target_dir

    def run(self):
        try:
            self.updater.apply_update(self.zip_path, self.target_dir)
            self.finished.emit(True, "")
        except Exception as e:
            self.finished.emit(False, str(e))
