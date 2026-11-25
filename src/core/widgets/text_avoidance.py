from __future__ import annotations

import asyncio
import ctypes
import os
import re
import sys
import threading
import time
from ctypes import wintypes
from typing import TYPE_CHECKING

from loguru import logger
from PySide6.QtCore import (
    QBuffer,
    QByteArray,
    QIODevice,
    QObject,
    Property,
    QThread,
    QTimer,
    Qt,
    Signal,
    Slot,
)
from PySide6.QtGui import QImage

if TYPE_CHECKING:
    from src.core.central import AppCentral

IS_WINDOWS = sys.platform == "win32"

# WinRT 模块按需导入（第一次启用防挡文字时），避免功能未使用也常驻约 10MB。

if IS_WINDOWS:
    import win32gui
    import win32process

# 扫描周期：内容变化才 OCR，因此周期只决定 PrintWindow 与哈希的节奏
SCAN_INTERVAL_SECONDS = 1.0
# 连续多少次未检测到文字才恢复不透明度。窗口切换有单独的立即恢复路径，
# 这里只兜底同窗口内的内容变化，1 次即可避免明显延迟。
RESTORE_MISSES = 1
# 已淡化的组件每隔多少秒强制 OCR 一次，即使缩略图签名没有变化，
# 避免「小范围文字消失但变化量低于阈值」时一直卡在淡化状态。
FORCE_RECHECK_SECONDS = 5.0
# 裁剪时向外扩展的像素，避免文字被切掉一半导致 OCR 认不出
CROP_MARGIN_PX = 12
# 至少识别出多少个有效字符才算「明确有文字」
MIN_TEXT_CHARS = 2
# 内容变化检测：缩略图的宽度与平均灰度差阈值。
# 光标闪烁、轻微动画不会触发重新 OCR，整页/幻灯片切换会。
SIGNATURE_WIDTH = 32
SIGNATURE_DIFF_THRESHOLD = 2.0

_SYSTEM_CLASSES = {
    "Progman",  # 桌面
    "WorkerW",
    "Shell_TrayWnd",  # 任务栏
    "Shell_SecondaryTrayWnd",
}
_WS_EX_TRANSPARENT = 0x00000020
_WS_EX_LAYERED = 0x00080000
_GWL_EXSTYLE = -20
_DWMWA_CLOAKED = 14
_PW_RENDERFULLCONTENT = 0x00000002

_TEXT_CHAR_RE = re.compile(
    r"[0-9A-Za-z㐀-䶿一-鿿぀-ヿ가-힯]"
)


class _BitmapInfoHeader(ctypes.Structure):
    _fields_ = [
        ("biSize", wintypes.DWORD),
        ("biWidth", wintypes.LONG),
        ("biHeight", wintypes.LONG),
        ("biPlanes", wintypes.WORD),
        ("biBitCount", wintypes.WORD),
        ("biCompression", wintypes.DWORD),
        ("biSizeImage", wintypes.DWORD),
        ("biXPelsPerMeter", wintypes.LONG),
        ("biYPelsPerMeter", wintypes.LONG),
        ("biClrUsed", wintypes.DWORD),
        ("biClrImportant", wintypes.DWORD),
    ]


def _is_cloaked(hwnd: int) -> bool:
    """被 DWM 隐藏（切走的 UWP、虚拟桌面等）的窗口不应视为可见。"""
    try:
        value = wintypes.DWORD(0)
        result = ctypes.windll.dwmapi.DwmGetWindowAttribute(
            wintypes.HWND(hwnd),
            _DWMWA_CLOAKED,
            ctypes.byref(value),
            ctypes.sizeof(value),
        )
        return result == 0 and value.value != 0
    except Exception:  # noqa: BLE001
        return False


