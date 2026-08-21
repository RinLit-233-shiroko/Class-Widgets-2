from __future__ import annotations

import os
import tempfile
import threading
import wave
from pathlib import Path
from typing import Optional

from PySide6.QtCore import QObject, Property, Signal, Slot
from loguru import logger

try:
    import sounddevice as sd
except (ImportError, OSError):  # 在未安装依赖或缺少 PortAudio 的环境中保持可启动。
    sd = None


class MicrophoneRecorder(QObject):
    """使用默认系统麦克风录制 16 kHz 单声道 WAV 文件。

    录制工作在守护线程中执行，避免音频 I/O 阻塞 QML 主线程。输出文件由
    调用方负责删除；这样语音转写线程能够在录制结束后安全地读取该文件。
    """

    recordingChanged = Signal()
    recorded = Signal(str)
    errorOccurred = Signal(str)

    SAMPLE_RATE = 16_000
    CHANNELS = 1
    SAMPLE_WIDTH = 2

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._recording = False
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None
        self._output_path: Optional[Path] = None
        self._lock = threading.Lock()

    @Property(bool, notify=recordingChanged)
    def recording(self) -> bool:
        return self._recording

    def _set_recording(self, value: bool) -> None:
        if self._recording == value:
            return
        self._recording = value
        self.recordingChanged.emit()

    @Slot()
    def start(self) -> None:
        """开始录音；录制结果会通过 ``recorded`` 信号异步返回。"""
        if sd is None:
            self.errorOccurred.emit(self.tr("Microphone support is unavailable because sounddevice is not installed."))
            return
        with self._lock:
            if self._thread and self._thread.is_alive():
                return
            descriptor, filename = tempfile.mkstemp(prefix="classwidgets-ai-", suffix=".wav")
            os.close(descriptor)
            self._output_path = Path(filename)
            self._stop_event.clear()
            self._set_recording(True)
            self._thread = threading.Thread(
                target=self._record_worker,
                name="AiChatRecorder",
                daemon=True,
            )
            self._thread.start()

    @Slot()
    def stop(self) -> None:
        """请求结束录音；WAV 写入完成后发出 ``recorded`` 信号。"""
        if self._recording:
            self._stop_event.set()

    def release(self) -> None:
        """停止录音并清理尚未交给转写服务的临时文件。"""
        self._stop_event.set()
        thread = self._thread
        if thread and thread.is_alive():
            thread.join(timeout=2.0)
        path = self._output_path
        if path and path.exists():
            try:
                path.unlink()
            except OSError:
                logger.debug("Failed to remove temporary recording {}", path)
        self._thread = None
        self._output_path = None
        self._set_recording(False)

    def _record_worker(self) -> None:
        output_path = self._output_path
        chunks: list[bytes] = []
        failure: Optional[str] = None

        def on_audio(indata, _frames, _time_info, status) -> None:
            if status:
                logger.warning("AI microphone input status: {}", status)
            chunks.append(bytes(indata))

        try:
            with sd.RawInputStream(
                samplerate=self.SAMPLE_RATE,
                blocksize=0,
                device=None,
                channels=self.CHANNELS,
                dtype="int16",
                callback=on_audio,
            ):
                while not self._stop_event.wait(0.1):
                    pass
        except Exception as error:
            logger.exception("AI microphone recording failed")
            failure = str(error)

        if failure:
            if output_path and output_path.exists():
                try:
                    output_path.unlink()
                except OSError:
                    pass
            self._output_path = None
            self.errorOccurred.emit(self.tr("Unable to record from the microphone: {0}").format(failure))
        elif output_path and chunks:
            try:
                with wave.open(str(output_path), "wb") as wav_file:
                    wav_file.setnchannels(self.CHANNELS)
                    wav_file.setsampwidth(self.SAMPLE_WIDTH)
                    wav_file.setframerate(self.SAMPLE_RATE)
                    wav_file.writeframes(b"".join(chunks))
                self.recorded.emit(str(output_path))
            except Exception as error:
                logger.exception("Failed to write AI microphone recording")
                try:
                    output_path.unlink(missing_ok=True)
                except OSError:
                    pass
                self._output_path = None
                self.errorOccurred.emit(self.tr("Unable to save microphone recording: {0}").format(error))
        else:
            if output_path:
                try:
                    output_path.unlink(missing_ok=True)
                except OSError:
                    pass
            self._output_path = None
            self.errorOccurred.emit(self.tr("No audio was captured. Please check the microphone permission and try again."))

        self._thread = None
        self._set_recording(False)
