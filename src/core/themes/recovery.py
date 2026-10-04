from __future__ import annotations

from PySide6.QtCore import QObject, QTimer, Slot
from loguru import logger

from src.core.themes.manager import DEFAULT_THEME_ID


class ThemeRecoveryController(QObject):
    """Handles asynchronous QML theme-load failures."""

    def __init__(self, theme_manager, window_manager, parent=None) -> None:
        super().__init__(parent)
        self.theme_manager = theme_manager
        self.window_manager = window_manager
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
        logger.error(
            "Theme '{}' failed to load; restoring default theme",
            failed_theme_id,
        )
        recovered = self.theme_manager.rollback_to_default(failed_theme_id)
        if not recovered:
            logger.critical("Unable to recover from theme load failure")

        if not self._dialog_scheduled:
            self._dialog_scheduled = True
            QTimer.singleShot(
                0,
                lambda: self._show_error_dialog(failed_theme_id, recovered),
            )

    @Slot(str)
    def report_component_failure(self, source: str = "") -> None:
        failed_theme_id = self.theme_manager.currentTheme
        logger.error(
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