def _collect_windows(our_pid: int) -> list[tuple[int, tuple[int, int, int, int]]]:
    """按 Z 序（从上到下）收集可作为「小组件下方内容」的可见窗口。"""
    windows: list[tuple[int, tuple[int, int, int, int]]] = []

    def visit(hwnd: int, _) -> bool:
        try:
            if not win32gui.IsWindowVisible(hwnd) or win32gui.IsIconic(hwnd):
                return True
            if win32gui.GetClassName(hwnd) in _SYSTEM_CLASSES:
                return True
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            if pid == our_pid:
                return True
            ex_style = win32gui.GetWindowLong(hwnd, _GWL_EXSTYLE)
            # 点击穿透或半透明的悬浮层不参与视觉遮挡判断：
            # 它们不会真正遮住下方内容，文字仍来自后面的窗口。
            if ex_style & (_WS_EX_TRANSPARENT | _WS_EX_LAYERED):
                return True
            if _is_cloaked(hwnd):
                return True
            left, top, right, bottom = win32gui.GetWindowRect(hwnd)
            if right <= left or bottom <= top:
                return True
            windows.append((hwnd, (left, top, right, bottom)))
        except Exception:  # noqa: BLE001
            pass
        return True

    try:
        win32gui.EnumWindows(visit, None)
    except Exception as exc:  # noqa: BLE001
        logger.debug("Text avoidance: failed to enumerate windows: {}", exc)
    return windows


def _capture_window(
    hwnd: int, window_rect: tuple[int, int, int, int]
) -> QImage | None:
    """PrintWindow 抓取窗口自身画面；窗口被遮挡时也能拿到内容。"""
    left, top, right, bottom = window_rect
    width, height = right - left, bottom - top
    if width <= 0 or height <= 0:
        return None

    user32 = ctypes.windll.user32
    gdi32 = ctypes.windll.gdi32
    hwnd_dc = mem_dc = bitmap = None
    old_object = None
    try:
        hwnd_dc = user32.GetWindowDC(hwnd)
        if not hwnd_dc:
            return None
        mem_dc = gdi32.CreateCompatibleDC(hwnd_dc)
        bitmap = gdi32.CreateCompatibleBitmap(hwnd_dc, width, height)
        if not mem_dc or not bitmap:
            return None
        old_object = gdi32.SelectObject(mem_dc, bitmap)
        if not user32.PrintWindow(hwnd, mem_dc, _PW_RENDERFULLCONTENT):
            return None

        header = _BitmapInfoHeader()
        header.biSize = ctypes.sizeof(_BitmapInfoHeader)
        header.biWidth = width
        header.biHeight = -height  # top-down
        header.biPlanes = 1
        header.biBitCount = 32
        header.biCompression = 0  # BI_RGB
        buffer = ctypes.create_string_buffer(width * height * 4)
        if not gdi32.GetDIBits(
            mem_dc, bitmap, 0, height, buffer, ctypes.byref(header), 0
        ):
            return None
        # Format_RGB32 在小端机器上的内存布局与 32bpp BI_RGB 一致
        return QImage(buffer, width, height, width * 4, QImage.Format_RGB32).copy()
    except Exception as exc:  # noqa: BLE001
        logger.debug("Text avoidance: PrintWindow failed for {}: {}", hwnd, exc)
        return None
    finally:
        try:
            if old_object and mem_dc:
                gdi32.SelectObject(mem_dc, old_object)
            if bitmap:
                gdi32.DeleteObject(bitmap)
            if mem_dc:
                gdi32.DeleteDC(mem_dc)
            if hwnd_dc:
                user32.ReleaseDC(hwnd, hwnd_dc)
        except Exception:  # noqa: BLE001
            pass


def _crop_bounds(
    image_width: int,
    image_height: int,
    window_rect: tuple[int, int, int, int],
    widget_rect: tuple[int, int, int, int],
) -> tuple[int, int, int, int] | None:
    x, y, width, height = widget_rect
    win_left, win_top = window_rect[0], window_rect[1]
    x0 = max(0, x - win_left - CROP_MARGIN_PX)
    y0 = max(0, y - win_top - CROP_MARGIN_PX)
    x1 = min(image_width, x + width - win_left + CROP_MARGIN_PX)
    y1 = min(image_height, y + height - win_top + CROP_MARGIN_PX)
    if x1 - x0 < 8 or y1 - y0 < 8:
        return None
    return x0, y0, x1, y1


def _image_signature(image: QImage) -> bytes:
    height = max(1, round(SIGNATURE_WIDTH * image.height() / max(1, image.width())))
    small = image.scaled(
        SIGNATURE_WIDTH, height, Qt.IgnoreAspectRatio, Qt.SmoothTransformation
    ).convertToFormat(QImage.Format_Grayscale8)
    return bytes(small.constBits())


