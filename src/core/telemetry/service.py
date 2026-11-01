"""Sentry 只在此模块出现；工作线程只能提交普通 Python 数据。"""

from __future__ import annotations

import logging
import platform
import threading
import time
from collections.abc import Callable, Iterator, Mapping
from contextlib import contextmanager
from types import TracebackType
from typing import TYPE_CHECKING, Self

import requests
from loguru import logger

from src import BUILD_DIST, SENTRY_DSN, __version__, __version_type__

from .privacy import sanitize_event, sanitize_log, technical_tags

if TYPE_CHECKING:
    from sentry_sdk import Client, Scope
    from sentry_sdk._types import Event, Hint, Log
    from sentry_sdk.client import BaseClient
    from sentry_sdk.envelope import Envelope
    from sentry_sdk.session import Session
    from sentry_sdk.tracing import Span
    from sentry_sdk.transport import Transport


class Operation:
    """一个异步操作的生命周期，重复完成或撤销授权后完成均为空操作。"""

    def __init__(
        self,
        service: TelemetryService,
        transaction: Span | None = None,
        generation: int = 0,
        scope: Scope | None = None,
    ) -> None:
        self._service = service
        self._transaction = transaction
        self._generation = generation
        self._scope = scope
        self._lock = threading.Lock()
        self._finished = False

    def finish(self, status: str = "ok") -> None:
        with self._lock:
            if self._finished:
                return
            self._finished = True
        self._service.finish_operation(self, status)

    def __enter__(self) -> Self:
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        _value: BaseException | None,
        _traceback: TracebackType | None,
    ) -> None:
        self.finish("internal_error" if exc_type else "ok")


