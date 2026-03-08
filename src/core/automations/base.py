from __future__ import annotations

from typing import Optional, TYPE_CHECKING
from PySide6.QtCore import QObject

if TYPE_CHECKING:
    from src.core.central import AppCentral


class AutomationTask(QObject):
    """自动化任务基类"""
    def __init__(self, central: "AppCentral", parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self.enabled: bool = True  # 默认启用
        self.app_central: "AppCentral" = central

    def update(self) -> None:
        """每秒调用，由 AutomationManager 调度"""
        pass

    @property
    def name(self) -> str:
        return self.__class__.__name__

