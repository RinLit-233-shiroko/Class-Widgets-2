from PySide6.QtCore import QObject, QTimer, Signal
from datetime import datetime

class UnionUpdateTimer(QObject):
    tick = Signal()  # 每秒触发一次

    def __init__(self, parent=None):
        super().__init__(parent)
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._check_time)
        self._last_second = None

    def start(self):
        now = datetime.now()
        self._last_second = now.second
        self._timer.start(50)

    def stop(self):
        self._timer.stop()

    def _check_time(self):
        now = datetime.now()
        if now.second != self._last_second:
            self._last_second = now.second
            self.tick.emit()
