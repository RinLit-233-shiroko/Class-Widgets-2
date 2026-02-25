from urllib.parse import urlparse

import requests
from pathlib import Path
import time

from loguru import logger

from class_widgets_2.core.config import ConfigManager


class UpdateDownloader:
    def __init__(self, url: str, dest: Path, configs=ConfigManager):
        self.url = url
        self.dest = dest
        self._stop_flag = False  # 用于中断
        self.manual_stop = False  # 用于手动中断
        self.configs = configs

    def stop(self, manual=False):
        """外部调用停止下载"""
        self._stop_flag = True
        if manual:
            self.manual_stop = True

    def _resolve_url(self, url: str) -> str:
        """根据 URL 判断是否使用备用下载源"""
        parsed = urlparse(url)
        if "github.com" not in parsed.netloc:
            return url

        if self.configs.network.mirrors and self.configs.network.current_mirror and self.configs.network.mirror_enabled:
            mirror = self.configs.network.mirrors[self.configs.network.current_mirror]
            return mirror + url
        else:
            return url


    def download(self, progress_callback=None):
        """阻塞下载，progress_callback(百分比, 速度)"""
        self._stop_flag = False
        resolved_url = self._resolve_url(self.url)
        logger.info(f"Downloading updates from: {resolved_url}")

        with requests.get(resolved_url, stream=True, proxies=None) as r:
            r.raise_for_status()
            total = int(r.headers.get('content-length', 0))
            downloaded = 0
            start_time = time.time()
            with open(self.dest, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    if self._stop_flag:
                        return False  # 表示下载被中断
                    f.write(chunk)
                    downloaded += len(chunk)
                    elapsed = max(time.time() - start_time, 0.001)
                    speed = downloaded / elapsed  # bytes/sec
                    if progress_callback:
                        progress_callback(downloaded / total * 100, speed)
        return True