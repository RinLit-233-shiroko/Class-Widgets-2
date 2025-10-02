import json
import shutil
from datetime import datetime
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property
from loguru import logger

from src.core.models import ScheduleData, MetaInfo
from src.core.parser import ScheduleParser
from src.core.utils import generate_id, get_default_subjects


def _create_empty_schedule():
    return ScheduleData(
        meta=MetaInfo(
            id=generate_id("meta"),
            version=1,
            maxWeekCycle=2,
            startDate=f"{datetime.now().year}-09-01"
        ),
        subjects=get_default_subjects(),
        days=[]
    )


class ScheduleManager(QObject):
    scheduleSwitched = Signal(ScheduleData)
    scheduleModified = Signal(ScheduleData)

    def __init__(self, schedules_dir: Path, app_central):
        super().__init__()
        self.app_central = app_central
        self.schedules_dir = schedules_dir
        self.schedules_dir.mkdir(parents=True, exist_ok=True)
        self.schedule_path: Path = Path(self.schedules_dir) / "schedule.json"
        self.schedule: ScheduleData = _create_empty_schedule()
        self.current_schedule_name: str | None = None  # 当前选中的课程表

    @Slot(str, result=bool)
    def load(self, name: str, force: bool = False) -> bool:
        """加载课程表"""
        if name == self.current_schedule_name and not force:
            return True

        logger.info(f"Loading schedule: {name}")
        path = self.schedules_dir / f"{name}.json"
        self.schedule_path = path
        self.current_schedule_name = name
        self.app_central.configs.schedule.current_schedule = self.current_schedule_name

        parser = ScheduleParser(self.schedule_path)
        try:
            self.schedule = parser.load()
            logger.success(f"Schedule loaded from {self.schedule_path}")
        except FileNotFoundError:
            logger.warning("Schedule file not found, creating a new one...")
            self.schedule = _create_empty_schedule()
            self.save()
        except Exception as e:  # 备份
            logger.error(f"Failed to load schedule: {e}")
            if path.exists():
                backup_path = Path(self.schedule_path / "backup" / f"{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
                logger.info(f"Original schedule backed up to {backup_path.name}")
                self.save(backup_path)
            # 创建空课表
            self.schedule = _create_empty_schedule()
            self.save()
            return False

        self.scheduleSwitched.emit(self.schedule)
        self.scheduleModified.emit(self.schedule)
        return True

    @Slot(result=bool)
    def reload(self):
        """重新加载当前课表"""
        if self.current_schedule_name is None:
            return False
        return self.load(self.current_schedule_name, force=True)

    def modify(self, schedule: ScheduleData):
        """ 接受外部修改（如编辑器）"""
        self.schedule = schedule
        self.scheduleModified.emit(self.schedule)

    @Slot(result=bool)
    def save(self, path: Path | None = None):
        try:
            if path is None:
                path = self.schedule_path
            with open(path, "w", encoding="utf-8") as f:
                json.dump(self.schedule.model_dump(), f, ensure_ascii=False, indent=4)
                logger.success(f"Schedule saved to {path.name}")
                return True
        except Exception as e:
            logger.error(f"Error saving schedule: {e}")
            return False

    @Property(str, notify=scheduleSwitched)
    def currentScheduleName(self) -> str | None:
        return self.current_schedule_name

    #slots
    @Slot(result=list)
    def schedules(self) -> list[dict]:
        """列出当前目录下所有课程表文件，返回dict"""
        files = []
        for p in self.schedules_dir.glob("*.json"):
            files.append({
                "name": p.stem,
                "path": str(p),
                "type": "local"  # 未来可以做拓展
            })
        return files

    @Slot(str)
    def add(self, name: str):
        """创建新的空课表"""
        path = self.schedules_dir / f"{name}.json"
        if path.exists():
            logger.warning(f"Schedule already exists: {name}")
            return False
        new_schedule = _create_empty_schedule()
        try:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(new_schedule.model_dump(), f, ensure_ascii=False, indent=4)
                logger.success(f"New schedule created: {name}")
                return True
        except Exception as e:
            logger.error(f"Error creating new schedule: {e}")
            return False

    @Slot(str)
    def delete(self, name: str) -> bool:
        """删除课表文件"""
        if name == self.current_schedule_name:
            logger.warning(f"Cannot delete current schedule: {name}")
            return False

        path = self.schedules_dir / f"{name}.json"
        if path.exists():
            path.unlink()
            logger.info(f"Schedule deleted: {name}")
            return True
        return False

    @Slot(str, str)
    def duplicate(self, src_name: str, dest_name: str) -> bool:
        """复制课表文件"""
        src_path = self.schedules_dir / f"{src_name}.json"
        dest_path = self.schedules_dir / f"{dest_name}.json"
        if not src_path.exists():
            return False
        shutil.copy(src_path, dest_path)
        logger.success(f"Schedule copied: {src_name} -> {dest_name}")
        return True

    @Slot(str, str, result=bool)
    def rename(self, old_name: str, new_name: str) -> bool:
        """重命名课程表文件"""
        old_path = self.schedules_dir / f"{old_name}.json"
        new_path = self.schedules_dir / f"{new_name}.json"

        if not old_path.exists():
            logger.warning(f"Schedule to rename does not exist: {old_name}")
            return False
        if new_path.exists():
            logger.warning(f"Target schedule name already exists: {new_name}")
            return False

        try:
            old_path.rename(new_path)
            logger.success(f"Schedule renamed: {old_name} -> {new_name}")

            # 要更新 runtime 和当前记录
            if self.current_schedule_name == old_name:
                self.current_schedule_name = new_name
                self.schedule_path = new_path
                self.app_central.configs.schedule.current_schedule = new_name
                self.scheduleSwitched.emit(self.schedule)
                self.scheduleModified.emit(self.schedule)

            return True
        except Exception as e:
            logger.error(f"Failed to rename schedule: {e}")
            return False

    @Slot(str, result=bool)
    def checkNameExists(self, name: str) -> bool:  # validator
        path = self.schedules_dir / f"{name}.json"
        return path.exists()
