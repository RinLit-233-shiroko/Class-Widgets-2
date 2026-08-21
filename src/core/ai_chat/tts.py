from __future__ import annotations

import os
import tempfile
from pathlib import Path
from typing import Optional

import requests
from PySide6.QtCore import QObject, QUrl, QThread, Signal
from PySide6.QtMultimedia import QAudioOutput, QMediaPlayer
from loguru import logger


class SpeechSynthesisWorker(QThread):
    """调用 OpenAI 兼容的 ``/v1/audio/speech`` 接口生成临时 MP3 文件。"""

    generated = Signal(str, str)
    failed = Signal(str)

    def __init__(
        self,
        endpoint: str,
        headers: dict[str, str],
        model: str,
        voice: str,
        speed: float,
        text: str,
    ) -> None:
        super().__init__()
        self.endpoint = endpoint
        self.headers = headers
        self.model = model
        self.voice = voice
        self.speed = speed
        self.text = text

    def run(self) -> None:
        audio_path: Optional[Path] = None
        try:
            response = requests.post(
                self.endpoint,
                headers=self.headers,
                json={
                    "model": self.model,
                    "voice": self.voice,
                    "input": self.text,
                    "response_format": "mp3",
                    "speed": self.speed,
                },
                timeout=(15, 180),
            )
            response.raise_for_status()
            if not response.content:
                raise RuntimeError("The speech service returned an empty audio response.")
            descriptor, filename = tempfile.mkstemp(prefix="classwidgets-tts-", suffix=".mp3")
            os.close(descriptor)
            audio_path = Path(filename)
            audio_path.write_bytes(response.content)
            self.generated.emit(str(audio_path), self.text)
            audio_path = None  # 文件所有权已移交给播放器。
        except requests.RequestException as error:
            logger.warning("AI speech request failed: {}", error)
            self.failed.emit(f"Speech request failed: {error}")
        except Exception as error:
            logger.exception("AI speech processing failed")
            self.failed.emit(str(error))
        finally:
            if audio_path is not None:
                try:
                    audio_path.unlink(missing_ok=True)
                except OSError:
                    logger.debug("Failed to remove temporary speech file {}", audio_path)


class SpeechPlayer(QObject):
    """播放一段临时合成音频，并在结束或出错后自动清理文件。"""

    started = Signal(str)
    finished = Signal()
    failed = Signal(str)

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        # 不在启动时创建底层多媒体设备。这样无音频服务、远程桌面或测试
        # 环境仍可使用文字 AI，对实际播放请求再尝试获取输出设备。
        self._audio_output: Optional[QAudioOutput] = None
        self._player: Optional[QMediaPlayer] = None
        self._audio_path: Optional[Path] = None
        self._playing = False

    @property
    def playing(self) -> bool:
        return self._playing

    def play(self, audio_path: str, text: str) -> None:
        self.stop(cleanup_only=True)
        if not self._ensure_player():
            try:
                Path(audio_path).unlink(missing_ok=True)
            except OSError:
                pass
            self.failed.emit(self.tr("No usable audio output device is available for speech playback."))
            return
        self._audio_path = Path(audio_path)
        self._playing = True
        self._player.setSource(QUrl.fromLocalFile(str(self._audio_path)))
        self._player.play()
        self.started.emit(text)

    def stop(self, cleanup_only: bool = False) -> None:
        if self._player and self._player.playbackState() != QMediaPlayer.PlaybackState.StoppedState:
            self._player.stop()
        had_active_playback = self._playing
        self._playing = False
        self._cleanup_audio_file()
        if had_active_playback and not cleanup_only:
            self.finished.emit()

    def release(self) -> None:
        self.stop(cleanup_only=True)
        if self._player:
            self._player.setSource(QUrl())

    def _ensure_player(self) -> bool:
        if self._player and self._audio_output:
            return True
        try:
            self._audio_output = QAudioOutput(self)
            self._audio_output.setVolume(1.0)
            self._player = QMediaPlayer(self)
            self._player.setAudioOutput(self._audio_output)
            self._player.mediaStatusChanged.connect(self._on_media_status_changed)
            self._player.errorOccurred.connect(self._on_error)
            return True
        except Exception as error:
            logger.warning("Unable to initialize the AI speech player: {}", error)
            self._audio_output = None
            self._player = None
            return False

    def _on_media_status_changed(self, status: QMediaPlayer.MediaStatus) -> None:
        if status == QMediaPlayer.MediaStatus.EndOfMedia and self._playing:
            self._playing = False
            self._cleanup_audio_file()
            self.finished.emit()

    def _on_error(self, _error, error_string: str) -> None:
        if not self._playing:
            return
        self._playing = False
        self._cleanup_audio_file()
        self.failed.emit(error_string or self.tr("The generated speech audio could not be played."))

    def _cleanup_audio_file(self) -> None:
        path = self._audio_path
        self._audio_path = None
        if path:
            try:
                path.unlink(missing_ok=True)
            except OSError:
                logger.debug("Failed to remove temporary speech file {}", path)
