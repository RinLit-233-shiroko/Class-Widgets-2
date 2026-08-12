from __future__ import annotations

import threading
import time
from pathlib import Path
from typing import Callable

import requests

from src.core.utils.http_stream import call_interruptibly, iter_response_chunks


PROGRESS_INTERVAL = 0.1


class PluginDownloadCancelled(Exception):
    """Raised when a plugin download is cancelled by the user."""


class PluginDownloadPaused(Exception):
    """Raised when a plugin download is paused and can be resumed later."""


class PluginDownloader:
    """Stream one remote plugin archive to a local file."""

    def __init__(
        self,
        url: str,
        destination: Path,
        *,
        max_size: int = 100 * 1024 * 1024,
        stall_timeout: float = 30.0,
    ):
        # self.url = "https://qqdl.gtimg.cn/qqfile/QQNT/9.9.33/release/a0ce07ad/QQ_9.9.33_260730_x64_01.exe"
        self.url = url
        self.destination = Path(destination)
        self.max_size = max_size
        # self.max_size = 9999999999999
        self.stall_timeout = stall_timeout
        self._cancel_event = threading.Event()
        self._pause_event = threading.Event()
        self._response: requests.Response | None = None
        self._response_lock = threading.Lock()

    def cancel(self) -> None:
        self._cancel_event.set()
        self._interrupt_response()

    def pause(self) -> None:
        self._pause_event.set()
        self._interrupt_response()

    def download(
        self,
        progress_callback: Callable[[float, float, int, int], None] | None = None,
    ) -> Path:
        if self._cancel_event.is_set():
            raise PluginDownloadCancelled()
        if self._pause_event.is_set():
            raise PluginDownloadPaused()

        self.destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.destination.with_name(f".{self.destination.name}.part")
        resumed_bytes = temporary.stat().st_size if temporary.exists() else 0
        if resumed_bytes > self.max_size:
            temporary.unlink(missing_ok=True)
            raise ValueError("Plugin download is too large.")

        headers = {"Range": f"bytes={resumed_bytes}-"} if resumed_bytes else {}

        try:
            response = call_interruptibly(
                lambda: requests.get(
                    self.url,
                    stream=True,
                    timeout=(10, 60),
                    allow_redirects=True,
                    headers=headers,
                ),
                poll=self._raise_if_interrupted,
            )
            with response:
                self._set_response(response)
                self._raise_if_interrupted()
                response.raise_for_status()
                content_length = int(response.headers.get("content-length", "0") or 0)
                is_resuming = resumed_bytes > 0 and response.status_code == 206
                downloaded = resumed_bytes if is_resuming else 0
                mode = "ab" if is_resuming else "wb"
                total_bytes = self._total_bytes(response, content_length, downloaded)
                if total_bytes > self.max_size:
                    raise ValueError("Plugin download is too large.")

                started_at = time.monotonic()
                last_progress_at = started_at
                with temporary.open(mode) as output:
                    for chunk in iter_response_chunks(
                        response,
                        poll=self._raise_if_interrupted,
                        stall_timeout=self.stall_timeout,
                    ):
                        if not chunk:
                            continue
                        downloaded += len(chunk)
                        if downloaded > self.max_size:
                            raise ValueError("Plugin download is too large.")
                        output.write(chunk)
                        now = time.monotonic()
                        if progress_callback and (
                            now - last_progress_at >= PROGRESS_INTERVAL
                            or (total_bytes and downloaded >= total_bytes)
                        ):
                            elapsed = max(now - started_at, 0.001)
                            speed = (downloaded - resumed_bytes) / elapsed
                            percent = downloaded / total_bytes * 100 if total_bytes else 0.0
                            progress_callback(percent, speed, downloaded, total_bytes)
                            last_progress_at = now
                        if total_bytes and downloaded >= total_bytes:
                            break

                # A stream can end without an exception even though the body is
                # incomplete: pause/cancel close the response from another
                # thread, which urllib3 reports as a plain EOF, and a server
                # can also drop the connection early.  Never install a
                # truncated archive.
                self._raise_if_interrupted()
                if total_bytes and downloaded < total_bytes:
                    raise requests.exceptions.ConnectionError(
                        f"Download ended before the archive was complete "
                        f"({downloaded}/{total_bytes} bytes)."
                    )

            temporary.replace(self.destination)
            if progress_callback:
                progress_callback(100.0, 0.0, downloaded, total_bytes or downloaded)
            return self.destination
        except (PluginDownloadPaused, PluginDownloadCancelled):
            raise
        except Exception:
            self._raise_if_interrupted()
            temporary.unlink(missing_ok=True)
            raise
        finally:
            self._set_response(None)

    def _raise_if_interrupted(self) -> None:
        if self._cancel_event.is_set():
            raise PluginDownloadCancelled()
        if self._pause_event.is_set():
            raise PluginDownloadPaused()

    def _interrupt_response(self) -> None:
        with self._response_lock:
            response = self._response
        if response is not None:
            response.close()

    def _set_response(self, response: requests.Response | None) -> None:
        with self._response_lock:
            self._response = response

    @staticmethod
    def _total_bytes(response: requests.Response, content_length: int, downloaded: int) -> int:
        content_range = response.headers.get("content-range", "")
        if "/" in content_range:
            total = content_range.rsplit("/", 1)[-1]
            if total.isdigit():
                return int(total)
        return downloaded + content_length
