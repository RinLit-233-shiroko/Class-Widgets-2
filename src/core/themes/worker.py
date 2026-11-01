from __future__ import annotations

import shutil
import zipfile
from collections.abc import Callable
from pathlib import Path
from typing import TYPE_CHECKING

from PySide6.QtCore import QObject, Signal, Slot

if TYPE_CHECKING:
    from src.core.telemetry import TelemetryService
    from src.core.themes.model import ThemeMeta


class ThemeImportWorker(QObject):
    finished = Signal(list)
    error = Signal(str)

    def __init__(
        self,
        zip_path: str | Path,
        external_path: Path,
        scan_func: Callable[[], None],
        metas_ref: list[ThemeMeta],
        *,
        telemetry: TelemetryService | None = None,
    ) -> None:
        super().__init__()
        self.zip_path = zip_path
        self.external_path = external_path
        self.scan_func = scan_func
        self.metas_ref = metas_ref
        self.telemetry = telemetry

    @Slot()
    def run(self) -> None:
        operation = self.telemetry.start_operation("theme.import", {
            "component": "theme", "stage": "import",
        }) if self.telemetry is not None else None
        status = "internal_error"
        try:
            old_ids = {m.get("id", "") for m in self.metas_ref}
            old_meta_by_id = {m.get("id", ""): m for m in self.metas_ref}

            with zipfile.ZipFile(self.zip_path, 'r') as zip_ref:
                members = zip_ref.namelist()
                top_dirs = {Path(m).parts[0] for m in members if not m.endswith('/')}

                # 如果有冲突，先删除现有主题
                for theme_id in old_ids:
                    if theme_id in [m for m in members if m.endswith('cwtheme.json')]:
                        theme_path = self.external_path / theme_id
                        if theme_path.exists():
                            shutil.rmtree(theme_path)

                if len(top_dirs) == 1:
                    zip_ref.extractall(self.external_path)
                else:
                    target_dir = self.external_path / Path(self.zip_path).stem
                    if target_dir.exists():
                        shutil.rmtree(target_dir)
                    zip_ref.extractall(target_dir)

            self.scan_func()
            new_ids = {m.get("id", "") for m in self.metas_ref}
            new_meta_by_id = {m.get("id", ""): m for m in self.metas_ref}

            new_themes = list(new_ids - old_ids)
            updated_themes = list(new_ids & old_ids)

            result = {
                "new_themes": new_themes,
                "updated_themes": updated_themes,
                "all_imported": new_themes + updated_themes
            }
            
            self.finished.emit([result])
            status = "ok"

        except Exception as e:
            if self.telemetry is not None:
                self.telemetry.capture_failure("theme.import", {
                    "component": "theme", "stage": "import",
                }, error=e)
            self.error.emit(str(e))
        finally:
            if operation is not None:
                operation.finish(status)
