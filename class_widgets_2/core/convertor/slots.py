import json
from pathlib import Path
from PySide6.QtCore import QObject, Slot
from PySide6.QtWidgets import QFileDialog, QApplication
from loguru import logger

from .converter import ScheduleConverter
from class_widgets_2.core.schedule.model import ScheduleData


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
                QApplication.translate("ExportScheduleDialog","Export Schedule"),
                default_name,
                QApplication.translate("ExportScheduleDialog","CSES Format (*.yaml *.yml)")
            )
            if not output_path:
                return False
            ScheduleConverter.from_cw2(path).to_cses(Path(output_path))
            logger.success(f"Exported schedule to {output_path}")
            return True
        except Exception as e:
            logger.exception(f"Export failed: {e}")
            return False

    @Slot(result=bool)
    def importCSES(self) -> bool:
        """导入并转换 CSES"""
        file_path, _ = QFileDialog.getOpenFileName(
            None,
            QApplication.translate("ImportScheduleDialog", "Import CSES Schedule"),
            str(self.manager.schedules_dir),
            QApplication.translate("ImportScheduleDialog", "CSES YAML Files (*.yaml *.yml)")
        )
        if not file_path:
            logger.info("User cancelled import.")
            return False

        try:
            path = Path(file_path)
            if not path.exists():
                logger.error(f"Selected file does not exist: {file_path}")
                return False

            # 转换并保存
            dest_path = self.manager.schedules_dir / f"{path.stem} - CSES.json"
            ScheduleConverter.from_cses(path).to_cw2(dest_path)

            with open(dest_path, "r", encoding="utf-8") as f:
                data = json.load(f)

            self.manager.schedule = ScheduleData.model_validate(data)
            self.manager.current_schedule_name = dest_path.stem
            self.manager.schedule_path = dest_path

            # 保存并触发信号
            self.manager.save()
            self.manager.scheduleSwitched.emit(self.manager.schedule)
            self.manager.scheduleModified.emit(self.manager.schedule)

            logger.success(f"Imported CSES schedule from {file_path}")
            return True
        except Exception as e:
            logger.exception(f"Import failed: {e}")
            return False
