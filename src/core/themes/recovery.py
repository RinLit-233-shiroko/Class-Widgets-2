from __future__ import annotations

from typing import TYPE_CHECKING

from PySide6.QtCore import QObject, QTimer, Slot
from loguru import logger

from src.core.themes.manager import DEFAULT_THEME_ID


if TYPE_CHECKING:
    from src.core.telemetry import TelemetryService
    from src.core.themes.manager import ThemeManager
    from src.core.windows.manager import AppWindowManager


class ThemeRecoveryController(QObject):
    """Handles asynchronous QML theme-load failures."""

    def __init__(
        self,
        theme_manager: ThemeManager,
        window_manager: AppWindowManager,
        parent: QObject | None = None,
        *,
        telemetry: TelemetryService | None = None,
    ) -> None:
        super().__init__(parent)
        self.theme_manager = theme_manager
        self.window_manager = window_manager
        self.telemetry = telemetry
        self._handling = False
        self._dialog_scheduled = False

    @Slot(str)
    def handle_failure(self, failed_theme_id: str) -> None:
        # A stale Loader error may arrive after the fallback is selected.
        if (
            self.theme_manager.currentTheme == DEFAULT_THEME_ID
            and failed_theme_id != DEFAULT_THEME_ID
        ):
            return
        if self._handling:
            return

        self._handling = True
        logger.bind(telemetry_skip=True).error(
            "Theme '{}' failed to load; restoring default theme",
            failed_theme_id,
        )
        recovered = self.theme_manager.rollback_to_default(failed_theme_id)
        if self.telemetry is not None:
            self.telemetry.capture_failure("theme.load", {
                "component": "theme", "stage": "qml", "theme_id": failed_theme_id,
                "recovered": recovered,
            })
        if not recovered:
            logger.bind(telemetry_skip=True).critical("Unable to recover from theme load failure")

        if not self._dialog_scheduled:
            self._dialog_scheduled = True
            QTimer.singleShot(
                0,
                lambda: self._show_error_dialog(failed_theme_id, recovered),
            )

    @Slot(str)
    def report_component_failure(self, source: str = "") -> None:
        failed_theme_id = str(self.theme_manager.currentTheme)
        logger.bind(telemetry_skip=True).error(
            "Theme component failed to load for theme '{}'{}",
            failed_theme_id,
            f": {source}" if source else "",
        )
        if self._handling:
            return
        QTimer.singleShot(0, lambda: self.handle_failure(failed_theme_id))

    def _show_error_dialog(self, failed_theme_id: str, recovered: bool) -> None:
        self._dialog_scheduled = False
        self.window_manager.open_theme_load_error(failed_theme_id, recovered)
        self._handling = False
