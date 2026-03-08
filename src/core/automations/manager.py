from __future__ import annotations

from typing import TYPE_CHECKING
from PySide6.QtCore import QObject, Signal
from loguru import logger

from .base import AutomationTask

if TYPE_CHECKING:
    from src.core.central import AppCentral
from .builtin_tasks import AutoHideTask
from .update_check import UpdateCheckTask


class AutomationManager(QObject):
    updated = Signal()

    def __init__(self, app_central: "AppCentral") -> None:
        super().__init__()
        self.app_central: "AppCentral" = app_central
        self.tasks: dict[str, AutomationTask] = {}
        # self._init_builtin_tasks()

    def init_builtin_tasks(self) -> None:
        """Instantiate and register all built-in tasks"""
        builtin_tasks = [
            AutoHideTask,
            UpdateCheckTask
        ]
        for task_cls in builtin_tasks:
            task_instance = task_cls(self.app_central)
            self.add_task(task_instance)

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
