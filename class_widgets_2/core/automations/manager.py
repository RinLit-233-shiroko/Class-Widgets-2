from PySide6.QtCore import QObject, Signal
from loguru import logger

from .base import AutomationTask
from .builtin_tasks import AutoHideTask
from .update_check import UpdateCheckTask


class AutomationManager(QObject):
    updated = Signal()

    def __init__(self, app_central):
        super().__init__()
        self.app_central = app_central
        self.tasks: dict[str, AutomationTask] = {}
        # self._init_builtin_tasks()

    def init_builtin_tasks(self):
        """Instantiate and register all built-in tasks"""
        builtin_tasks = [
            AutoHideTask,
            UpdateCheckTask
        ]
        for task_cls in builtin_tasks:
            task_instance = task_cls(self.app_central)
            self.add_task(task_instance)

    def add_task(self, task: AutomationTask):
        """Add a task instance"""
        if not isinstance(task, AutomationTask):
            raise TypeError(f"{task} must be an instance of AutomationTask")

        name = task.name
        if name in self.tasks:
            logger.warning(f"Task '{name}' already exists, overwriting old instance")
        self.tasks[name] = task
        logger.debug(f"Added automation task: {name}")

    def remove_task(self, name: str):
        """Remove a task"""
        if name in self.tasks:
            del self.tasks[name]
            logger.debug(f"Removed automation task: {name}")

    def update(self):
        """Update all active tasks"""
        for task in list(self.tasks.values()):
            if not task.enabled:
                continue
            try:
                task.update()
            except Exception as e:
                logger.error(f"Error executing task '{task.name}': {e}")
        self.updated.emit()
