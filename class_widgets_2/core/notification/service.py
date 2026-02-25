from PySide6.QtCore import QObject, Signal, Slot, QUrl
from PySide6.QtMultimedia import QSoundEffect
from pathlib import Path
from loguru import logger

from .model import NotificationProviderConfig
from class_widgets_2.core.directories import ASSETS_PATH


class NotificationService(QObject):
    """通知服务类，管理所有通知相关功能"""
    
    notificationProvidersChanged = Signal()
    
    def __init__(self, notification_manager, config_manager):
        super().__init__()
        self.notification_manager = notification_manager
        self.config_manager = config_manager
        self._sound_effects = {}
        
    @property
    def notificationProviders(self):
        """
        获取所有已注册的通知提供者信息，用于QML界面显示
        """
        return self.notification_manager.get_providers()

    @Slot(str, bool)
    def setNotificationProviderEnabled(self, provider_id, enabled):
        """
        设置特定通知提供者的启用状态
        """
        if provider_id not in self.config_manager.notifications.providers:
            self.config_manager.notifications.providers[provider_id] = NotificationProviderConfig()
        self.config_manager.notifications.providers[provider_id].enabled = enabled

    @Slot(str, bool)
    def setNotificationProviderSystemNotify(self, provider_id, use_system):
        """
        设置特定通知提供者是否使用系统通知
        """
        if provider_id not in self.config_manager.notifications.providers:
            self.config_manager.notifications.providers[provider_id] = NotificationProviderConfig()
        self.config_manager.notifications.providers[provider_id].use_system_notify = use_system

    @Slot(str, bool)
    def setNotificationProviderAppNotify(self, provider_id, use_app):
        """
        设置特定通知提供者是否使用应用内通知
        """
        if provider_id not in self.config_manager.notifications.providers:
            self.config_manager.notifications.providers[provider_id] = NotificationProviderConfig()
        self.config_manager.notifications.providers[provider_id].use_app_notify = use_app

    # === 声音管理方法 ===
    @Slot(int, str)
    def setLevelSound(self, level, sound):
        """设置通知级别对应的声音文件"""
        if not hasattr(self.config_manager.notifications, 'level_sounds'):
            self.config_manager.notifications.level_sounds = {}
        self.config_manager.notifications.level_sounds[str(level)] = sound
        logger.debug(f"Set sound for level {level}: {sound}")

    @Slot(int, result=str)
    def getLevelSound(self, level):
        """获取通知级别对应的声音文件"""
        if not hasattr(self.config_manager.notifications, 'level_sounds'):
            return ""
        return self.config_manager.notifications.level_sounds.get(str(level), "")

    @Slot(int, result=float)
    def getNotificationVolume(self):
        """获取全局通知音量"""
        return getattr(self.config_manager.notifications, 'volume', 1.0)

    @Slot(float)
    def setNotificationVolume(self, volume):
        """设置全局通知音量"""
        self.config_manager.notifications.volume = volume

    @Slot(bool)
    def setNotificationsEnabled(self, enabled):
        """设置全局通知启用状态"""
        self.config_manager.notifications.enabled = enabled

    @Slot(result=bool)
    def getNotificationsEnabled(self):
        """获取全局通知启用状态"""
        return getattr(self.config_manager.notifications, 'enabled', True)

    # === 全局级别声音控制 ===
    @Slot(str, int, result=str)
    def getNotificationProviderLevelSound(self, provider_id, level):
        """获取全局级别声音路径（忽略provider_id参数）"""
        return self.getLevelSound(level)

    @Slot(str, int, str)
    def setNotificationProviderLevelSound(self, provider_id, level, sound):
        """设置全局级别声音路径（忽略provider_id参数）"""
        self.setLevelSound(level, sound)

    @Slot(int, result=str)
    def getGlobalLevelSound(self, level):
        """获取全局级别声音路径"""
        return self.getLevelSound(level)

    @Slot(int, str)
    def setGlobalLevelSound(self, level, sound):
        """设置全局级别声音路径"""
        self.setLevelSound(level, sound)

    @Slot(result=float)
    def getGlobalVolume(self):
        """获取全局通知音量"""
        return getattr(self.config_manager.notifications, 'volume', 1.0)

    @Slot(float)
    def setGlobalVolume(self, volume):
        """设置全局通知音量"""
        self.config_manager.notifications.volume = volume

    @Slot(result=float)
    def getGlobalNotificationVolume(self):
        """获取全局通知音量"""
        return self.getNotificationVolume()

    @Slot(float)
    def setGlobalNotificationVolume(self, volume):
        """设置全局通知音量"""
        self.setNotificationVolume(volume)

    # === 声音播放方法 ===
    @Slot(int)
    def playNotificationSoundLevel(self, level):
        """播放指定级别的通知声音（使用全局配置）"""
        self.playNotificationSound("global", level)

    @Slot(str, int)
    def playNotificationSound(self, provider_id, level):
        """播放通知级别对应的铃声"""
        try:
            if not self.getNotificationsEnabled():
                return

            # 获取全局级别声音配置
            global_level_sounds = getattr(self.config_manager.notifications, 'level_sounds', {})
            custom_sound = global_level_sounds.get(str(level), "")

            # 根据级别设置默认声音文件
            level_audio_mapping = {
                0: "info.wav",      # INFO级别
                1: "announcement.wav", # ANNOUNCEMENT级别
                2: "warning.wav",   # WARNING级别
                3: "system.wav",    # SYSTEM级别
            }
            audio_filename = level_audio_mapping.get(level, "info.wav")

            # 如果配置了自定义声音文件路径，使用自定义路径
            if custom_sound:
                sound_file = custom_sound
            else:
                sound_file = str(ASSETS_PATH / "audio" / audio_filename)

            # 检查声音文件是否存在
            if not Path(sound_file).exists():
                return

            # 使用Qt的QSoundEffect播放声音
            # 创建唯一的键来标识不同的声音效果
            effect_key = f"{provider_id}_{level}"
            
            # 获取或创建声音效果对象
            if effect_key not in self._sound_effects:
                self._sound_effects[effect_key] = QSoundEffect()
            
            effect = self._sound_effects[effect_key]
            
            # 设置声音源
            source_url = QUrl.fromLocalFile(sound_file)
            effect.setSource(source_url)
            
            # 设置音量
            volume = self.getNotificationVolume()
            effect.setVolume(volume)
            
            # 播放声音
            effect.play()
            
        except Exception as e:
            logger.error(f"Failed to play notification sound for provider {provider_id}, level {level}: {e}")

    @Slot(result=bool)
    def selectNotificationSound(self):
        """选择并设置通知声音文件"""
        try:
            from PySide6.QtWidgets import QFileDialog
            
            dialog = QFileDialog()
            dialog.setFileMode(QFileDialog.FileMode.ExistingFile)
            dialog.setNameFilter("Audio Files (*.wav *.mp3 *.ogg)")
            dialog.setWindowTitle("Select Notification Sound")
            
            if dialog.exec() == QFileDialog.DialogCode.Accepted:
                selected_files = dialog.selectedFiles()
                if selected_files:
                    source_path = Path(selected_files[0])
                    target_path = ASSETS_PATH / "audio" / source_path.name
                    
                    # 复制声音文件到assets目录
                    import shutil
                    shutil.copy2(source_path, target_path)
                    
                    # 设置为默认声音
                    self.setLevelSound(1, str(target_path))
                    logger.debug(f"Copied notification sound from {source_path} to {target_path}")
                    return True
            return False
            
        except Exception as e:
            logger.error(f"Failed to select and copy notification sound: {e}")
            return False