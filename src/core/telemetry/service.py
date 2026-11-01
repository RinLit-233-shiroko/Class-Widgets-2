"""Sentry 只在此模块出现；工作线程只能提交普通 Python 数据。"""

import platform
import threading
import time
from contextlib import contextmanager

import requests
from loguru import logger

from src import BUILD_DIST, SENTRY_DSN, __version__, __version_type__

from .privacy import sanitize_event, technical_tags


class Operation:
    """一个异步操作的生命周期，重复完成或撤销授权后完成均为空操作。"""

    def __init__(self, service, transaction=None, generation=0, scope=None):
        self._service = service
        self._transaction = transaction
        self._generation = generation
        self._scope = scope
        self._lock = threading.Lock()
        self._finished = False

    def finish(self, status="ok"):
        with self._lock:
            if self._finished:
                return
            self._finished = True
        self._service.finish_operation(self, status)

    def __enter__(self):
        return self

    def __exit__(self, exc_type, _value, _traceback):
        self.finish("internal_error" if exc_type else "ok")


class TelemetryService:
    def __init__(self, *, dsn=None, dist=None, transport_factory=None, clock=time.monotonic):
        import os

        self._dsn = os.environ.get("SENTRY_DSN", SENTRY_DSN) if dsn is None else dsn
        self._dist = dist or BUILD_DIST or f"{platform.system()}-{platform.machine()}-local"
        self._transport_factory = transport_factory
        self._clock = clock
        self._lock = threading.RLock()
        self._client = None
        self._allowed = threading.Event()
        self._generation = 0
        self._operations = {}
        self._last_failure = {}
        self._tags = {"phase": "startup"}

    @property
    def enabled(self):
        return self._allowed.is_set() and self._client is not None

    def set_context(self, **context):
        with self._lock:
            self._tags.update(technical_tags(context))

    def configure(self, enabled: bool):
        with self._lock:
            if enabled and self.enabled:
                return
            if not enabled:
                self._disable()
                return
            if not self._dsn:
                return
            try:
                from sentry_sdk import Client
                from sentry_sdk.transport import HttpTransport

                allowed = threading.Event()

                class ConsentTransport(HttpTransport):
                    def _send_envelope(self, envelope):
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
                    auto_session_tracking=False,
                    send_default_pii=False,
                    include_local_variables=False,
                    include_source_context=False,
                    enable_logs=False,
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
                    before_send=sanitize_event,
                    before_send_transaction=sanitize_event,
                    in_app_include=["src"],
                )
                self._allowed = allowed
                self._allowed.set()
            except Exception:
                self._client = None
                logger.warning("Unable to initialize telemetry; continuing locally")

    def _disable(self):
        self._allowed.clear()
        self._generation += 1
        self._operations.clear()
        self._last_failure.clear()
        client, self._client = self._client, None
        if client is not None:
            # 不调用 close()/flush()：撤销授权时必须丢弃发送队列。
            client.transport.kill()

    @contextmanager
    def _scope(self, context):
        from sentry_sdk import Scope
        from sentry_sdk.scope import use_scope

        scope = Scope(client=self._client)
        for key, value in {**self._tags, **technical_tags(context)}.items():
            scope.set_tag(key, value)
        with use_scope(scope):
            yield scope

    def capture_exception(self, exc_info, context=None):
        with self._lock:
            if not self.enabled:
                return None
            try:
                with self._scope(context or {}) as scope:
                    return scope.capture_exception(exc_info)
            except Exception:
                logger.warning("Unable to capture telemetry exception")
                return None

    def capture_failure(self, code, context=None, *, error=None):
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

    def start_operation(self, name, context=None, *, parent=None):
        with self._lock:
            transaction = None
            operation_scope = None
            if self.enabled:
                try:
                    if (
                        parent is not None
                        and parent._transaction is not None
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

    def finish_operation(self, operation, status):
        with self._lock:
            self._operations.pop(operation, None)
            if (
                not self.enabled
                or operation._generation != self._generation
                or operation._transaction is None
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
    def operation(self, name, context=None, *, parent=None):
        with self.start_operation(name, context, parent=parent) as operation:
            yield operation

    def shutdown(self, timeout=2):
        with self._lock:
            for operation in reversed(list(self._operations)):
                operation.finish("cancelled")
            client = self._client
        if client is not None:
            try:
                client.flush(timeout=min(max(timeout, 0), 2))
            except Exception:
                logger.warning("Unable to flush telemetry")
        with self._lock:
            self._disable()