def _signature_changed(previous: bytes | None, current: bytes) -> bool:
    if previous is None or len(previous) != len(current):
        return True
    total = 0
    for old, new in zip(previous, current):
        total += abs(old - new)
    return total / len(current) > SIGNATURE_DIFF_THRESHOLD


def _has_text(text: str | None) -> bool:
    if not text:
        return False
    return len(_TEXT_CHAR_RE.findall(text)) >= MIN_TEXT_CHARS


def _sample_points(rect: tuple[int, int, int, int]) -> list[tuple[int, int]]:
    x, y, width, height = rect
    xs = (x + width * 0.5, x + width * 0.25, x + width * 0.75)
    ys = (y + height * 0.5, y + height * 0.25, y + height * 0.75)
    points = [(int(xs[0]), int(ys[0]))]
    for px in xs:
        for py in ys:
            point = (int(px), int(py))
            if point not in points:
                points.append(point)
    return points


def _create_ocr_engine():
    try:
        from winrt.windows.media.ocr import OcrEngine
    except Exception:  # noqa: BLE001
        return None
    try:
        languages = list(OcrEngine.available_recognizer_languages)
    except Exception:  # noqa: BLE001
        return None
    for prefix in ("zh", "en"):
        for language in languages:
            if language.language_tag.lower().startswith(prefix):
                try:
                    engine = OcrEngine.try_create_from_language(language)
                except Exception:  # noqa: BLE001
                    engine = None
                if engine is not None:
                    return engine
    try:
        return OcrEngine.try_create_from_user_profile_languages()
    except Exception:  # noqa: BLE001
        return None


