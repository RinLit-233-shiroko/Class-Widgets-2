from __future__ import annotations

import platform
import sys
import time
import traceback
from dataclasses import dataclass, field
from datetime import datetime
from types import TracebackType
from typing import Optional

from src import __version__, __version_type__
from src.core.directories import LOGS_PATH

#: Used when a report has to estimate the process uptime on its own.
PROCESS_START = time.monotonic()


def _format_uptime(seconds: float) -> str:
    total = max(int(seconds), 0)
    hours, remainder = divmod(total, 3600)
    minutes, secs = divmod(remainder, 60)
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


def _describe_os() -> str:
    """短名称，用于报告窗口的运行环境一行。"""
    if platform.system() == "Windows":
        try:
            # Windows 11 still reports release "10", only the build tells apart.
            if int(platform.version().split(".")[2]) >= 22000:
                return "Windows 11"
        except (IndexError, ValueError):
            pass
        return f"Windows {platform.release()}"
    return f"{platform.system()} {platform.release()}"


@dataclass(frozen=True)
class CrashReport:
    """A single unhandled exception, formatted for the problem report window."""

    exception_type: str = "Exception"
    message: str = ""
    traceback_text: str = ""
    occurred_at: datetime = field(default_factory=datetime.now)
    os_name: str = field(default_factory=_describe_os)
    app_version: str = f"{__version__}-{__version_type__}"
    uptime: float = 0.0
    plugin_count: int = 0
    theme_id: str = ""
    platform_detail: str = field(default_factory=platform.platform)
    source: str = ""
    log_dir: str = field(default_factory=lambda: str(LOGS_PATH))
    safe_mode: bool = False

    @property
    def headline(self) -> str:
        detail = self.message.strip().splitlines()[0].strip() if self.message.strip() else ""
        return f"{self.exception_type}: {detail}" if detail else self.exception_type

    @property
    def uptime_text(self) -> str:
        return _format_uptime(self.uptime)

    @property
    def details_text(self) -> str:
        """Text shown inside the collapsible technical detail frame."""
        return self.traceback_text or self.headline

    @property
    def summary_text(self) -> str:
        """Compact, clipboard friendly version of the report."""
        lines = [
            self.headline,
            "",
            f"Class Widgets: {self.app_version}",
            f"System: {self.os_name}",
            f"Platform: {self.platform_detail}",
            f"Uptime: {self.uptime_text}",
            f"Plugins: {self.plugin_count}",
            f"Theme: {self.theme_id or '-'}",
            f"Safe mode: {'yes' if self.safe_mode else 'no'}",
            f"Source: {self.source or '-'}",
            f"Time: {self.occurred_at:%Y-%m-%d %H:%M:%S}",
        ]
        if self.log_dir:
            lines.append(f"Logs: {self.log_dir}")
        if self.traceback_text:
            lines.extend(["", self.traceback_text.rstrip()])
        return "\n".join(lines)


def build_crash_report(
    exc_type: Optional[type[BaseException]] = None,
    exc_value: Optional[BaseException] = None,
    exc_tb: Optional[TracebackType] = None,
    *,
    source: str = "",
    uptime: Optional[float] = None,
    plugin_count: int = 0,
    theme_id: str = "",
    log_dir: Optional[str] = None,
    safe_mode: bool = False,
) -> CrashReport:
    """Build a report from ``sys.exc_info()`` style arguments."""
    if exc_type is None and exc_value is None and exc_tb is None:
        exc_type, exc_value, exc_tb = sys.exc_info()

    if exc_type is None:
        exc_type = type(exc_value) if exc_value is not None else Exception
    exception_type = getattr(exc_type, "__name__", str(exc_type))
    message = str(exc_value) if exc_value is not None else ""

    if exc_tb is not None:
        traceback_text = "".join(traceback.format_exception(exc_type, exc_value, exc_tb))
    else:
        traceback_text = f"{exception_type}: {message}" if message else exception_type

    return CrashReport(
        exception_type=exception_type,
        message=message,
        traceback_text=traceback_text,
        os_name=_describe_os(),
        platform_detail=platform.platform(),
        uptime=(time.monotonic() - PROCESS_START) if uptime is None else uptime,
        plugin_count=plugin_count,
        theme_id=theme_id,
        source=source,
        log_dir=str(LOGS_PATH) if log_dir is None else log_dir,
        safe_mode=safe_mode,
    )
