from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Optional

import requests
from PySide6.QtCore import QObject, Property, QThread, QTimer, Signal, Slot
from PySide6.QtWidgets import QFileDialog
from loguru import logger

from src.core.directories import ASSETS_PATH

from .mic_recorder import MicrophoneRecorder
from .tts import SpeechPlayer, SpeechSynthesisWorker
from .wake_listener import WakeListener


class ChatRequestWorker(QThread):
    """在工作线程内执行 OpenAI 兼容流式聊天请求。"""

    chunkReceived = Signal(str)
    replyCompleted = Signal(str)
    failed = Signal(str)

    def __init__(self, endpoint: str, headers: dict[str, str], payload: dict) -> None:
        super().__init__()
        self.endpoint = endpoint
        self.headers = headers
        self.payload = payload

    def run(self) -> None:
        reply_parts: list[str] = []
        try:
            with requests.post(
                self.endpoint,
                headers=self.headers,
                json=self.payload,
                stream=True,
                timeout=(15, 120),
            ) as response:
                response.raise_for_status()
                non_stream_lines: list[str] = []
                for raw_line in response.iter_lines(decode_unicode=True):
                    if not raw_line:
                        continue
                    line = raw_line.strip()
                    if not line.startswith("data:"):
                        non_stream_lines.append(line)
                        continue
                    data = line[5:].strip()
                    if data == "[DONE]":
                        break
                    try:
                        payload = json.loads(data)
                    except json.JSONDecodeError:
                        continue
                    choices = payload.get("choices") or []
                    if not choices:
                        continue
                    delta = choices[0].get("delta") or {}
                    content = delta.get("content")
                    if content:
                        text = str(content)
                        reply_parts.append(text)
                        self.chunkReceived.emit(text)

            if not reply_parts and non_stream_lines:
                try:
                    payload = json.loads("\n".join(non_stream_lines))
                    choices = payload.get("choices") or []
                    content = (choices[0].get("message") or {}).get("content") if choices else ""
                    if content:
                        reply_parts.append(str(content))
                except json.JSONDecodeError:
                    pass
            reply = "".join(reply_parts).strip()
            if not reply:
                raise RuntimeError("The AI service returned an empty response.")
            self.replyCompleted.emit(reply)
        except requests.RequestException as error:
            logger.warning("AI chat request failed: {}", error)
            self.failed.emit(f"Network request failed: {error}")
        except Exception as error:
            logger.exception("AI chat request processing failed")
            self.failed.emit(str(error))


class TranscriptionWorker(QThread):
    """在工作线程内将录制的 WAV 文件提交到 OpenAI 兼容转写接口。"""

    transcribed = Signal(str)
    failed = Signal(str)

    def __init__(
        self,
        endpoint: str,
        headers: dict[str, str],
        model: str,
        recording_path: str,
    ) -> None:
        super().__init__()
        self.endpoint = endpoint
        self.headers = headers
        self.model = model
        self.recording_path = recording_path

    def run(self) -> None:
        path = Path(self.recording_path)
        try:
            with path.open("rb") as recording:
                response = requests.post(
                    self.endpoint,
                    headers=self.headers,
                    data={"model": self.model},
                    files={"file": (path.name, recording, "audio/wav")},
                    timeout=(15, 120),
                )
            response.raise_for_status()
            text = str(response.json().get("text", "")).strip()
            if not text:
                raise RuntimeError("The transcription service returned no text.")
            self.transcribed.emit(text)
        except requests.RequestException as error:
            logger.warning("AI transcription request failed: {}", error)
            self.failed.emit(f"Transcription request failed: {error}")
        except Exception as error:
            logger.exception("AI transcription processing failed")
            self.failed.emit(str(error))
        finally:
            try:
                path.unlink(missing_ok=True)
            except OSError:
                logger.debug("Failed to remove temporary recording {}", path)


class ModelsListWorker(QThread):
    """在后台读取 OpenAI 兼容服务的可用模型列表。"""

    loaded = Signal(list)
    failed = Signal(str)

    def __init__(self, endpoint: str, headers: dict[str, str]) -> None:
        super().__init__()
        self.endpoint = endpoint
        self.headers = headers

    def run(self) -> None:
        try:
            response = requests.get(
                self.endpoint,
                headers=self.headers,
                timeout=(10, 30),
            )
            response.raise_for_status()
            payload = response.json()
            models = sorted(
                {
                    str(item.get("id", "")).strip()
                    for item in payload.get("data", [])
                    if isinstance(item, dict) and str(item.get("id", "")).strip()
                },
                key=str.lower,
            )
            if not models:
                raise RuntimeError("The provider returned no models for this API key.")
            self.loaded.emit(models)
        except requests.RequestException as error:
            logger.warning("AI model-list request failed: {}", error)
            self.failed.emit(f"Model list request failed: {error}")
        except Exception as error:
            logger.warning("AI model-list processing failed: {}", error)
            self.failed.emit(str(error))


