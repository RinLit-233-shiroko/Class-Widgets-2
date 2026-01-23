import hashlib
import time
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

import requests
from loguru import logger

from src.core.config import ConfigManager


class UpdateDownloader:
    def __init__(self, url: str, dest: Path, configs=ConfigManager):
        self.url = url
        self.dest = dest
        self._stop_flag = False  # 用于中断
        self.manual_stop = False  # 用于手动中断
        self.configs = configs
        self.error_msg = ""

    def stop(self, manual=False):
        """外部调用停止下载"""
        self._stop_flag = True
        if manual:
            self.manual_stop = True

    def _resolve_url(self, url: str) -> str:
        """构造最终下载地址"""
        parsed = urlparse(url)
        current = self.configs.network.current_mirror
        if not current:
            return url
        if current in ("origin",):
            return url
        if "github.com" not in parsed.netloc:
            return url

        if current in ("auto", "自动选择"):
            return url
        return self._build_mirror_url(url, current)

    def _build_mirror_url(self, origin_url: str, mirror_key: str) -> str:
        """根据镜像前缀构造代理地址"""
        parsed = urlparse(origin_url)
        if "github.com" not in parsed.netloc:
            return origin_url
        prefix = self.configs.network.mirrors.get(mirror_key)
        if not prefix or prefix in ("auto", "origin"):
            return origin_url
        suffix = parsed.path.lstrip("/")
        query = f"?{parsed.query}" if parsed.query else ""
        return f"{prefix}{suffix}{query}"

    def _get_system_proxies(self) -> dict | None:
        """获取系统代理设置"""
        try:
            proxies = urllib.request.getproxies()
            return proxies if proxies else None
        except Exception:
            return None

    def _get_verify_flag(self) -> bool:
        """返回 SSL 校验开关"""
        try:
            return not bool(self.configs.network.ignore_ssl_verify)
        except Exception:
            return True

    def _resolve_candidates(self, url: str) -> list:
        """生成候选下载地址列表, 返回 (key, url)"""
        parsed = urlparse(url)
        if "github.com" not in parsed.netloc:
            return [("origin", url)]

        current = self.configs.network.current_mirror
        if current not in ("auto", "自动选择"):
            return [(current, self._resolve_url(url))]
        candidates = []
        for k in self.configs.network.mirrors:
            if k in ("auto",):
                continue
            if k in ("origin",):
                candidates.append((k, url))
            else:
                candidates.append((k, self._build_mirror_url(url, k)))
        scored = []
        for k, u in candidates:
            latency = self._measure_latency(u)
            scored.append(((k, u), latency if latency is not None else float("inf")))
        scored.sort(key=lambda x: x[1])
        return [pair for pair, _ in scored]

    def _origin_sha_url(self, origin_url: str) -> str:
        p = urlparse(origin_url)
        sha_path = p.path + ".sha256"
        return f"{p.scheme}://{p.netloc}{sha_path}"

    def _download_text(self, url: str) -> str | None:
        try:
            r = requests.get(url, timeout=10, proxies=self._get_system_proxies(), verify=self._get_verify_flag())
            r.raise_for_status()
            return r.text.strip()
        except Exception:
            return None

    def _parse_sha256(self, content: str) -> str | None:
        if not content:
            return None
        s = content.strip()
        if " " in s:
            s = s.split()[0]
        return s if len(s) == 64 else None

    def _measure_latency(self, url: str) -> float | None:
        """测量首字节延迟"""
        try:
            start = time.time()
            r = requests.get(url, stream=True, timeout=3, proxies=self._get_system_proxies(), verify=self._get_verify_flag())
            r.raise_for_status()
            r.close()
            return max(time.time() - start, 0.001)
        except Exception:
            return None


    def download(self, progress_callback=None) -> bool:
        """阻塞下载
        Args:
           progress_callback(None): 百分比, 速度

        Returns:
           bool: 是否成功下载"""
        self._stop_flag = False
        candidates = self._resolve_candidates(self.url)
        logger.info(f"Download candidates: {[u for _, u in candidates]}")
        chosen_key = None
        for idx, (key, resolved_url) in enumerate(candidates):
            if self._stop_flag:
                return False
            try:
                logger.info(f"Trying to download from [{idx+1}/{len(candidates)}]: {resolved_url}")
                with requests.get(
                    resolved_url,
                    stream=True,
                    timeout=15,
                    proxies=self._get_system_proxies(),
                    verify=self._get_verify_flag()
                ) as r:
                    r.raise_for_status()
                    total = int(r.headers.get('content-length', 0))
                    downloaded = 0
                    start_time = time.time()
                    with open(self.dest, 'wb') as f:
                        for chunk in r.iter_content(chunk_size=1024 * 128):
                            if self._stop_flag:
                                return False
                            if not chunk:
                                continue
                            f.write(chunk)
                            downloaded += len(chunk)
                            elapsed = max(time.time() - start_time, 0.001)
                            speed = downloaded / elapsed  # bytes/sec
                            if progress_callback and total > 0:
                                progress_callback(downloaded / total * 100, speed)
                chosen_key = key
                break
            except Exception as e:
                logger.warning(f"Failed from {resolved_url}: {e}")
                continue
        if not chosen_key:
            self.error_msg = "All sources failed"
            return False

        origin_sha = self._origin_sha_url(self.url)
        sha_url = origin_sha if chosen_key == "origin" else self._build_mirror_url(origin_sha, chosen_key)
        sha_text = self._download_text(sha_url)
        if not sha_text:
            self.error_msg = "Checksum file missing"
            return False
        expected = self._parse_sha256(sha_text)
        if not expected:
            self.error_msg = "Invalid checksum file"
            return False

        h = hashlib.sha256()
        try:
            with open(self.dest, "rb") as f:
                for chunk in iter(lambda: f.read(1024 * 128), b""):
                    h.update(chunk)
        except Exception as e:
            self.error_msg = f"Checksum read failed: {e}"
            return False
        actual = h.hexdigest()
        if actual.lower() != expected.lower():
            self.error_msg = "Checksum mismatch"
            return False
        return True
