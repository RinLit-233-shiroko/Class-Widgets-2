from __future__ import annotations

import sys
import threading
import traceback
from types import TracebackType
from typing import Callable, Optional

from PySide6.QtCore import QObject, Signal
from loguru import logger

from src.core.crash.report import CrashReport, build_crash_report


class CrashHandler(QObject):
    """Turns unhandled exceptions into :class:`CrashReport` objects.

    Installed hooks feed the problem report window, so a crash no longer
    terminates the process silently.  ``crashReported`` is emitted on the
    crashing thread; receivers living in the GUI thread get it queued.
    """

    crashReported = Signal(object)

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._installed = False
        self._previous_excepthook: Optional[Callable] = sys.excepthook
        self._previous_thread_excepthook: Optional[Callable] = threading.excepthook
        self._context_provider: Optional[Callable[[], dict]] = None
        self._handling = False

    # ---------------- setup ----------------
    def set_context_provider(self, provider: Callable[[], dict]) -> None:
        """Register a callable returning extra report fields (uptime, plugins...)."""
        self._context_provider = provider

    def install(self) -> None:
        if self._installed:
            return
        self._previous_excepthook = sys.excepthook
        self._previous_thread_excepthook = threading.excepthook
        sys.excepthook = self._excepthook
        threading.excepthook = self._thread_excepthook
        self._installed = True
        logger.info("Crash handler installed")

    def uninstall(self) -> None:
        if not self._installed:
            return
        if sys.excepthook is self._excepthook and self._previous_excepthook:
            sys.excepthook = self._previous_excepthook
        if threading.excepthook is self._thread_excepthook and self._previous_thread_excepthook:
            threading.excepthook = self._previous_thread_excepthook
        self._installed = False

    # ---------------- hooks ----------------
    def _excepthook(self, exc_type, exc_value, exc_tb) -> None:
        if issubclass(exc_type, KeyboardInterrupt):
            if self._previous_excepthook:
                self._previous_excepthook(exc_type, exc_value, exc_tb)
            return
        self.report_exception(exc_type, exc_value, exc_tb, source="unhandled exception")

    def _thread_excepthook(self, args) -> None:
        thread_name = getattr(getattr(args, "thread", None), "name", "unknown")
        self.report_exception(
            args.exc_type,
            args.exc_value,
            args.exc_traceback,
            source=f"thread '{thread_name}'",
        )

    # ---------------- reporting ----------------
    def report_exception(
        self,
        exc_type: Optional[type[BaseException]],
        exc_value: Optional[BaseException],
        exc_tb: Optional[TracebackType],
        *,
        source: str = "",
    ) -> Optional[CrashReport]:
        if exc_type is None:
            return None

        context: dict = {}
        if self._context_provider is not None:
            try:
                context = self._context_provider() or {}
            except Exception:
                logger.exception("Failed to collect crash context")

        try:
            report = build_crash_report(
                exc_type, exc_value, exc_tb, source=source, **context
            )
        except Exception:
            logger.exception("Failed to build crash report")
            return None

        self._print_traceback(exc_type, exc_value, exc_tb)
        logger.critical("Unhandled exception: {}", report.headline)
        self._dispatch(report)
        return report

    def _dispatch(self, report: CrashReport) -> None:
        if self._handling:
            # A crash inside the report handler itself must not recurse.
            logger.error("Crash report dropped while another report is being handled")
            return

        self._handling = True
        try:
            self.crashReported.emit(report)
        except Exception:
            logger.exception("Failed to deliver crash report")
        finally:
            self._handling = False

    @staticmethod
    def _print_traceback(exc_type, exc_value, exc_tb) -> None:
        stream = getattr(sys, "__stderr__", None) or sys.stderr
        if stream is None:
            return
        try:
            traceback.print_exception(exc_type, exc_value, exc_tb, file=stream)
        except Exception:
            pass
