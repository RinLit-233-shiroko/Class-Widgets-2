from __future__ import annotations

import socket
import struct
import time
from datetime import datetime, timedelta
from threading import Lock, Thread
from typing import TYPE_CHECKING

from loguru import logger
from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot

if TYPE_CHECKING:
    from src.core.config.manager import ConfigManager


_NTP_PORT = 123
_NTP_PACKET_SIZE = 48
_NTP_TIMESTAMP_DELTA = 2_208_988_800
_NTP_TIMEOUT_SECONDS = 3.0


class TimeService(QObject):
    """提供可选 NTP 校时、系统时间回退和面向 QML 的显示状态。"""

    updated = Signal()
    syncFinished = Signal(bool)
    _syncResult = Signal(bool, float, str, str)

    def __init__(self, configs: "ConfigManager", parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._configs = configs
        self._lock = Lock()
        self._ntp_offset_seconds = 0.0
        self._ntp_available = False
        self._syncing = False
        self._status_text = self.tr("正在使用系统时间")
        self._sync_thread: Thread | None = None

        self._display_timer = QTimer(self)
        self._display_timer.setInterval(500)
        self._display_timer.timeout.connect(self.updated)
        self._display_timer.start()
        self._syncResult.connect(self._apply_sync_result)

    def start(self) -> None:
        """在配置加载后启动服务，并在需要时异步进行首次 NTP 同步。"""
        if self._configs.time.use_precise_time:
            self.sync()
        else:
            self.updated.emit()

    def stop(self) -> None:
        self._display_timer.stop()

    def now(self) -> datetime:
        """返回当前有效时间；NTP 不可用时始终安全回退到系统时间。"""
        with self._lock:
            use_ntp = self._configs.time.use_precise_time and self._ntp_available
            offset = self._ntp_offset_seconds if use_ntp else 0.0
        return datetime.now() + timedelta(seconds=offset)

    def schedule_now(self, base_time: datetime | None = None) -> datetime:
        """返回课程计算时间；课程偏移只在 NTP/系统基准时间后叠加一次。"""
        reference_time = base_time or self.now()
        return reference_time + timedelta(seconds=self._configs.schedule.time_offset)

    @Property(str, notify=updated)
    def currentTime(self) -> str:
        """设置页显示真实基准时间，不应用课程偏移。"""
        return self.now().strftime("%H:%M:%S")

    @Property(str, notify=updated)
    def currentDate(self) -> str:
        """设置页显示真实基准日期，不应用课程偏移。"""
        return self.now().strftime("%Y-%m-%d")

    @Property(bool, notify=updated)
    def preciseTimeAvailable(self) -> bool:
        with self._lock:
            return self._ntp_available

    @Property(bool, notify=updated)
    def syncing(self) -> bool:
        with self._lock:
            return self._syncing

    @Property(str, notify=updated)
    def statusText(self) -> str:
        with self._lock:
            return self._status_text

    @Property(str, notify=updated)
    def selectedServer(self) -> str:
        return self._configs.time.ntp_server

    @Slot()
    def sync(self) -> None:
        """从当前配置的 NTP 服务器异步同步时间。"""
        server = self._configs.time.ntp_server.strip()
        if not server:
            self._set_failure(self.tr("未指定 NTP 服务器，正在使用系统时间"))
            return

        with self._lock:
            if self._syncing:
                return
            self._syncing = True
            self._status_text = self.tr("正在与 {0} 同步…").format(server)
        self.updated.emit()

        self._sync_thread = Thread(
            target=self._sync_worker,
            args=(server,),
            name="ClassWidgetsNtpSync",
            daemon=True,
        )
        self._sync_thread.start()

    @Slot()
    def synchronizeTime(self) -> None:
        """为 QML 提供语义明确的同步入口。"""
        self.sync()

    @Slot(bool)
    def setPreciseTimeEnabled(self, enabled: bool) -> None:
        self._configs.set("time.use_precise_time", enabled)
        if enabled:
            self.sync()
        else:
            with self._lock:
                self._status_text = self.tr("正在使用系统时间")
            self.updated.emit()

    def _sync_worker(self, server: str) -> None:
        try:
            offset = self._query_ntp_offset(server)
        except Exception as exc:
            logger.warning("NTP synchronization with {} failed: {}", server, exc)
            self._syncResult.emit(False, 0.0, server, str(exc))
            return
        self._syncResult.emit(True, offset, server, "")

    @Slot(bool, float, str, str)
    def _apply_sync_result(self, success: bool, offset: float, server: str, _error: str) -> None:
        with self._lock:
            self._syncing = False
            self._ntp_available = success
            if success:
                self._ntp_offset_seconds = offset
                self._status_text = self.tr("已与 {0} 同步").format(server)
            else:
                self._ntp_offset_seconds = 0.0
                self._status_text = self.tr("NTP 同步失败，正在使用系统时间")
        self.updated.emit()
        self.syncFinished.emit(success)

    def _set_failure(self, message: str) -> None:
        with self._lock:
            self._syncing = False
            self._ntp_available = False
            self._ntp_offset_seconds = 0.0
            self._status_text = message
        self.updated.emit()
        self.syncFinished.emit(False)

    @staticmethod
    def _query_ntp_offset(server: str) -> float:
        """查询 NTP 响应并以本地发送/接收中点估算时钟偏差。"""
        addresses = socket.getaddrinfo(
            server,
            _NTP_PORT,
            type=socket.SOCK_DGRAM,
        )
        if not addresses:
            raise OSError("No address found for NTP server")

        request = b"\x1b" + (b"\0" * (_NTP_PACKET_SIZE - 1))
        last_error: OSError | None = None
        for family, socktype, protocol, _canonical_name, address in addresses:
            try:
                with socket.socket(family, socktype, protocol) as client:
                    client.settimeout(_NTP_TIMEOUT_SECONDS)
                    sent_at = time.time()
                    client.sendto(request, address)
                    response, _ = client.recvfrom(_NTP_PACKET_SIZE)
                    received_at = time.time()
                if len(response) < _NTP_PACKET_SIZE:
                    raise OSError("Incomplete NTP response")

                seconds, fraction = struct.unpack("!II", response[40:48])
                if seconds == 0:
                    raise OSError("Invalid NTP transmit timestamp")
                server_timestamp = (
                    seconds - _NTP_TIMESTAMP_DELTA + fraction / 2**32
                )
                return server_timestamp - ((sent_at + received_at) / 2)
            except OSError as exc:
                last_error = exc

        raise last_error or OSError("Unable to query NTP server")