class AiChatService(QObject):
    """提供给 QML、Widget 与插件的 AI 对话统一服务。

    支持任意 OpenAI 兼容服务的文字对话及音频转写接口。点击 Widget 或
    检测到本地 Vosk 唤醒语都会使状态进入 ``listening``，从而统一驱动屏幕
    边框动画；流式回复结束或发生错误后自动回到 ``idle``。
    """

    stateChanged = Signal()
    conversationChanged = Signal()
    responseChanged = Signal()
    activationRequested = Signal(bool, float, float, float, float)
    transcriptionChanged = Signal()
    errorOccurred = Signal(str)
    wakeAvailabilityChanged = Signal()
    speechChanged = Signal()
    modelListChanged = Signal()

    IDLE = "idle"
    LISTENING = "listening"
    THINKING = "thinking"
    RESPONDING = "responding"
    SPEAKING = "speaking"

    def __init__(self, app, parent: Optional[QObject] = None) -> None:
        super().__init__(parent)
        self.app = app
        self._state = self.IDLE
        self._conversation: list[dict[str, str]] = []
        self._current_response = ""
        self._transcription_text = ""
        self._chat_worker: Optional[ChatRequestWorker] = None
        self._transcription_worker: Optional[TranscriptionWorker] = None
        self._speech_worker: Optional[SpeechSynthesisWorker] = None
        self._models_worker: Optional[ModelsListWorker] = None
        self._available_models: list[str] = []
        self._model_list_error = ""
        self._models_loading = False
        self._tts_unavailable = False
        self._speech_text = ""
        self._speech_player = SpeechPlayer(self)
        self._recorder = MicrophoneRecorder(self)
        self._wake_listener = WakeListener(self)
        self._recorder.recorded.connect(self._transcribe_recording)
        self._recorder.errorOccurred.connect(self._on_operation_error)
        self._recorder.recordingChanged.connect(self.stateChanged)
        self._wake_listener.wakeDetected.connect(self._activate_from_wake)
        self._wake_listener.availabilityChanged.connect(self._on_wake_availability_changed)
        self._wake_listener.errorOccurred.connect(self.errorOccurred)
        self._speech_player.started.connect(self._on_speech_started)
        self._speech_player.finished.connect(self._on_speech_finished)
        self._speech_player.failed.connect(self._on_speech_failed)

    @Property(str, notify=stateChanged)
    def state(self) -> str:
        return self._state

    @Property(bool, notify=stateChanged)
    def active(self) -> bool:
        return self._state != self.IDLE

    @Property(bool, notify=stateChanged)
    def recording(self) -> bool:
        return self._recorder.recording

    @Property("QVariantList", notify=conversationChanged)
    def messages(self) -> list[dict[str, str]]:
        return list(self._conversation)

    @Property(str, notify=responseChanged)
    def currentResponse(self) -> str:
        return self._current_response

    @Property(str, notify=transcriptionChanged)
    def transcriptionText(self) -> str:
        return self._transcription_text

    @Property(bool, notify=stateChanged)
    def speaking(self) -> bool:
        return self._state == self.SPEAKING

    @Property(str, notify=speechChanged)
    def speechText(self) -> str:
        return self._speech_text

    @Property("QStringList", notify=modelListChanged)
    def availableModels(self) -> list[str]:
        return list(self._available_models)

    @Property(bool, notify=modelListChanged)
    def modelsLoading(self) -> bool:
        return self._models_loading

    @Property(str, notify=modelListChanged)
    def modelListError(self) -> str:
        return self._model_list_error

    @Property(bool, notify=wakeAvailabilityChanged)
    def wakeAvailable(self) -> bool:
        return self._wake_listener.available

    @Property(str, notify=wakeAvailabilityChanged)
    def wakeAvailabilityMessage(self) -> str:
        return self._wake_listener.availability_message

    @staticmethod
    def _endpoint(base_url: str, path: str) -> str:
        base = base_url.strip().rstrip("/")
        if not base:
            return ""
        if not base.endswith("/v1"):
            base = f"{base}/v1"
        return f"{base}/{path.lstrip('/')}"

    def _headers(self) -> dict[str, str]:
        key = self.app.configs.ai_chat.api_key.strip()
        return {
            "Authorization": f"Bearer {key}",
            "Accept": "application/json",
        }

    def _configuration_error(
        self,
        needs_transcription: bool = False,
        needs_speech: bool = False,
    ) -> str:
        config = self.app.configs.ai_chat
        if not config.enabled:
            return self.tr("AI chat is disabled. Enable it in Settings first.")
        if not config.base_url.strip():
            return self.tr("Set an AI provider base URL in Settings first.")
        if not config.api_key.strip():
            return self.tr("Set an API key in Settings first.")
        if not config.model.strip():
            return self.tr("Set a chat model in Settings first.")
        if needs_transcription and not config.transcription_model.strip():
            return self.tr("Set a transcription model in Settings first.")
        if needs_speech and not config.tts_model.strip():
            return self.tr("Set a speech model in Settings first.")
        if needs_speech and not config.tts_voice.strip():
            return self.tr("Set a speech voice in Settings first.")
        return ""

    def _set_state(self, state: str) -> None:
        if self._state == state:
            return
        self._state = state
        self.stateChanged.emit()

    @Slot()
    def activate(self) -> None:
        """由 Widget 点击触发，打开文字对话面板并显示边框动画。"""
        self.activateAt(0.0, 0.0, 0.0, 0.0)

    @Slot(float, float, float, float)
    def activateAt(self, x: float, y: float, width: float, height: float) -> None:
        """从指定 Widget 的下方打开输入浮层；坐标来自 QML 场景。"""
        error = self._configuration_error()
        if error:
            self.errorOccurred.emit(error)
            return
        self._stop_wake_listener()
        self._transcription_text = ""
        self.transcriptionChanged.emit()
        self._set_state(self.LISTENING)
        self.activationRequested.emit(False, x, y, width, height)

    @Slot()
    def startRecording(self) -> None:
        """开始一次按键式语音输入；停止后自动进行云端转写与回答。"""
        error = self._configuration_error(needs_transcription=True)
        if error:
            self.errorOccurred.emit(error)
            return
        if self._state == self.IDLE:
            self.activate()
        if self._state != self.LISTENING:
            return
        self._stop_wake_listener()
        self._recorder.start()

    @Slot()
    def stopRecording(self) -> None:
        self._recorder.stop()

    @Slot(str)
    def sendMessage(self, text: str) -> None:
        """发送用户文字，并在后台开始流式 OpenAI 兼容聊天请求。"""
        content = (text or "").strip()
        if not content:
            return
        error = self._configuration_error()
        if error:
            self.errorOccurred.emit(error)
            return
        if self._chat_worker is not None:
            return
        self._stop_speech()
        self._stop_wake_listener()
        self._conversation.append({"role": "user", "content": content})
        self.conversationChanged.emit()
        self._current_response = ""
        self.responseChanged.emit()
        self._set_state(self.THINKING)

        config = self.app.configs.ai_chat
        request_messages: list[dict[str, str]] = []
        if config.system_prompt.strip():
            request_messages.append({"role": "system", "content": config.system_prompt.strip()})
        request_messages.extend(self._conversation)
        worker = ChatRequestWorker(
            self._endpoint(config.base_url, "chat/completions"),
            self._headers(),
            {
                "model": config.model.strip(),
                "messages": request_messages,
                "stream": True,
            },
        )
        self._chat_worker = worker
        worker.chunkReceived.connect(self._on_chat_chunk)
        worker.replyCompleted.connect(self._on_chat_completed)
        worker.failed.connect(self._on_operation_error)
        worker.finished.connect(worker.deleteLater)
        worker.start()

    @Slot()
    def clearConversation(self) -> None:
        if self._chat_worker is not None or self._transcription_worker is not None or self._speech_worker is not None:
            return
        self._conversation.clear()
        self._current_response = ""
        self.conversationChanged.emit()
        self.responseChanged.emit()

    @Slot()
    def cancel(self) -> None:
        """退出当前交互。已发出的网络请求会在完成后被忽略。"""
        self._recorder.stop()
        self._stop_speech()
        self._current_response = ""
        self.responseChanged.emit()
        self._finish_interaction()

    @Slot()
    def refreshModels(self) -> None:
        """从当前 OpenAI 兼容提供商加载此 API Key 可用的模型列表。"""
        if self._models_worker is not None:
            return
        config = self.app.configs.ai_chat
        if not config.base_url.strip() or not config.api_key.strip():
            self._available_models = []
            self._model_list_error = self.tr("Enter a base URL and API key before refreshing models.")
            self._models_loading = False
            self.modelListChanged.emit()
            return
        self._model_list_error = ""
        self._models_loading = True
        self.modelListChanged.emit()
        worker = ModelsListWorker(self._endpoint(config.base_url, "models"), self._headers())
        self._models_worker = worker
        worker.loaded.connect(self._on_models_loaded)
        worker.failed.connect(self._on_models_failed)
        # 结果信号进入主线程时，工作线程可能尚未完成退出；必须保留引用直到
        # finished，防止大量模型响应下 QThread 被提前析构而导致程序崩溃。
        worker.finished.connect(self._on_models_worker_finished)
        worker.finished.connect(worker.deleteLater)
        worker.start()

    @Slot(list)
    def _on_models_loaded(self, models: list) -> None:
        self._available_models = [str(model) for model in models]
        self._model_list_error = ""
        self._models_loading = False
        self.modelListChanged.emit()

    @Slot(str)
    def _on_models_failed(self, message: str) -> None:
        self._available_models = []
        self._model_list_error = message or self.tr("Unable to load the provider model list.")
        self._models_loading = False
        self.modelListChanged.emit()

    @Slot()
    def _on_models_worker_finished(self) -> None:
        if self.sender() is self._models_worker:
            self._models_worker = None

    @Slot(result=str)
    def selectWakeModelDirectory(self) -> str:
        """选择任意语言的本地 Vosk 模型目录并立即应用。"""
        directory = QFileDialog.getExistingDirectory(
            None,
            self.tr("Select a local Vosk model folder"),
            self.app.configs.ai_chat.wake_model_path or str(ASSETS_PATH / "models"),
        )
        if not directory:
            return ""
        self.app.configs.set("ai_chat.wake_model_path", directory)
        self.app.configs.save(silent=True)
        self.refreshWakeListener()
        return directory

    @Slot()
    def refreshWakeListener(self) -> None:
        """按已保存的设置重启离线唤醒监听；设置页保存后调用。"""
        self._stop_wake_listener()
        config = self.app.configs.ai_chat
        if not config.enabled or not config.wake_enabled:
            self._on_wake_availability_changed(False, "")
            return
        model_path = self._default_vosk_model_path()
        self._wake_listener.configure(config.wake_phrase, model_path)
        self._wake_listener.start()

    @Slot()
    def release(self) -> None:
        # 在清空状态前保存语音线程引用，避免 Qt 在仍运行时析构该线程。
        speech_worker = self._speech_worker
        self._stop_wake_listener()
        self._recorder.release()
        self._stop_speech()
        for worker in (self._chat_worker, self._transcription_worker, speech_worker, self._models_worker):
            if worker and worker.isRunning():
                worker.wait(5_000)
        self._chat_worker = None
        self._transcription_worker = None
        self._speech_worker = None
        self._models_worker = None
        self._speech_player.release()

    def _default_vosk_model_path(self) -> Path:
        # 用户设置的任意本地 Vosk 目录优先，可替换为英语、日语等对应语言模型。
        configured = self.app.configs.ai_chat.wake_model_path.strip()
        if configured:
            return Path(configured).expanduser()
        environment_override = os.environ.get("CLASSWIDGETS_VOSK_MODEL_PATH", "").strip()
        if environment_override:
            return Path(environment_override).expanduser()
        return ASSETS_PATH / "models" / "vosk-model-small-cn-0.22"

    def _stop_wake_listener(self) -> None:
        self._wake_listener.stop()

    @Slot(str)
    def _activate_from_wake(self, _phrase: str) -> None:
        if self._state != self.IDLE:
            return
        error = self._configuration_error(needs_transcription=True)
        if error:
            self.errorOccurred.emit(error)
            self.refreshWakeListener()
            return
        self._stop_wake_listener()
        self._transcription_text = ""
        self.transcriptionChanged.emit()
        self._set_state(self.LISTENING)
        self.activationRequested.emit(True, 0.0, 0.0, 0.0, 0.0)
        self._recorder.start()

    @Slot(str)
    def _transcribe_recording(self, recording_path: str) -> None:
        error = self._configuration_error(needs_transcription=True)
        if error:
            try:
                Path(recording_path).unlink(missing_ok=True)
            except OSError:
                pass
            self._on_operation_error(error)
            return
        config = self.app.configs.ai_chat
        self._set_state(self.THINKING)
        worker = TranscriptionWorker(
            self._endpoint(config.base_url, "audio/transcriptions"),
            self._headers(),
            config.transcription_model.strip(),
            recording_path,
        )
        self._transcription_worker = worker
        worker.transcribed.connect(self._on_transcribed)
        worker.failed.connect(self._on_operation_error)
        worker.finished.connect(self._on_transcription_finished)
        worker.finished.connect(worker.deleteLater)
        worker.start()

    @Slot(str)
    def _on_transcribed(self, text: str) -> None:
        # 先展示已识别文本，让聆听卡有明确的“听到了什么”反馈；随后再以
        # 平滑过渡进入用户消息与 AI 回复状态。
        self._transcription_text = text
        self.transcriptionChanged.emit()
        self._set_state(self.LISTENING)
        QTimer.singleShot(520, lambda: self.sendMessage(text))

    @Slot()
    def _on_transcription_finished(self) -> None:
        if self.sender() is self._transcription_worker:
            self._transcription_worker = None

    @Slot(str)
    def _on_chat_chunk(self, chunk: str) -> None:
        if self._state == self.IDLE:
            return
        if self._state != self.RESPONDING:
            self._set_state(self.RESPONDING)
        self._current_response += chunk
        self.responseChanged.emit()

    @Slot(str)
    def _on_chat_completed(self, reply: str) -> None:
        self._chat_worker = None
        if self._state == self.IDLE:
            return
        self._current_response = reply
        self._conversation.append({"role": "assistant", "content": reply})
        self.responseChanged.emit()
        self.conversationChanged.emit()
        if self.app.configs.ai_chat.tts_enabled and not self._tts_unavailable:
            self._begin_speech(reply)
        else:
            self._finish_interaction()

    def _begin_speech(self, text: str) -> None:
        """开始生成朗读音频；生成和播放期间保持 AI 交互处于活动状态。"""
        error = self._configuration_error(needs_speech=True)
        if error:
            self.errorOccurred.emit(error)
            self._finish_interaction()
            return
        config = self.app.configs.ai_chat
        self._speech_text = text
        self.speechChanged.emit()
        self._set_state(self.SPEAKING)
        worker = SpeechSynthesisWorker(
            self._endpoint(config.base_url, "audio/speech"),
            self._headers(),
            config.tts_model.strip(),
            config.tts_voice.strip(),
            max(0.25, min(float(config.tts_speed), 4.0)),
            text,
        )
        self._speech_worker = worker
        worker.generated.connect(self._on_speech_generated)
        worker.failed.connect(self._on_speech_failed)
        worker.finished.connect(worker.deleteLater)
        worker.start()

    @Slot(str, str)
    def _on_speech_generated(self, audio_path: str, text: str) -> None:
        # 已取消或由另一轮对话替换时，不再播放迟到的合成结果。
        if self.sender() is not self._speech_worker or self._state != self.SPEAKING:
            try:
                Path(audio_path).unlink(missing_ok=True)
            except OSError:
                pass
            return
        self._speech_player.play(audio_path, text)

    @Slot(str)
    def _on_speech_started(self, text: str) -> None:
        self._speech_text = text
        self.speechChanged.emit()

    @Slot()
    def _on_speech_finished(self) -> None:
        self._speech_worker = None
        self._speech_text = ""
        self.speechChanged.emit()
        self._finish_interaction()

    @Slot(str)
    def _on_speech_failed(self, message: str) -> None:
        self._speech_worker = None
        self._speech_text = ""
        self.speechChanged.emit()
        # 许多 OpenAI 兼容提供商只实现聊天接口。朗读端点 404 时保留已完成
        # 的文字对话，并在本次应用运行中停止重复请求该不兼容端点。
        if "404" in (message or ""):
            self._tts_unavailable = True
            logger.info("The configured provider does not support /v1/audio/speech; keeping text chat available.")
        elif message:
            logger.warning("AI speech playback was skipped: {}", message)
        self._finish_interaction()

    def _stop_speech(self) -> None:
        self._speech_worker = None
        self._speech_player.stop(cleanup_only=True)
        if self._speech_text:
            self._speech_text = ""
            self.speechChanged.emit()

    @Slot(str)
    def _on_operation_error(self, message: str) -> None:
        self._chat_worker = None
        self._transcription_worker = None
        self._stop_speech()
        if message:
            self.errorOccurred.emit(message)
        self._finish_interaction()

    @Slot(bool, str)
    def _on_wake_availability_changed(self, _available: bool, _message: str) -> None:
        self.wakeAvailabilityChanged.emit()

    def _finish_interaction(self) -> None:
        self._set_state(self.IDLE)
        self.refreshWakeListener()
