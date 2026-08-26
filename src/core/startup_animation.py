"""Class Widgets 2 启动动画窗口及其本地媒体配置控制器。"""
from __future__ import annotations

from pathlib import Path

from PySide6.QtCore import (
    QEventLoop,
    QObject,
    Property,
    QTimer,
    QUrl,
    Signal,
    Slot,
)
from PySide6.QtGui import QImageReader
from PySide6.QtMultimedia import QMediaPlayer
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QFileDialog
from loguru import logger

from src.core import QML_PATH


class StartupAnimation(QObject):
    """管理主程序的非全屏启动动画和自定义本地媒体。"""

    changed = Signal()
    finished = Signal()
    MAX_VIDEO_DURATION_MS = 10_000
    IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".bmp", ".webp", ".gif"}
    VIDEO_SUFFIXES = {".mp4", ".webm", ".mov", ".m4v", ".avi"}

    def __init__(self, app_central: QObject):
        super().__init__(app_central)
        self.app = app_central
        self.engine: QQmlApplicationEngine | None = None
        self.root_window = None

    @Property(bool, notify=changed)
    def hasCustomMedia(self) -> bool:
        path = self._media_path()
        return bool(path and path.is_file() and self._media_type() in {"image", "video"})

    @Property(str, notify=changed)
    def mediaPath(self) -> str:
        path = self._media_path()
        return str(path) if path else ""

    @Property(str, notify=changed)
    def mediaName(self) -> str:
        path = self._media_path()
        return path.name if path else ""

    @Property(str, notify=changed)
    def mediaType(self) -> str:
        return self._media_type()

    @Property(str, notify=changed)
    def mediaUrl(self) -> str:
        path = self._media_path()
        return path.resolve().as_uri() if path and path.is_file() else ""

    @Property(int, constant=True)
    def maxVideoDurationSeconds(self) -> int:
        return self.MAX_VIDEO_DURATION_MS // 1000

    def _media_path(self) -> Path | None:
        value = getattr(self.app.configs.app, "startup_animation_media_path", "")
        return Path(value).expanduser() if value else None

    def _media_type(self) -> str:
        return getattr(self.app.configs.app, "startup_animation_media_type", "none")

    def _persist(self) -> None:
        self.app.configs.save(silent=True)
        self.changed.emit()

    @Slot(result=str)
    def selectMedia(self) -> str:
        """选择图片或视频，并仅在校验通过后保存绝对路径。"""
        path, _ = QFileDialog.getOpenFileName(
            None,
            self.tr("Select startup media"),
            "",
            self.tr(
                "Supported media (*.png *.jpg *.jpeg *.bmp *.webp *.gif "
                "*.mp4 *.webm *.mov *.m4v *.avi)"
            ),
        )
        if not path:
            return ""

        return self.setMediaPath(path)

    @Slot(str, result=str)
    def setMediaPath(self, path: str) -> str:
        """校验并保存一个用户指定的本地图片或视频路径。"""
        media_path = Path(path).expanduser().resolve()
        if not media_path.is_file():
            return self.tr("The selected media file does not exist.")

        suffix = media_path.suffix.lower()
        if suffix in self.IMAGE_SUFFIXES:
            reader = QImageReader(str(media_path))
            if not reader.canRead():
                return self.tr("The selected image cannot be read.")
            self._set_media(media_path, "image")
            return ""

        if suffix in self.VIDEO_SUFFIXES:
            duration = self._video_duration_ms(media_path)
            if duration <= 0:
                return self.tr("The selected video could not be read.")
            if duration > self.MAX_VIDEO_DURATION_MS:
                return self.tr("Startup videos must be 10 seconds or shorter.")
            self._set_media(media_path, "video")
            return ""

        return self.tr("Unsupported media format.")

    def _set_media(self, path: Path, media_type: str) -> None:
        self.app.configs.set("app.startup_animation_media_path", str(path))
        self.app.configs.set("app.startup_animation_media_type", media_type)
        self._persist()

    @Slot()
    def clearMedia(self) -> None:
        self.app.configs.set("app.startup_animation_media_path", "")
        self.app.configs.set("app.startup_animation_media_type", "none")
        # 未提供媒体时，始终显示默认 Class Widgets 信息。
        self.app.configs.set("app.startup_animation_show_info", True)
        self._persist()

    def _video_duration_ms(self, path: Path) -> int:
        """通过 Qt 多媒体后端读取时长；读取异常或超时视为无效媒体。"""
        player = QMediaPlayer(self)
        loop = QEventLoop()
        timer = QTimer(self)
        timer.setSingleShot(True)

        def finish_if_ready(duration: int) -> None:
            if duration > 0:
                loop.quit()

        player.durationChanged.connect(finish_if_ready)
        player.mediaStatusChanged.connect(
            lambda status: loop.quit()
            if status == QMediaPlayer.MediaStatus.InvalidMedia
            else None
        )
        timer.timeout.connect(loop.quit)
        player.setSource(QUrl.fromLocalFile(str(path)))
        timer.start(3_000)
        loop.exec()
        duration = player.duration()
        player.deleteLater()
        timer.deleteLater()
        return duration

    def start(self) -> bool:
        """按配置显示启动动画，并返回是否已成功进入动画等待状态。"""
        if not getattr(self.app.configs.app, "startup_animation_enabled", True):
            return False
        if self.engine is not None:
            return True

        self.engine = QQmlApplicationEngine(self)
        self.engine.addImportPath(str(QML_PATH))
        context = self.engine.rootContext()
        context.setContextProperty("StartupAnimationController", self)
        context.setContextProperty("AppCentral", self.app)
        context.setContextProperty("Configs", self.app.configs)
        context.setContextProperty("PathManager", self.app.path_manager)
        self.engine.objectCreated.connect(self._on_object_created)
        self.engine.load(QUrl.fromLocalFile(str(QML_PATH / "StartupAnimation.qml")))

        if not self.engine.rootObjects():
            logger.error("Startup animation QML failed to load")
            self.release()
            return False
        return True

    def _on_object_created(self, obj, _url) -> None:
        if obj is not None and self.root_window is None:
            self.root_window = obj

    @Slot()
    def finish(self) -> None:
        if self.engine is None and self.root_window is None:
            return
        self.release()
        self.finished.emit()

    def release(self) -> None:
        if self.root_window is not None:
            self.root_window.close()
            self.root_window.deleteLater()
            self.root_window = None
        if self.engine is not None:
            self.engine.clearComponentCache()
            self.engine.collectGarbage()
            self.engine.deleteLater()
            self.engine = None
