from __future__ import annotations

from pathlib import Path
from typing import Optional

from PySide6.QtCore import QCoreApplication, QObject, Property, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtWidgets import QFileDialog
from loguru import logger

from src.core.crash.report import CrashReport
from src.core.directories import CW_PATH, LOGS_PATH
from src.core.windows.windows import ReleasableWindow


class ProblemReport(ReleasableWindow, QObject):
    """崩溃报告窗口。

    显示未处理异常的信息，并提供重新启动（可进入安全模式）等操作。
    """

    reportChanged = Signal()

    #: 日志导出时附带的最大日志尾部长度。
    _LOG_TAIL_LIMIT = 256 * 1024

    def __init__(self, parent):
        super().__init__(parent)
        self._report: Optional[CrashReport] = None
        self._show_when_ready = False
        self.engine.rootContext().setContextProperty("ProblemReportBridge", self)
        self.engine.objectCreated.connect(self._on_object_created)
        self.load(CW_PATH / "Windows" / "ProblemReport.qml")
        logger.info("Problem report window QML requested")

    # ---------------- 报告内容 / report data ----------------
    @Property(bool, notify=reportChanged)
    def hasReport(self) -> bool:
        return self._report is not None

    @Property(str, notify=reportChanged)
    def headline(self) -> str:
        return self._report.headline if self._report else ""

    @Property(str, notify=reportChanged)
    def osName(self) -> str:
        return self._report.os_name if self._report else ""

    @Property(str, notify=reportChanged)
    def appVersion(self) -> str:
        return self._report.app_version if self._report else ""

    @Property(str, notify=reportChanged)
    def uptimeText(self) -> str:
        return self._report.uptime_text if self._report else ""

    @Property(int, notify=reportChanged)
    def pluginCount(self) -> int:
        return self._report.plugin_count if self._report else 0

    @Property(str, notify=reportChanged)
    def themeId(self) -> str:
        return self._report.theme_id if self._report else ""

    @Property(bool, notify=reportChanged)
    def safeMode(self) -> bool:
        return self._report.safe_mode if self._report else False

    @Property(str, notify=reportChanged)
    def tracebackText(self) -> str:
        return self._report.details_text if self._report else ""

    def set_report(self, report: CrashReport) -> None:
        self._report = report
        self.reportChanged.emit()

    # ---------------- 显示 / show ----------------
    def show_when_ready(self) -> None:
        self._show_when_ready = True
        self._show_root_window()

    def _on_object_created(self, obj, url) -> None:
        if obj is not None:
            logger.info("Problem report root object created")
            self._show_root_window()

    def _show_root_window(self) -> None:
        if not self._show_when_ready or not self.root_window:
            return
        logger.info("Showing problem report window")
        self.root_window.show()
        self.root_window.raise_()
        self.root_window.requestActivate()

    # ---------------- 操作 / actions ----------------
    @Slot()
    def restartInSafeMode(self) -> None:
        logger.warning("Restarting in safe mode from the problem report")
        self.central.restart("--safe-mode")

    @Slot()
    def restartNormally(self) -> None:
        logger.warning("Restarting from the problem report")
        self.central.restart()

    @Slot()
    def ignoreAndContinue(self) -> None:
        logger.warning("User chose to ignore the reported problem")
        self.central.ignore_crash()

    @Slot()
    def copySummary(self) -> None:
        if not self._report:
            return
        try:
            QGuiApplication.clipboard().setText(self._report.summary_text)
        except Exception:
            logger.exception("Failed to copy the crash summary")
            return
        logger.info("Crash summary copied to the clipboard")

    @Slot()
    def exportLogs(self) -> None:
        """把概要、堆栈和最近的日志导出为文本文件。"""
        report = self._report
        if not report:
            return

        suggested = f"ClassWidgets-report-{report.occurred_at:%Y%m%d-%H%M%S}.txt"
        try:
            path, _ = QFileDialog.getSaveFileName(
                None,
                QCoreApplication.translate("ProblemReport", "Export logs"),
                str(Path.home() / suggested),
                "Text files (*.txt)",
            )
        except Exception:
            logger.exception("Failed to open the log export dialog")
            return

        if not path:
            logger.info("Log export cancelled")
            return

        try:
            Path(path).write_text(self._build_export_text(report), encoding="utf-8")
        except Exception:
            logger.exception("Failed to export the crash report")
            return
        logger.success("Crash report exported to {}", path)

    def _build_export_text(self, report: CrashReport) -> str:
        sections = [report.summary_text]
        log_tail = self._read_log_tail()
        if log_tail:
            sections.extend(["", "=" * 72, "Log tail", "=" * 72, log_tail])
        return "\n".join(sections)

    def _read_log_tail(self) -> str:
        try:
            log_files = sorted(
                LOGS_PATH.glob("*.log"),
                key=lambda item: item.stat().st_mtime,
                reverse=True,
            )
        except OSError:
            return ""
        if not log_files:
            return ""

        newest = log_files[0]
        try:
            with newest.open("rb") as handle:
                handle.seek(0, 2)
                size = handle.tell()
                handle.seek(max(0, size - self._LOG_TAIL_LIMIT))
                data = handle.read()
        except OSError:
            logger.exception("Failed to read the log file for export")
            return ""
        return f"# {newest.name}\n" + data.decode("utf-8", errors="replace")