class TelemetryService:
    def __init__(
        self,
        *,
        dsn: str | None = None,
        dist: str | None = None,
        transport_factory: type[Transport] | None = None,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        import os

        self._dsn = os.environ.get("SENTRY_DSN", SENTRY_DSN) if dsn is None else dsn
        self._dist = dist or BUILD_DIST or f"{platform.system()}-{platform.machine()}-local"
        self._transport_factory = transport_factory
        self._clock = clock
        self._lock = threading.RLock()
        self._client: Client | None = None
        self._previous_global_client: BaseClient | None = None
        self._session: Session | None = None
        self._session_started = 0.0
        self._allowed = threading.Event()
        self._generation = 0
        self._operations: dict[Operation, None] = {}
        self._last_failure: dict[tuple[str, ...], float] = {}
        self._reported_exceptions: dict[int, tuple[BaseException, float]] = {}
        self._tags: dict[str, str] = {"phase": "startup"}

    @property
    def enabled(self) -> bool:
        return self._allowed.is_set() and self._client is not None

    def set_context(self, **context: object) -> None:
        with self._lock:
            self._tags.update(technical_tags(context))

    def configure(self, enabled: bool) -> None:
        with self._lock:
            if enabled and self.enabled:
                return
            if not enabled:
                self._disable()
                return
            if not self._dsn:
                return
            try:
                from sentry_sdk import Client, get_global_scope
                from sentry_sdk.integrations.loguru import LoguruIntegration
                from sentry_sdk.session import Session
                from sentry_sdk.transport import HttpTransport

                allowed = threading.Event()

                class ConsentTransport(HttpTransport):
                    def capture_envelope(self, envelope: Envelope) -> None:
                        if allowed.is_set():
                            super().capture_envelope(envelope)

                    def _send_envelope(self, envelope: Envelope) -> None:
                        if allowed.is_set():
                            super()._send_envelope(envelope)

                factory = self._transport_factory or ConsentTransport
                self._client = Client(
                    dsn=self._dsn,
                    release=f"classwidgets-2@{__version__}-{__version_type__}",
                    environment=__version_type__,
                    dist=self._dist,
                    server_name="",
                    default_integrations=False,
                    auto_enabling_integrations=False,
                    integrations=[
                        LoguruIntegration(
                            level=None,
                            event_level=logging.ERROR,
                            event_format="{message}",
                            sentry_logs_level=logging.INFO,
                            capture_sentry_logs=True,
                        ),
                    ],
                    auto_session_tracking=False,
                    send_default_pii=False,
                    include_local_variables=False,
                    include_source_context=False,
                    enable_logs=True,
                    enable_metrics=False,
                    enable_backpressure_handling=False,
                    send_client_reports=False,
                    traces_sample_rate=0.1,
                    sample_rate=1.0,
                    profiles_sample_rate=0.0,
                    profile_session_sample_rate=0.0,
                    trace_propagation_targets=[],
                    transport=factory,
                    transport_queue_size=100,
                    shutdown_timeout=2,
                    before_send=self._before_send,
                    before_send_log=self._before_send_log,
                    before_send_transaction=sanitize_event,
                    in_app_include=["src"],
                )
                self._allowed = allowed
                self._allowed.set()
                global_scope = get_global_scope()
                self._previous_global_client = global_scope.client
                global_scope.set_client(self._client)
                self._session = Session(
                    release=self._client.options["release"],
                    environment=self._client.options["environment"],
                    session_mode="application",
                )
                self._session_started = self._clock()
                self._client.capture_session(self._session)
            except Exception:
                self._client = None
                logger.warning("Unable to initialize telemetry; continuing locally")

    def _disable(self) -> None:
        self._allowed.clear()
        self._generation += 1
        self._operations.clear()
        self._last_failure.clear()
        self._reported_exceptions.clear()
        self._session = None
        client, self._client = self._client, None
        if client is not None:
            from sentry_sdk import get_global_scope

            global_scope = get_global_scope()
            if global_scope.client is client:
                global_scope.set_client(self._previous_global_client)
            self._previous_global_client = None
            # 不调用 close()/flush()：撤销授权时必须丢弃发送队列。
            try:
                client.session_flusher.kill()
                client.session_flusher.pending_sessions.clear()
                with client.session_flusher._aggregate_lock:
                    client.session_flusher.pending_aggregates.clear()
                if client.log_batcher is not None:
                    client.log_batcher.kill()
                    with client.log_batcher._lock:
                        client.log_batcher._buffer.clear()
                if client.transport is not None:
                    client.transport.kill()
            except Exception:
                logger.warning("Unable to stop telemetry transport")

    def _before_send_log(self, log: Log, _hint: Hint) -> Log | None:
        with self._lock:
            if not self.enabled or log["severity_number"] < 9:
                return None
            name = str(log["attributes"].get("logger.name", ""))
            if name.startswith(("src.core.telemetry", "sentry_sdk")):
                return None
            clean = sanitize_log(log)
            attributes = clean["attributes"]
            attributes.update(self._tags)
            attributes.update(
                {
                    "sentry.release": f"classwidgets-2@{__version__}-{__version_type__}",
                    "sentry.environment": __version_type__,
                    "dist": self._dist,
                }
            )
            if name.startswith("cw_plugin_"):
                attributes.update(
                    technical_tags(
                        {"component": "plugin", "plugin_id": name.removeprefix("cw_plugin_")}
                    )
                )
            return clean

    def _before_send(self, event: Event, hint: Hint) -> Event | None:
        with self._lock:
            if not self.enabled:
                return None
            record = hint.get("log_record")
            exc_info = hint.get("exc_info")
            error = exc_info[1] if exc_info is not None else None
            if isinstance(error, (requests.ConnectionError, requests.Timeout)):
                return None
            now = self._clock()
            if record is not None:
                extra = getattr(record, "extra", {})
                if extra.get("telemetry_skip") or record.name.startswith(
                    ("src.core.telemetry", "sentry_sdk")
                ):
                    return None
                key = (
                    "loguru",
                    record.name,
                    record.funcName,
                    str(record.lineno),
                    str(record.levelno),
                )
                if now - self._last_failure.get(key, float("-inf")) < 60:
                    return None
                self._last_failure[key] = now
                context = dict(self._tags)
                if record.name.startswith("cw_plugin_"):
                    context.update(
                        component="plugin", plugin_id=record.name.removeprefix("cw_plugin_")
                    )
                event["tags"] = {
                    **context,
                    **event.get("tags", {}),
                    "source": "loguru",
                }
                event["fingerprint"] = ["loguru", record.name, record.funcName, str(record.lineno)]
                event.setdefault("contexts", {}).update(
                    os={"name": platform.system(), "version": platform.release()},
                    runtime={"name": "CPython", "version": platform.python_version()},
                )
            if error is not None:
                self._reported_exceptions = {
                    key: value
                    for key, value in self._reported_exceptions.items()
                    if now - value[1] < 60
                }
                if id(error) in self._reported_exceptions:
                    return None
                if len(self._reported_exceptions) >= 100:
                    self._reported_exceptions.pop(next(iter(self._reported_exceptions)))
                self._reported_exceptions[id(error)] = (error, now)
            self._last_failure = {
                key: value for key, value in self._last_failure.items() if now - value < 60
            }
            clean = sanitize_event(event, hint)
            if self._session is not None and self._client is not None:
                exceptions = clean.get("exception", {}).get("values", [])
                crashed = any(
                    item.get("mechanism", {}).get("handled") is False for item in exceptions
                )
                self._session.update(
                    status="crashed" if crashed else None,
                    errors=self._session.errors + 1,
                )
                self._client.capture_session(self._session)
            return clean

    @contextmanager
    def _scope(self, context: Mapping[str, object]) -> Iterator[Scope]:
        from sentry_sdk import Scope
        from sentry_sdk.scope import use_scope

        scope = Scope(client=self._client)
        scope.set_context(
            "os",
            {
                "name": platform.system(),
                "version": platform.release(),
                "build": platform.version(),
            },
        )
        scope.set_context("runtime", {"name": "CPython", "version": platform.python_version()})
        for key, value in {**self._tags, **technical_tags(context)}.items():
            scope.set_tag(key, value)
        with use_scope(scope):
            yield scope

    def capture_exception(
        self,
        exc_info: tuple[type[BaseException], BaseException | None, TracebackType | None],
        context: Mapping[str, object] | None = None,
        *,
        handled: bool = True,
    ) -> str | None:
        with self._lock:
            if not self.enabled or self._client is None or exc_info[1] is None:
                return None
            try:
                with self._scope(context or {}) as scope:
                    from sentry_sdk.utils import event_from_exception

                    event, hint = event_from_exception(
                        (exc_info[0], exc_info[1], exc_info[2]),
                        client_options=self._client.options,
                        mechanism={"type": "classwidgets", "handled": handled},
                    )
                    return scope.capture_event(event, hint=hint)
            except Exception:
                logger.warning("Unable to capture telemetry exception")
                return None

    def capture_failure(
        self,
        code: str,
        context: Mapping[str, object] | None = None,
        *,
        error: BaseException | None = None,
    ) -> str | None:
        context = dict(context or {}, failure_code=code)
        if isinstance(error, (requests.ConnectionError, requests.Timeout)):
            return None
        if isinstance(error, requests.HTTPError) and error.response is not None:
            context["status_code"] = error.response.status_code
        with self._lock:
            if not self.enabled:
                return None
            key = (
                *[
                    technical_tags(context).get(name, "")
                    for name in ("component", "stage", "plugin_id", "theme_id", "failure_code")
                ],
                type(error).__name__ if error else "",
            )
            now = self._clock()
            if now - self._last_failure.get(key, float("-inf")) < 60:
                return None
            # 长时间运行时只保留仍处在限流窗口内的记录。
            self._last_failure = {k: t for k, t in self._last_failure.items() if now - t < 60}
            self._last_failure[key] = now
            if error is not None:
                return self.capture_exception((type(error), error, error.__traceback__), context)
            try:
                with self._scope(context) as scope:
                    return scope.capture_message(code, level="error")
            except Exception:
                logger.warning("Unable to capture telemetry failure")
                return None

    def start_operation(
        self,
        name: str,
        context: Mapping[str, object] | None = None,
        *,
        parent: Operation | None = None,
    ) -> Operation:
        with self._lock:
            transaction = None
            operation_scope = None
            if self.enabled:
                try:
                    if (
                        parent is not None
                        and parent._transaction is not None
                        and parent._scope is not None
                        and parent._generation == self._generation
                        and not parent._finished
                    ):
                        from sentry_sdk.scope import use_scope

                        with use_scope(parent._scope):
                            transaction = parent._transaction.start_child(op=name, description=name)
                        operation_scope = parent._scope
                    else:
                        with self._scope(context or {}) as scope:
                            transaction = scope.start_transaction(name=name, op=name)
                            operation_scope = scope
                except Exception:
                    logger.warning("Unable to start telemetry operation")
            operation = Operation(self, transaction, self._generation, operation_scope)
            if transaction is not None:
                self._operations[operation] = None
            return operation

    def finish_operation(self, operation: Operation, status: str) -> None:
        with self._lock:
            self._operations.pop(operation, None)
            if (
                not self.enabled
                or operation._generation != self._generation
                or operation._transaction is None
                or operation._scope is None
            ):
                return
            try:
                from sentry_sdk.scope import use_scope

                operation._transaction.set_status(status)
                with use_scope(operation._scope):
                    operation._transaction.finish()
            except Exception:
                logger.warning("Unable to finish telemetry operation")

    @contextmanager
    def operation(
        self,
        name: str,
        context: Mapping[str, object] | None = None,
        *,
        parent: Operation | None = None,
    ) -> Iterator[Operation]:
        with self.start_operation(name, context, parent=parent) as operation:
            yield operation

    def shutdown(self, timeout: float = 2) -> None:
        with self._lock:
            for operation in reversed(list(self._operations)):
                operation.finish("cancelled")
            client = self._client
            if client is not None and self._session is not None:
                self._session.update(duration=max(0.0, self._clock() - self._session_started))
                self._session.close()
                client.capture_session(self._session)
                self._session = None
        if client is not None:
            try:
                client.flush(timeout=min(max(timeout, 0), 2))
            except Exception:
                logger.warning("Unable to flush telemetry")
        with self._lock:
            self._disable()
