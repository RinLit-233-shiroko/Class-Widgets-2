from PySide6.QtCore import QDir, QLockFile

class SingleInstanceGuard:
    def __init__(self, lock_name="ClassWidgets2.lock"):
        lock_path = QDir.temp().absoluteFilePath(lock_name)
        self.lock_file = QLockFile(lock_path)
        self.lock_acquired = False

    def try_acquire(self, timeout: int = 100):
        self.lock_acquired = self.lock_file.tryLock(timeout)
        return self.lock_acquired

    def release(self):
        if self.lock_acquired:
            self.lock_file.unlock()

    def get_lock_info(self):
        pid, hostname, appname = self.lock_file.getLockInfo()
        if pid is not None and hostname is not None and appname is not None:
            return {"pid": pid, "hostname": hostname, "appname": appname}
        return None