class _ScanWorker(QThread):
    """后台扫描线程：窗口枚举 → PrintWindow → 裁剪哈希 → 变化时 OCR。"""

    resultReady = Signal(object)
    unavailable = Signal()

    def __init__(self, owner: "TextAvoidanceDetector") -> None:
        super().__init__(owner)
        self._owner = owner
        self._stop_event = threading.Event()
        self._wake_event = threading.Event()
        self._loop: asyncio.AbstractEventLoop | None = None
        self._engine = None
        self._cache: dict[str, tuple[int, bytes, bool]] = {}
        self._state: dict[str, bool] = {}
        self._misses: dict[str, int] = {}
        self._last_windows: dict[str, int | None] = {}
        self._last_ocr: dict[str, float] = {}
        self._last_emitted: dict[str, bool] = {}

    def wake(self) -> None:
        self._wake_event.set()

    def stop(self) -> None:
        self._stop_event.set()
        self._wake_event.set()
        if not self.wait(3000):
            logger.warning("Text avoidance worker did not stop in time")

    # ── thread body ──────────────────────────────────────

    def run(self) -> None:
        if not IS_WINDOWS:
            return
        try:
            self._loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self._loop)
            self._engine = _create_ocr_engine()
            if self._engine is None:
                logger.warning(
                    "Text avoidance disabled: OCR bindings or language pack unavailable"
                )
                self.unavailable.emit()
                return
            while not self._stop_event.is_set():
                self._wake_event.wait(SCAN_INTERVAL_SECONDS)
                self._wake_event.clear()
                if self._stop_event.is_set():
                    break
                if not self._owner.is_enabled():
                    self._reset()
                    continue
                rects = self._owner.snapshot_rects()
                if not rects:
                    self._reset()
                    continue
                try:
                    self._scan(rects)
                except Exception as exc:  # noqa: BLE001
                    logger.debug("Text avoidance scan failed: {}", exc)
        except Exception as exc:  # noqa: BLE001
            logger.warning("Text avoidance worker stopped: {}", exc)
            self.unavailable.emit()
        finally:
            self._engine = None
            if self._loop is not None:
                self._loop.close()
                self._loop = None

    def _reset(self) -> None:
        if self._state:
            self._state.clear()
            self._misses.clear()
            self._cache.clear()
            self._last_windows.clear()
            self._last_ocr.clear()
        self._emit({})

    def _emit(self, state: dict[str, bool]) -> None:
        if state != self._last_emitted:
            self._last_emitted = dict(state)
            self.resultReady.emit(dict(state))

    def _scan(self, rects: dict[str, tuple[int, int, int, int]]) -> None:
        now = time.monotonic()
        windows = _collect_windows(os.getpid())
        assigned: dict[str, int | None] = {}
        for instance_id, rect in rects.items():
            counts: dict[int | None, int] = {}
            for px, py in _sample_points(rect):
                hwnd = None
                for candidate, window_rect in windows:
                    if (
                        window_rect[0] <= px < window_rect[2]
                        and window_rect[1] <= py < window_rect[3]
                    ):
                        hwnd = candidate
                        break
                counts[hwnd] = counts.get(hwnd, 0) + 1
            assigned[instance_id] = max(counts, key=counts.get) if counts else None

        rect_by_hwnd = {hwnd: rect for hwnd, rect in windows}
        by_hwnd: dict[int | None, list[str]] = {}
        for instance_id, hwnd in assigned.items():
            by_hwnd.setdefault(hwnd, []).append(instance_id)

        results: dict[str, bool] = {}
        for hwnd, instance_ids in by_hwnd.items():
            if hwnd is None:
                for instance_id in instance_ids:
                    results[instance_id] = False
                continue
            window_rect = rect_by_hwnd.get(hwnd)
            image = _capture_window(hwnd, window_rect) if window_rect else None
            for instance_id in instance_ids:
                # 抓图/裁剪失败时结果是「未知」，保持上一轮状态，
                # 避免一次偶发失败就立刻恢复造成闪烁。
                if image is None:
                    continue
                bounds = _crop_bounds(
                    image.width(), image.height(), window_rect, rects[instance_id]
                )
                if bounds is None:
                    continue
                x0, y0, x1, y1 = bounds
                crop = image.copy(x0, y0, x1 - x0, y1 - y0)
                signature = _image_signature(crop)
                cached = self._cache.get(instance_id)
                # 已淡化的组件定期强制复检，避免签名变化低于阈值时一直卡住
                force_recheck = (
                    self._state.get(instance_id, False)
                    and now - self._last_ocr.get(instance_id, 0.0)
                    >= FORCE_RECHECK_SECONDS
                )
                if (
                    cached
                    and cached[0] == hwnd
                    and not _signature_changed(cached[1], signature)
                    and not force_recheck
                ):
                    results[instance_id] = cached[2]
                    continue
                try:
                    text = self._loop.run_until_complete(self._recognize(crop))
                except Exception as exc:  # noqa: BLE001
                    logger.debug("Text avoidance OCR failed: {}", exc)
                    continue
                occluded = _has_text(text)
                self._cache[instance_id] = (hwnd, signature, occluded)
                self._last_ocr[instance_id] = now
                results[instance_id] = occluded

        final: dict[str, bool] = {}
        for instance_id in rects:
            current_hwnd = assigned.get(instance_id)
            # 组件下方换了一个窗口（切应用、最小化、回桌面）：旧窗口的文字已不可见，
            # 没必要再等迟滞轮次，直接恢复。
            window_changed = (
                instance_id in self._last_windows
                and self._last_windows[instance_id] != current_hwnd
            )
            self._last_windows[instance_id] = current_hwnd

            detected = results.get(instance_id)
            if detected is True:
                self._state[instance_id] = True
                self._misses[instance_id] = 0
            elif detected is False:
                if window_changed:
                    self._state[instance_id] = False
                    self._misses[instance_id] = 0
                elif self._state.get(instance_id):
                    misses = self._misses.get(instance_id, 0) + 1
                    self._misses[instance_id] = misses
                    if misses >= RESTORE_MISSES:
                        self._state[instance_id] = False
                else:
                    self._state[instance_id] = False
            # detected is None：本轮无法判断，沿用上一轮状态
            final[instance_id] = self._state.get(instance_id, False)

        for store in (
            self._cache,
            self._state,
            self._misses,
            self._last_windows,
            self._last_ocr,
        ):
            for instance_id in list(store):
                if instance_id not in rects:
                    store.pop(instance_id, None)
        self._emit(final)

    async def _recognize(self, image: QImage) -> str:
        from winrt.windows.graphics.imaging import BitmapDecoder
        from winrt.windows.storage.streams import (
            DataWriter,
            InMemoryRandomAccessStream,
        )

        encoded = QByteArray()
        buffer = QBuffer(encoded)
        buffer.open(QIODevice.WriteOnly)
        image.save(buffer, "PNG")
        buffer.close()
        stream = InMemoryRandomAccessStream()
        writer = DataWriter(stream)
        writer.write_bytes(bytes(encoded.data()))
        await writer.store_async()
        stream.seek(0)
        decoder = await BitmapDecoder.create_async(stream)
        bitmap = await decoder.get_software_bitmap_async()
        result = await self._engine.recognize_async(bitmap)
        return result.text


