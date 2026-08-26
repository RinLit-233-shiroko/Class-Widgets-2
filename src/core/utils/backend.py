import platform
import json
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import Property, Slot, QObject, Signal, QCoreApplication
from PySide6.QtGui import QGuiApplication
from loguru import logger

from src.core.directories import LOGS_PATH, ROOT_PATH
from src.core.notification import NotificationProvider
from src.core.utils.auto_startup import autostart_supported, enable_autostart, disable_autostart, is_autostart_enabled


class UtilsBackend(QObject):
    logsUpdated = Signal()
    extraSettingsChanged = Signal()
    licenseLoaded = Signal()
    notificationProvidersChanged = Signal()
    shortcutsChanged = Signal()

    MAX_LOG_LINES = 200

    def __init__(self, app):
        super().__init__()
        self.app = app
        self.notification_service = app.notification_service
        self._extra_settings: list = []
        self._license_text: str = ""
        self._logs: list = []
        self._log_buffer_bytes = 0
        self._log_buffer_peak_bytes = 0
        self.app.plugin_api.ui.settingsPageRegistered.connect(lambda: self.extraSettingsChanged.emit())
        self.app.plugin_api.ui.shortcutsChanged.connect(self.shortcutsChanged.emit)
        self.app.configs.configChanged.connect(self.shortcutsChanged.emit)
        self.debugPostProvider = None
        self._register_debug_provider()

        # 连接到retranslate信号，在翻译加载后更新通知提供者名称
        self.app.retranslate.connect(self._on_retranslate)

        # 音频播放对象已委托给 NotificationService
        # self._sound_effects = {}

        # 执行初始化逻辑
        self._init_logger()
        self.load_license()  # 启动时立即加载

    def _register_debug_provider(self):
        """注册调试通知提供者，确保在翻译加载后执行"""
        if self.debugPostProvider is not None:
            return
            
        self.debugPostProvider = NotificationProvider(
            id="com.classwidgets.debug",
            name=QCoreApplication.translate("NotificationProviders", "Debug Notification"),
            manager=self.app.notification,
            # icon=Path( ASSETS_PATH / "images" / "logo.png" ),
            use_system_notify=True,
            icon="ic_fluent_code_20_regular"
        )

    @Slot()
    def _on_retranslate(self):
        """处理翻译信号，重新注册通知提供者"""
        if self.debugPostProvider:
            # 取消注册旧的provider
            self.app.notification.unregister_provider("com.classwidgets.debug")
            self.debugPostProvider = None
            
        # 重新注册provider，使用新的翻译
        self._register_debug_provider()

    def _init_logger(self):
        """配置 Loguru 钩子"""
        logger.add(self._capture_log, level="DEBUG", enqueue=True)

    def _capture_log(self, message):
        """Loguru 回调函数"""
        record = message.record
        log_entry = {
            "time": record["time"].strftime("%H:%M:%S"),
            "level": record["level"].name,
            "message": record["message"]
        }
        entry_size = len(json.dumps(log_entry, ensure_ascii=False).encode("utf-8"))
        self._logs.append(log_entry)
        self._log_buffer_bytes += entry_size

        if len(self._logs) > self.MAX_LOG_LINES:
            removed_entry = self._logs.pop(0)
            self._log_buffer_bytes -= len(
                json.dumps(removed_entry, ensure_ascii=False).encode("utf-8")
            )

        self._log_buffer_peak_bytes = max(self._log_buffer_peak_bytes, self._log_buffer_bytes)
        self.logsUpdated.emit()

    @Property("QVariantList", notify=logsUpdated)
    def logs(self):
        return self._logs

    @Property(int, notify=logsUpdated)
    def logCount(self) -> int:
        return len(self._logs)

    @Property(int, constant=True)
    def maxLogLines(self) -> int:
        return self.MAX_LOG_LINES

    @Property(int, notify=logsUpdated)
    def logBufferBytes(self) -> int:
        return self._log_buffer_bytes

    @Property(int, notify=logsUpdated)
    def logBufferPeakBytes(self) -> int:
        return self._log_buffer_peak_bytes

    @Property(str, notify=logsUpdated)
    def logFirstTime(self) -> str:
        return self._logs[0]["time"] if self._logs else ""

    @Property(str, notify=logsUpdated)
    def logLastTime(self) -> str:
        return self._logs[-1]["time"] if self._logs else ""

    @Slot(result=bool)
    def clearMemoryLogs(self) -> bool:
        self._logs.clear()
        self._log_buffer_bytes = 0
        self.logsUpdated.emit()
        return True

    def get_log_snapshot(self, limit: int = MAX_LOG_LINES) -> list[dict]:
        safe_limit = max(0, min(limit, self.MAX_LOG_LINES))
        if safe_limit == 0:
            return []
        return [dict(item) for item in self._logs[-safe_limit:]]

    @Slot(result=list)
    def clearLogs(self):
        """清理物理日志文件"""
        try:
            size = 0
            if LOGS_PATH.exists():
                for file in LOGS_PATH.glob("**/*"):
                    if file.is_file():
                        try:
                            file_size = file.stat().st_size / 1024 # kb
                            file.unlink()
                            size += file_size
                        except PermissionError:
                            logger.debug(f"Permission denied: {file.name}")
            return True, round(size, 2)
        except Exception as e:
            logger.exception(f"Failed to clear logs: {e}")
            return [False, 0]

    # 设置与插件
    @Property(list, notify=extraSettingsChanged)
    def extraSettings(self):
        return self.app.plugin_api.ui.pages

    @Property(list, notify=shortcutsChanged)
    def shortcuts(self):
        configured_ids = self.app.configs.preferences.shortcuts
        registered = {shortcut["id"]: shortcut for shortcut in self.app.plugin_api.ui.shortcuts}
        return [dict(registered[shortcut_id]) for shortcut_id in configured_ids if shortcut_id in registered]

    @Property(list, notify=shortcutsChanged)
    def availableShortcuts(self):
        configured_ids = set(self.app.configs.preferences.shortcuts)
        return [
            dict(shortcut)
            for shortcut in self.app.plugin_api.ui.shortcuts
            if shortcut["id"] not in configured_ids
        ]

    @Slot(str, result=bool)
    def executeShortcut(self, shortcut_id: str) -> bool:
        return self.app.plugin_api.ui.invoke_shortcut(shortcut_id)

    @Slot(str, bool, result=bool)
    def setShortcutEnabled(self, shortcut_id: str, enabled: bool) -> bool:
        config_key = "preferences.shortcuts"
        if self.app.configs.isKeyLocked(config_key):
            logger.warning(f"Attempt to modify locked config key: {config_key}. Blocked.")
            return False

        shortcuts = list(self.app.configs.preferences.shortcuts)
        if enabled and shortcut_id not in shortcuts:
            shortcuts.append(shortcut_id)
        elif not enabled and shortcut_id in shortcuts:
            shortcuts.remove(shortcut_id)
        else:
            return True

        self.app.configs.preferences.shortcuts = shortcuts
        return True

    @Slot(str, int, result=bool)
    def moveShortcutTo(self, shortcut_id: str, target_index: int) -> bool:
        """Move an enabled shortcut to a visible shortcut index."""
        config_key = "preferences.shortcuts"
        if self.app.configs.isKeyLocked(config_key):
            return False

        shortcuts = list(self.app.configs.preferences.shortcuts)
        registered_ids = {shortcut["id"] for shortcut in self.app.plugin_api.ui.shortcuts}
        visible_ids = [shortcut for shortcut in shortcuts if shortcut in registered_ids]
        try:
            source_index = visible_ids.index(shortcut_id)
        except ValueError:
            return False

        target_index = max(0, min(target_index, len(visible_ids) - 1))
        if source_index == target_index:
            return True

        target_id = visible_ids[target_index]
        shortcuts.remove(shortcut_id)
        target_position = shortcuts.index(target_id)
        if target_index > source_index:
            target_position += 1
        shortcuts.insert(target_position, shortcut_id)
        self.app.configs.preferences.shortcuts = shortcuts
        return True

    # 设置功能
    @Property(str, notify=licenseLoaded)
    def licenseText(self):
        return self._license_text

    @Property(QObject, constant=True)
    def debugNotificationProvider(self):
        """
        暴露给 QML 的调试通知 Provider
        """
        return self.debugPostProvider

    def load_license(self):
        try:
            license_path = ROOT_PATH / "LICENSE"
            if license_path.exists():
                with open(license_path, "r", encoding="utf-8") as f:
                    self._license_text = f.read()
            else:
                self._license_text = "License file not found."
        except Exception as e:
            logger.error(f"Failed to load license: {e}")
            self._license_text = "Error loading license."
        finally:
            self.licenseLoaded.emit()

    @Slot(str, result=bool)
    def copyToClipboard(self, text):
        try:
            clipboard = QGuiApplication.clipboard()
            clipboard.setText(text)
            return True
        except Exception as e:
            logger.error(f"Failed to copy to clipboard: {e}")
            return False

    # 自启动
    @Property(bool, constant=True)
    def autostartSupported(self):
        return autostart_supported()

    @Slot(bool, result=bool)
    def setAutostart(self, enabled):
        if enabled:
            enable_autostart()
        else:
            disable_autostart()
        return is_autostart_enabled()

    @Slot(result=bool)
    def autostartEnabled(self):
        return autostart_supported() and is_autostart_enabled()

    @Slot(result=bool)
    def createDesktopShortcut(self) -> bool:
        """Create a Windows desktop shortcut for the packaged application."""
        if platform.system() != "Windows":
            return False

        target = Path(sys.executable) if getattr(sys, "frozen", False) else None
        if target is None or not target.is_file():
            logger.warning("Desktop shortcut is only available for packaged builds.")
            return False

        script = (
            "$shell = New-Object -ComObject WScript.Shell; "
            "$desktop = [Environment]::GetFolderPath('Desktop'); "
            "$shortcut = $shell.CreateShortcut((Join-Path $desktop 'Class Widgets 2.lnk')); "
            "$shortcut.TargetPath = $args[0]; "
            "$shortcut.WorkingDirectory = $args[1]; "
            "$shortcut.IconLocation = $args[2]; "
            "$shortcut.Save()"
        )
        try:
            subprocess.run(
                [
                    "powershell", "-NoProfile", "-NonInteractive", "-Command", script,
                    str(target), str(target.parent), f"{target},0",
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            return True
        except (OSError, subprocess.CalledProcessError) as error:
            logger.exception("Failed to create desktop shortcut: {}", error)
            return False



    @Property(list, notify=notificationProvidersChanged)
    def notificationProviders(self):
        """
        获取所有已注册的通知提供者信息，用于QML界面显示
        """
        return self.notification_service.notificationProviders

    @Slot(str, bool)
    def setNotificationProviderEnabled(self, provider_id, enabled):
        """
        设置特定通知提供者的启用状态
        """
        self.notification_service.setNotificationProviderEnabled(provider_id, enabled)

    @Slot(str, bool)
    def setNotificationProviderSystemNotify(self, provider_id, use_system):
        """
        设置特定通知提供者是否使用系统通知
        """
        self.notification_service.setNotificationProviderSystemNotify(provider_id, use_system)

    @Slot(str, bool)
    def setNotificationProviderAppNotify(self, provider_id, use_app):
        """
        设置特定通知提供者是否使用应用内通知
        """
        self.notification_service.setNotificationProviderAppNotify(provider_id, use_app)

    @Slot(int, str)
    def setLevelSound(self, level, sound):
        """
        设置特定通知级别的音频文件路径
        """
        self.notification_service.setLevelSound(level, sound)

    @Slot(int, result=str)
    def getLevelSound(self, level):
        """
        获取特定通知级别的音频文件路径
        """
        return self.notification_service.getLevelSound(level)

    @Slot(float)
    def setGlobalVolume(self, volume):
        """
        设置全局通知音量
        """
        self.notification_service.setNotificationVolume(volume)

    @Slot(result=float)
    def getGlobalVolume(self):
        """
        获取全局通知音量
        """
        return self.notification_service.getNotificationVolume()

    # 全局通知启用控制
    @Slot(result=bool)
    def getNotificationsEnabled(self):
        """
        获取全局通知启用状态
        """
        return self.notification_service.getNotificationsEnabled()

    @Slot(bool)
    def setNotificationsEnabled(self, enabled):
        """
        设置全局通知启用状态
        """
        self.notification_service.setNotificationsEnabled(enabled)

    # 全局音量控制（兼容旧接口）
    @Slot(str, result=float)
    def getNotificationProviderVolume(self, provider_id):
        """
        获取全局通知音量（忽略provider_id参数）
        """
        return self.notification_service.getNotificationVolume()

    @Slot(str, float)
    def setNotificationProviderVolume(self, provider_id, volume):
        """
        设置全局通知音量（忽略provider_id参数）
        """
        self.notification_service.setNotificationVolume(volume)

    # 全局级别声音控制（兼容旧接口）
    @Slot(str, int, result=str)
    def getNotificationProviderLevelSound(self, provider_id, level):
        """
        获取全局级别声音路径（忽略provider_id参数）
        """
        return self.notification_service.getNotificationProviderLevelSound(provider_id, level)

    @Slot(str, int, str)
    def setNotificationProviderLevelSound(self, provider_id, level, sound):
        """
        设置全局级别声音路径（忽略provider_id参数）
        """
        self.notification_service.setNotificationProviderLevelSound(provider_id, level, sound)

    # 简化的全局级别声音控制方法
    @Slot(int, result=str)
    def getGlobalLevelSound(self, level):
        """
        获取全局级别声音路径
        """
        return self.notification_service.getGlobalLevelSound(level)

    @Slot(int, str)
    def setGlobalLevelSound(self, level, sound):
        """
        设置全局级别声音路径
        """
        self.notification_service.setGlobalLevelSound(level, sound)

    # 简化的全局音量控制方法
    @Slot(result=float)
    def getGlobalVolume(self):
        """
        获取全局通知音量
        """
        return self.notification_service.getGlobalVolume()

    @Slot(float)
    def setGlobalVolume(self, volume):
        """
        设置全局通知音量
        """
        self.notification_service.setGlobalVolume(volume)

    # 简化的播放声音方法
    @Slot(int)
    def playNotificationSoundLevel(self, level):
        """
        播放指定级别的通知声音（使用全局配置）
        """
        self.notification_service.playNotificationSoundLevel(level)

    @Slot(str, int)
    def playNotificationSound(self, provider_id, level):
        """
        播放通知级别对应的铃声
        空值代表使用默认，有值代表使用自定义音频文件
        """
        self.notification_service.playNotificationSound(provider_id, level)

    @Slot(int, result=str)
    def selectNotificationSound(self, level: int):
        """
        打开文件选择器，让用户选择音频文件，并将其复制到应用配置目录下
        """
        return self.notification_service.selectNotificationSound(level)
