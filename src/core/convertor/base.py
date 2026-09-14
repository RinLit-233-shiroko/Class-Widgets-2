import json
from datetime import date, datetime
from pathlib import Path

import yaml
from PySide6.QtCore import QLocale
from PySide6.QtWidgets import QApplication
from loguru import logger

from src import __SCHEDULE_SCHEMA_VERSION__
from src.core.schedule.model import MetaInfo, ScheduleData, Subject, WeekType
from src.core.utils import generate_id


class BaseConverter:
    """Shared utilities and common patterns for all format converters."""

    # ---------------------------
    # Time utilities
    # ---------------------------

    @staticmethod
    def _to_cw_time(time: str | int) -> str:
        """统一时间为 HH:MM 字符串"""
        if isinstance(time, str):
            dt_time = datetime.strptime(str(time), '%H:%M:%S')
        elif isinstance(time, int):
            dt_time = datetime.strptime(f'{int(time / 60 / 60)}:{int(time / 60 % 60)}:{time % 60}', '%H:%M:%S')
        else:
            raise ValueError(f'Get error type of time: {type(time)}; value: {time}')
        return dt_time.strftime("%H:%M")

    @staticmethod
    def _minutes_to_hhmm(total_minutes: int) -> str:
        hours = total_minutes // 60
        minutes = total_minutes % 60
        return f"{hours:02d}:{minutes:02d}"

    @staticmethod
    def _to_cses_time(time_str: str) -> str:
        """统一时间为 HH:MM:SS 字符串，避免 YAML 解析问题"""
        if not time_str:
            raise ValueError(f'Get error type of time: {type(time_str)}; value: {time_str}')
        return str(time_str + ":00")

    # ---------------------------
    # Week utilities
    # ---------------------------

    @staticmethod
    def _convert_weeks_to_cses(weeks, max_week_cycle: int | None = None) -> str:
        """Convert a CW week rule to the CSES all/odd/even vocabulary."""
        if isinstance(weeks, WeekType):
            return weeks.value
        if isinstance(weeks, int) and max_week_cycle == 2:
            if weeks == 1:
                return "odd"
            if weeks == 2:
                return "even"
        return "all"


    # ---------------------------
    # Localization
    # ---------------------------

    @staticmethod
    def get_localized_day_name(dow: int) -> str:
        locale = QLocale()
        return locale.dayName(dow, QLocale.FormatType.LongFormat)

    @staticmethod
    def get_localized_week_label(week_str: str) -> str:
        if week_str == "all":
            return QApplication.translate("Schedule", "All Weeks")
        elif week_str == "odd":
            return QApplication.translate("Schedule", "Odd Weeks")
        elif week_str == "even":
            return QApplication.translate("Schedule", "Even Weeks")
        else:
            return week_str

    # ---------------------------
    # Common builders
    # ---------------------------

    @staticmethod
    def _build_meta() -> MetaInfo:
        return MetaInfo(
            id=generate_id("meta"),
            version=__SCHEDULE_SCHEMA_VERSION__,
            maxWeekCycle=2,
            startDate=str(date.today()),
        )

    # ---------------------------
    # Shared save / export
    # ---------------------------

    @staticmethod
    def _save_cw2_json(schedule: ScheduleData, output: str | Path) -> Path:
        output = Path(output)
        try:
            with open(output, "w", encoding="utf-8") as f:
                json.dump(schedule.model_dump(), f, ensure_ascii=False, indent=2)
            logger.info(f"Converted to CW2 JSON: {output}")
            return output
        except Exception as e:
            logger.error(f"Failed to export to CW2: {e}")
            raise

    @staticmethod
    def _save_cses_yaml(cses: dict, output: str | Path) -> Path:
        output = Path(output)
        try:
            with open(output, "w", encoding="utf-8") as f:
                yaml.safe_dump(cses, f, allow_unicode=True, sort_keys=False)
            logger.info(f"Converted to CSES YAML: {output}")
            return output
        except Exception as e:
            logger.error(f"Failed to export to CSES: {e}")
            raise
