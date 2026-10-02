from pathlib import Path

from loguru import logger
from PySide6.QtCore import QObject, Slot
from PySide6.QtWidgets import QApplication, QFileDialog

from .converter import FORMATS, convert, read, write


class ScheduleIO(QObject):
    def __init__(self, parent):
        super().__init__()
        self.manager = parent

    @Slot(str, result=bool)
    def exportToCSES(self, filename: str) -> bool:
        """Export current CW2 schedule to CSES YAML file."""
        try:
            path = self.manager.schedules_dir / f"{filename}.json"
            default_name = path.stem + ".yaml"
            output_path, _ = QFileDialog.getSaveFileName(
                None,
                QApplication.translate("ExportScheduleDialog", "Export Schedule"),
                default_name,
                QApplication.translate(
                    "ExportScheduleDialog", "CSES Format (*.yaml *.yml)"
                ),
            )
            if not output_path:
                return False
            convert(path, "cw2", Path(output_path), "cses")
            logger.success(f"Exported schedule to {output_path}")
            return True
        except Exception as e:
            logger.exception(f"Export failed: {e}")
            return False

    def _available_schedule_path(self, source_stem: str, suffix: str) -> Path:
        base = f"{source_stem} - {suffix}"
        candidate = self.manager.schedules_dir / f"{base}.json"
        index = 2
        while candidate.exists():
            candidate = self.manager.schedules_dir / f"{base} ({index}).json"
            index += 1
        return candidate

    def _commit_import(self, schedule, dest_path: Path, format_id: str) -> bool:
        self.manager.schedule = schedule
        self.manager.current_schedule_name = dest_path.stem
        self.manager.schedule_path = dest_path
        self.manager.save()
        self.manager.scheduleSwitched.emit(self.manager.schedule)
        self.manager.scheduleModified.emit(self.manager.schedule)
        logger.success(f"Imported {format_id.upper()} schedule to {dest_path.name}")
        return True

    def _import_as_cw2(
        self,
        format_id: str,
        dialog_title: str,
        file_filter: str,
        output_suffix: str,
    ) -> bool:
        file_path, _ = QFileDialog.getOpenFileName(
            None,
            dialog_title,
            str(self.manager.schedules_dir),
            file_filter,
        )
        if not file_path:
            logger.info("User cancelled import.")
            return False

        try:
            path = Path(file_path)
            if not path.exists():
                logger.error(f"Selected file does not exist: {file_path}")
                return False

            schedule = read(path, format_id)
            dest_path = self._available_schedule_path(path.stem, output_suffix)
            write(schedule, dest_path, "cw2")
            return self._commit_import(schedule, dest_path, format_id)
        except Exception as e:
            logger.exception(f"Import failed: {e}")
            return False

    def _file_filter(self, format_id: str) -> tuple[str, str]:
        options = {
            "cw2": ("Import Class Widgets 2 Schedule", "Class Widgets 2 JSON Files (*.json)"),
            "cses": ("Import CSES Schedule", "CSES YAML Files (*.yaml *.yml)"),
            "cw1": ("Import Class Widgets 1 Schedule", "Class Widgets 1 JSON Files (*.json)"),
            "ics": ("Import ICS Schedule", "iCalendar Files (*.ics *.ical)"),
        }
        return options.get(format_id, ("Import Schedule", "Schedule Files (*)"))

    @Slot(str, result=str)
    def selectImportFile(self, format_id: str) -> str:
        title, file_filter = self._file_filter(format_id)
        file_path, _ = QFileDialog.getOpenFileName(
            None,
            QApplication.translate("ImportScheduleDialog", title),
            str(self.manager.schedules_dir),
            QApplication.translate("ImportScheduleDialog", file_filter),
        )
        if not file_path:
            logger.info("User cancelled import.")
            return ""
        return file_path

    @Slot(str, result=str)
    def selectICSFile(self) -> str:
        return self.selectImportFile("ics")

    @Slot(str, str, result=bool)
    def validateImportFile(self, file_path: str, format_id: str) -> bool:
        path = Path(file_path)
        if not path.exists():
            return False
        module = FORMATS.get(format_id)
        if module is None:
            return False
        validator = getattr(module, "validate", None)
        if validator:
            return bool(validator(path))
        try:
            read(path, format_id)
            return True
        except Exception:
            logger.exception(f"Failed to validate {format_id} schedule: {file_path}")
            return False

    @Slot(str, str, str, result=int)
    def getImportMaxWeekCycle(self, file_path: str, format_id: str, start_date: str) -> int:
        try:
            if format_id == "ics":
                schedule = read(file_path, format_id, start_date=start_date)
            else:
                schedule = read(file_path, format_id)
            return schedule.meta.maxWeekCycle
        except Exception:
            logger.exception(f"Failed to inspect {format_id} schedule: {file_path}")
            return 1

    @Slot(str, str, str, str, result=bool)
    def importScheduleFile(
        self,
        file_path: str,
        format_id: str,
        start_date: str,
        name: str,
    ) -> bool:
        try:
            path = Path(file_path)
            if not path.exists() or not name or self.manager.checkNameExists(name):
                return False

            schedule = read(path, format_id, start_date=start_date)
            schedule.meta.startDate = start_date
            dest_path = self.manager.schedules_dir / f"{name}.json"
            write(schedule, dest_path, "cw2")
            return self._commit_import(schedule, dest_path, format_id)
        except Exception as e:
            logger.exception(f"Import failed: {e}")
            return False

    @Slot(str, str, result=bool)
    def importICS(self, file_path: str, start_date: str) -> bool:
        name = f"{Path(file_path).stem} - ICS"
        return self.importScheduleFile(file_path, "ics", start_date, name)

    @Slot(result=bool)
    def importCSES(self) -> bool:
        """Import a CSES schedule and convert it to CW2."""
        return self._import_as_cw2(
            format_id="cses",
            dialog_title=QApplication.translate(
                "ImportScheduleDialog", "Import CSES Schedule"
            ),
            file_filter=QApplication.translate(
                "ImportScheduleDialog", "CSES YAML Files (*.yaml *.yml)"
            ),
            output_suffix="CSES",
        )

    @Slot(result=bool)
    def importCW1(self) -> bool:
        """Import a Class Widgets 1 schedule and convert it to CW2."""
        return self._import_as_cw2(
            format_id="cw1",
            dialog_title=QApplication.translate(
                "ImportScheduleDialog", "Import Class Widgets 1 Schedule"
            ),
            file_filter=QApplication.translate(
                "ImportScheduleDialog", "Class Widgets 1 JSON Files (*.json)"
            ),
            output_suffix="CW1",
        )
