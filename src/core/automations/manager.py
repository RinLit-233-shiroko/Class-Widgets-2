from __future__ import annotations

from typing import TYPE_CHECKING
from PySide6.QtCore import QObject, Signal
from loguru import logger

from .base import AutomationTask

if TYPE_CHECKING:
    from src.core.central import AppCentral
from .builtin_tasks import AutoHideTask
from .plaza_update_check import PlazaUpdateCheckTask
from .update_check import UpdateCheckTask
from .user_profiles import AutomationProfilesService


class AutomationManager(QObject):
    updated = Signal()

    def __init__(self, app_central: "AppCentral") -> None:
        super().__init__()
        self.app_central: "AppCentral" = app_central
        self.tasks: dict[str, AutomationTask] = {}
        self.user_profiles: AutomationProfilesService | None = None

    def init_builtin_tasks(self) -> None:
        """Instantiate and register all built-in tasks"""
        builtin_tasks = [
            AutoHideTask,
            UpdateCheckTask,
            PlazaUpdateCheckTask,
        ]
        for task_cls in builtin_tasks:
            task_instance = task_cls(self.app_central)
            self.add_task(task_instance)

        self.init_user_profiles()

    def init_user_profiles(self) -> AutomationProfilesService:
        """初始化用户自动化服务；独立设置启动器可按需调用。"""
        if self.user_profiles is None:
            self.user_profiles = AutomationProfilesService(self.app_central)
            self.user_profiles.start()
            self.add_task(self.user_profiles)
        return self.user_profiles

    def add_task(self, task: AutomationTask) -> None:
        """Add a task instance"""
        if not isinstance(task, AutomationTask):
            raise TypeError(f"{task} must be an instance of AutomationTask")

        name = task.name
        if name in self.tasks:
            logger.warning(f"Task '{name}' already exists, overwriting old instance")
        self.tasks[name] = task
        logger.debug(f"Added automation task: {name}")

    def remove_task(self, name: str) -> None:
        """Remove a task"""
        if name in self.tasks:
            del self.tasks[name]
            logger.debug(f"Removed automation task: {name}")

    def stop(self) -> None:
        """停止用户配置的自动化服务，并允许退出触发器收尾。"""
        if self.user_profiles is not None:
            self.user_profiles.stop()

    def update(self) -> None:
        """Update all active tasks"""
        for task in list(self.tasks.values()):
            if not task.enabled:
                continue
            try:
                task.update()
            except Exception as e:
                logger.error(f"Error executing task '{task.name}': {e}")
        self.updated.emit()
