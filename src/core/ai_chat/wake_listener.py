from __future__ import annotations

import json
import queue
import re
import threading
import time
from pathlib import Path
from typing import Optional

from PySide6.QtCore import QObject, Signal
from loguru import logger

try:
    import sounddevice as sd
except (ImportError, OSError):
    sd = None

try:
    from vosk import KaldiRecognizer, Model, SetLogLevel
except ImportError:
    KaldiRecognizer = None
    Model = None
    SetLogLevel = None


class WakeListener(QObject):
    """在后台以 Vosk 识别默认麦克风输入，并匹配用户自定义唤醒语。"""

    wakeDetected = Signal(str)
    availabilityChanged = Signal(bool, str)
    errorOccurred = Signal(str)

    SAMPLE_RATE = 16_000

    def __init__(self, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self._wake_phrase = ""
        self._model_path: Optional[Path] = None
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None
        self._available = False
        self._availability_message = ""
        self._lock = threading.Lock()

    @property
    def available(self) -> bool:
        return self._available

    @property
    def availability_message(self) -> str:
        return self._availability_message

    @staticmethod
    def _normalise(value: str) -> str:
        return re.sub(r"[\W_]+", "", value, flags=re.UNICODE).lower()

    def configure(self, wake_phrase: str, model_path: Path) -> None:
        self._wake_phrase = self._normalise(wake_phrase)
        self._model_path = Path(model_path)

    def start(self) -> bool:
        """开始后台监听。依赖或模型不可用时返回 ``False`` 并说明原因。"""
        with self._lock:
            if self._thread and self._thread.is_alive():
                return True
            reason = self._validate_environment()
            if reason:
                self._set_available(False, reason)
                return False
            self._stop_event.clear()
            self._thread = threading.Thread(
                target=self._listen_worker,
                name="AiChatWakeListener",
                daemon=True,
            )
            self._thread.start()
            return True

    def stop(self) -> None:
        self._stop_event.set()
        thread = self._thread
        if thread and thread.is_alive():
            thread.join(timeout=2.0)
        self._thread = None

    def release(self) -> None:
        self.stop()

    def _validate_environment(self) -> str:
        if sd is None:
            return self.tr("Voice wake-up is unavailable because sounddevice is not installed.")
        if Model is None or KaldiRecognizer is None:
            return self.tr("Voice wake-up is unavailable because Vosk is not installed.")
        if not self._wake_phrase:
            return self.tr("Set a wake phrase before enabling voice wake-up.")
        if not self._model_path or not self._model_path.is_dir():
            return self.tr("The offline Vosk Chinese model has not been installed yet.")
        if not (self._model_path / "am").is_dir():
            return self.tr("The offline Vosk model folder is incomplete.")
        return ""

    def _set_available(self, available: bool, message: str = "") -> None:
        if self._available == available and self._availability_message == message:
            return
        self._available = available
        self._availability_message = message
        self.availabilityChanged.emit(available, message)

    def _listen_worker(self) -> None:
        audio_queue: queue.Queue[bytes] = queue.Queue(maxsize=32)
        phrase = self._wake_phrase
        model_path = self._model_path
        last_detection = 0.0

        def on_audio(indata, _frames, _time_info, status) -> None:
            if status:
                logger.debug("AI wake listener microphone status: {}", status)
            try:
                audio_queue.put_nowait(bytes(indata))
            except queue.Full:
                # 识别暂时落后时丢弃最早一小段音频，保持唤醒响应而不占满内存。
                try:
                    audio_queue.get_nowait()
                    audio_queue.put_nowait(bytes(indata))
                except queue.Empty:
                    pass

        try:
            if SetLogLevel is not None:
                SetLogLevel(-1)
            model = Model(str(model_path))
            recognizer = KaldiRecognizer(model, self.SAMPLE_RATE)
            self._set_available(True, "")
            logger.info("AI voice wake listener started with phrase {!r}", phrase)

            with sd.RawInputStream(
                samplerate=self.SAMPLE_RATE,
                blocksize=8_000,
                device=None,
                channels=1,
                dtype="int16",
                callback=on_audio,
            ):
                while not self._stop_event.is_set():
                    try:
                        data = audio_queue.get(timeout=0.25)
                    except queue.Empty:
                        continue
                    recognizer.AcceptWaveform(data)
                    partial = json.loads(recognizer.PartialResult()).get("partial", "")
                    text = self._normalise(partial)
                    now = time.monotonic()
                    if phrase and phrase in text and now - last_detection >= 2.5:
                        last_detection = now
                        logger.info("AI voice wake phrase detected")
                        self.wakeDetected.emit(phrase)
        except Exception as error:
            logger.exception("AI voice wake listener failed")
            message = self.tr("Voice wake-up stopped: {0}").format(error)
            self._set_available(False, message)
            self.errorOccurred.emit(message)
        finally:
            self._thread = None
            if self._stop_event.is_set():
                self._set_available(False, "")
            logger.info("AI voice wake listener stopped")
