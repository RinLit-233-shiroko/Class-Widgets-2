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
    pluginStateChanged = Signal()

    #: 日志导出时附带的最大日志尾部长度。
    _LOG_TAIL_LIMIT = 256 * 1024

    def __init__(self, parent):
        super().__init__(parent)
        self._report: Optional[CrashReport] = None
        self._plugin_disabled = False
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

    # ---------------- 智能检测 / plugin attribution ----------------
    @Property(bool, notify=reportChanged)
    def pluginDetected(self) -> bool:
        """本次崩溃是否被归因到某个第三方插件。"""
        return bool(self._report and self._report.blames_plugin)

    @Property(str, notify=reportChanged)
    def pluginName(self) -> str:
        suspect = self._report.plugin_suspect if self._report else None
        return suspect.display_name if suspect else ""

    @Property(str, notify=reportChanged)
    def pluginId(self) -> str:
        suspect = self._report.plugin_suspect if self._report else None
        return suspect.plugin_id if suspect else ""

    @Property(str, notify=reportChanged)
    def pluginVersion(self) -> str:
        suspect = self._report.plugin_suspect if self._report else None
        return suspect.version if suspect else ""

    @Property(str, notify=reportChanged)
    def pluginIcon(self) -> str:
        suspect = self._report.plugin_suspect if self._report else None
        return suspect.icon if suspect else ""

    @Property(bool, notify=pluginStateChanged)
    def pluginDisabled(self) -> bool:
        """插件当前是否已禁用（用户点过，或本来就没启用）。"""
        return self._plugin_disabled

    @Property(bool, notify=pluginStateChanged)
    def pluginDisableAvailable(self) -> bool:
        """能不能从报告窗口直接禁用这个插件。"""
        suspect = self._report.plugin_suspect if self._report else None
        if suspect is None or suspect.builtin or self._plugin_disabled:
            return False
        plugin_manager = getattr(self.central, "plugin_manager", None)
        if plugin_manager is None:
            return False
        try:
            if self.central.configs.isKeyLocked("plugins.enabled"):
                return False
        except Exception:
            return False
        return True

    def _suspect_is_enabled(self) -> bool:
        suspect = self._report.plugin_suspect if self._report else None
        if suspect is None:
            return False
        plugin_manager = getattr(self.central, "plugin_manager", None)
        if plugin_manager is None:
            return False
        try:
            return bool(plugin_manager.isPluginEnabled(suspect.plugin_id))
        except Exception:
            return False

    def set_report(self, report: CrashReport) -> None:
        self._report = report
        # 插件本来就没启用时直接呈现“已禁用”，不给用户一个按了没反应的按钮。
        self._plugin_disabled = report.blames_plugin and not self._suspect_is_enabled()
        self.reportChanged.emit()
        self.pluginStateChanged.emit()

    @Slot()
    def disableDetectedPlugin(self) -> None:
        """禁用被归因的插件，并立刻落盘（不能反悔）。"""
        suspect = self._report.plugin_suspect if self._report else None
        if suspect is None or self._plugin_disabled:
            return
        if not self.pluginDisableAvailable:
            logger.warning(
                "Disabling plugin {} from the problem report is not available",
                suspect.plugin_id,
            )
            return

        plugin_manager = getattr(self.central, "plugin_manager", None)
        try:
            plugin_manager.setPluginEnabled(suspect.plugin_id, False)
            self.central.configs.save(silent=True)
        except Exception:
            logger.exception("Failed to disable plugin {}", suspect.plugin_id)
            return

        self._plugin_disabled = True
        self.pluginStateChanged.emit()
        logger.success(
            "Plugin {} ({}) disabled from the problem report",
            suspect.display_name,
            suspect.plugin_id,
        )

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
