from PySide6.QtCore import QObject


class AutomationTask(QObject):
    """自动化任务基类"""
    def __init__(self, central, parent=None):
        super().__init__(parent)
        self.enabled = True  # 默认启用
        self.app_central = central

    def update(self):
        """每秒调用，由 AutomationManager 调度"""
        pass

    @property
    def name(self):
        return self.__class__.__name__