class TextAvoidanceDetector(QObject):
    """对外暴露每个小组件实例当前是否被文字遮挡。"""

    occludedWidgetsChanged = Signal()

    def __init__(self, central: "AppCentral") -> None:
        super().__init__(central)
        self._central = central
        self._occluded: dict[str, bool] = {}
        self._rects: dict[str, tuple[int, int, int, int]] = {}
        self._enabled = False
        # WinRT/OCR 在第一次启用时才加载；未使用时这里只是乐观可用状态
        self._available = IS_WINDOWS
        self._worker: _ScanWorker | None = None
        self._last_foreground: int | None = None
        self._foreground_timer = QTimer(self)
        self._foreground_timer.setInterval(250)
        self._foreground_timer.timeout.connect(self._poll_foreground)
        if not IS_WINDOWS:
            logger.info("Text avoidance is unavailable on this platform")
        try:
            central.configs.configChanged.connect(self._apply_config)
        except Exception:  # noqa: BLE001
            pass
        self._apply_config()

    @Property("QVariantMap", notify=occludedWidgetsChanged)
    def occludedWidgets(self) -> dict[str, bool]:
        return self._occluded

    @Property(bool, notify=occludedWidgetsChanged)
    def available(self) -> bool:
        return self._available

    def _apply_config(self) -> None:
        try:
            enabled = bool(self._central.configs.interactions.hide.text_avoid)
        except Exception:  # noqa: BLE001
            enabled = False
        enabled = enabled and self._available
        if enabled == self._enabled:
            return
        self._enabled = enabled
        if not enabled:
            self._rects = {}
            self._foreground_timer.stop()
            self._last_foreground = None
            if self._occluded:
                self._occluded = {}
                self.occludedWidgetsChanged.emit()
        else:
            self._foreground_timer.start()
            self._ensure_worker()
        if self._worker is not None:
            self._worker.wake()
        if enabled:
            window = getattr(self._central, "widgets_window", None)
            if window is not None:
                try:
                    window.schedule_mask_update()
                except Exception:  # noqa: BLE001
                    pass

    def _ensure_worker(self) -> None:
        """延迟创建扫描线程：第一次启用时才加载 WinRT 与 OCR 引擎。"""
        if self._worker is not None or not self._available or not IS_WINDOWS:
            return
        worker = _ScanWorker(self)
        worker.resultReady.connect(self._on_result)
        worker.unavailable.connect(self._on_unavailable)
        self._worker = worker
        worker.start()

    def _poll_foreground(self) -> None:
        """前台窗口变化时立即补扫，不必等下一个周期。"""
        if not self._enabled or self._worker is None or not IS_WINDOWS:
            return
        try:
            hwnd = int(win32gui.GetForegroundWindow())
        except Exception:  # noqa: BLE001
            return
        if hwnd != self._last_foreground:
            self._last_foreground = hwnd
            self._worker.wake()

    def is_enabled(self) -> bool:
        return self._enabled

    def snapshot_rects(self) -> dict[str, tuple[int, int, int, int]]:
        return self._rects

    def set_widget_rects(self, rects: dict[str, tuple[int, int, int, int]]) -> None:
        if not self._enabled:
            return
        if rects == self._rects:
            return
        self._rects = rects
        if self._worker is not None:
            self._worker.wake()

    @Slot(object)
    def _on_result(self, result) -> None:
        state = result if isinstance(result, dict) else {}
        if state != self._occluded:
            self._occluded = state
            self.occludedWidgetsChanged.emit()

    @Slot()
    def _on_unavailable(self) -> None:
        self._available = False
        self._worker = None
        self._rects = {}
        self._enabled = False
        self._foreground_timer.stop()
        self._last_foreground = None
        self._occluded = {}
        self.occludedWidgetsChanged.emit()

    def stop(self) -> None:
        worker = self._worker
        self._worker = None
        if worker is not None:
            worker.stop()
