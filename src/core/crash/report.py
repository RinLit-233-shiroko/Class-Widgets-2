from __future__ import annotations

import platform
import sys
import time
import traceback
from dataclasses import dataclass, field
from datetime import datetime
from types import TracebackType
from typing import Optional, Sequence

from loguru import logger

from src import __version__, __version_type__
from src.core.crash.diagnosis import (
    CrashDiagnosis,
    PluginRecord,
    PluginSuspect,
    diagnose_exception,
)
from src.core.directories import LOGS_PATH

#: Used when a report has to estimate the process uptime on its own.
PROCESS_START = time.monotonic()


def _format_uptime(seconds: float) -> str:
    total = max(int(seconds), 0)
    hours, remainder = divmod(total, 3600)
    minutes, secs = divmod(remainder, 60)
    return f"{hours:02d}:{minutes:02d}:{secs:02d}"


def _windows_build_components() -> tuple[int, int]:
    """返回 ``(build, revision)``，即 26200.9457 中的两段；取不到时为 0。"""
    parts = platform.version().split(".")
    try:
        build = int(parts[2])
    except (IndexError, ValueError):
        return 0, 0
    return build, _windows_revision()


def _windows_revision() -> int:
    """从注册表读取 UBR（补丁修订号）。

    ``platform.version()`` 只到构建号（10.0.26200），完整版本需要 UBR。
    """
    try:
        import winreg
    except ImportError:
        return 0
    try:
        with winreg.OpenKey(
            winreg.HKEY_LOCAL_MACHINE,
            r"SOFTWARE\Microsoft\Windows NT\CurrentVersion",
            0,
            winreg.KEY_READ | winreg.KEY_WOW64_64KEY,
        ) as key:
            revision, _ = winreg.QueryValueEx(key, "UBR")
    except OSError:
        return 0
    try:
        return int(revision)
    except (TypeError, ValueError):
        return 0


def _describe_os() -> str:
    """系统名称 + 完整版本号，例如 ``Windows 11 (26200.9457)``。"""
    if platform.system() == "Windows":
        build, revision = _windows_build_components()
        # Windows 11 依旧报告 release "10"，只能用构建号区分。
        name = "Windows 11" if build >= 22000 else f"Windows {platform.release()}"
        if build:
            version = f"{build}.{revision}" if revision else str(build)
            return f"{name} ({version})"
        return name
    return f"{platform.system()} {platform.release()}"


@dataclass(frozen=True)
class CrashReport:
    """A single unhandled exception, formatted for the problem report window."""

    exception_type: str = "Exception"
    message: str = ""
    traceback_text: str = ""
    occurred_at: datetime = field(default_factory=datetime.now)
    os_name: str = field(default_factory=_describe_os)
    app_version: str = f"{__version__}({__version_type__})"
    uptime: float = 0.0
    plugin_count: int = 0
    theme_id: str = ""
    platform_detail: str = field(default_factory=platform.platform)
    source: str = ""
    log_dir: str = field(default_factory=lambda: str(LOGS_PATH))
    safe_mode: bool = False
    #: 归因结论：这次崩溃是不是由某个插件引发。
    diagnosis: CrashDiagnosis = field(default_factory=CrashDiagnosis)

    @property
    def plugin_suspect(self) -> Optional[PluginSuspect]:
        return self.diagnosis.suspect

    @property
    def blames_plugin(self) -> bool:
        return self.diagnosis.blames_plugin

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
        if self.diagnosis.blames_plugin:
            suspect = self.diagnosis.suspect
            lines.append(
                f"Suspect plugin: {suspect.display_name} "
                f"({suspect.plugin_id}) "
                f"[rule={suspect.rule} confidence={suspect.confidence}]"
            )
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
    plugins: Sequence[PluginRecord] = (),
    active_plugin_id: str = "",
) -> CrashReport:
    """Build a report from ``sys.exc_info()`` style arguments.

    ``plugins`` 是当前已知的插件清单，用于按规则判断本次崩溃是否可以归因到
    某个第三方插件。
    """
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

    try:
        diagnosis = diagnose_exception(
            exc_tb,
            exc_value,
            plugins=plugins,
            active_plugin_id=active_plugin_id,
            message=message,
        )
    except Exception:  # 归因失败绝不能反过来干掉报告
        diagnosis = CrashDiagnosis()

    if diagnosis.blames_plugin:
        suspect = diagnosis.suspect
        logger.warning(
            "Crash attributed to plugin {} ({}) by rule {} ({})",
            suspect.display_name,
            suspect.plugin_id,
            suspect.rule,
            suspect.confidence,
        )

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
        diagnosis=diagnosis,
    )
