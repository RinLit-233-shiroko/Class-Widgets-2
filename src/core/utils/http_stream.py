"""Interruptible streaming of an HTTP response body.

``requests``/``urllib3`` read from the socket through ``socket.makefile``, and
on Windows closing the socket from another thread does not wake up a blocked
read.  That makes pause/cancel of a streaming download unresponsive: the worker
thread stays stuck until the server sends more data or the socket read timeout
fires.

This module streams the body with short reads (``read1``) gated by ``select``,
so the caller can poll its own state between chunks and abort promptly, even
while the server is idle.
"""

from __future__ import annotations

import select
import threading
import time
from collections.abc import Callable, Iterator
from typing import TypeVar, cast

import requests

PollCallback = Callable[[], None]

CHUNK_SIZE = 32 * 1024
POLL_INTERVAL = 0.2
STALL_TIMEOUT = 30.0
REQUEST_POLL_INTERVAL = 0.1

T = TypeVar("T")


def call_interruptibly(
    operation: Callable[[], T],
    *,
    poll: PollCallback,
    poll_interval: float = REQUEST_POLL_INTERVAL,
) -> T:
    """Run a blocking request without making its caller wait to cancel.

    DNS lookup, connection establishment, redirects, and response headers are
    all handled inside ``requests.get`` before a response object exists. A
    daemon helper owns that uninterruptible portion while the caller polls its
    cancellation state. An abandoned response is closed as soon as it arrives.
    """
    completed = threading.Event()
    lock = threading.Lock()
    state: dict[str, object] = {"abandoned": False}

    def run() -> None:
        try:
            result = operation()
            with lock:
                if state["abandoned"]:
                    _close_result(result)
                else:
                    state["result"] = result
        except Exception as error:
            with lock:
                if not state["abandoned"]:
                    state["error"] = error
        finally:
            completed.set()

    threading.Thread(target=run, daemon=True).start()
    try:
        while not completed.wait(poll_interval):
            poll()
        poll()
    except Exception:
        with lock:
            state["abandoned"] = True
            result = state.pop("result", None)
        _close_result(result)
        raise

    with lock:
        error = state.get("error")
        result = state.get("result")
    if isinstance(error, BaseException):
        raise error
    return cast(T, result)


def iter_response_chunks(
    response: requests.Response,
    *,
    poll: PollCallback | None = None,
    chunk_size: int = CHUNK_SIZE,
    poll_interval: float = POLL_INTERVAL,
    stall_timeout: float = STALL_TIMEOUT,
) -> Iterator[bytes]:
    """Yield the decoded response body in short, non-blocking chunks.

    ``poll`` is invoked before every read; raise from it to abort the stream
    (e.g. ``PluginDownloadPaused``/``PluginDownloadCancelled``).  If no data
    arrives for ``stall_timeout`` seconds a
    :class:`requests.exceptions.ReadTimeout` is raised.
    """
    raw = response.raw
    targets = _select_targets(response)
    last_data_at = time.monotonic()
    while True:
        if poll is not None:
            poll()
        if time.monotonic() - last_data_at > stall_timeout:
            raise requests.exceptions.ReadTimeout(
                f"No data received for {stall_timeout:g} seconds while downloading."
            )
        if targets:
            try:
                ready = select.select(targets, [], [], poll_interval)[0]
            except (AttributeError, OSError, ValueError, TypeError):
                # The stream was closed underneath us (or select is not
                # usable); fall back to blocking reads, which still respect
                # the socket timeout configured on the request.
                targets = []
            else:
                if not ready:
                    continue
        chunk = raw.read1(amt=chunk_size, decode_content=True)
        if not chunk:
            # A response closed by pause/cancel looks like a natural EOF to
            # urllib3 (read1() returns b"" once the raw is closed).  Re-poll
            # before treating it as end-of-stream so an interrupt that caused
            # the close raises instead of yielding a truncated body.
            if poll is not None:
                poll()
            return
        last_data_at = time.monotonic()
        yield chunk
        if raw.closed:
            # The body is fully consumed, so the underlying file was closed
            # by http.client/urllib3; stop instead of watching a dead fd.
            # Re-poll as well: the close may have come from pause/cancel
            # between the last read and this resume point.
            if poll is not None:
                poll()
            return


def _select_targets(response: requests.Response) -> list[object]:
    """Return objects whose ``fileno()`` can be watched with ``select``."""
    raw = response.raw
    candidates: list[object] = [raw]
    fp = getattr(raw, "_fp", None)
    if fp is not None and getattr(fp, "fp", None) is not None:
        candidates.append(fp.fp)
    connection = getattr(raw, "_connection", None)
    if connection is not None and getattr(connection, "sock", None) is not None:
        candidates.append(connection.sock)
    targets: list[object] = []
    for candidate in candidates:
        try:
            if int(candidate.fileno()) >= 0:
                targets.append(candidate)
        except (AttributeError, OSError, ValueError):
            continue
    return targets


def _close_result(result: object) -> None:
    close = getattr(result, "close", None)
    if callable(close):
        try:
            close()
        except Exception:
            pass
