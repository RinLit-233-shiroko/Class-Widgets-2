"""崩溃归因规则：判断未处理异常是不是由某个（第三方）插件引发的。

设计原则：
- **规则化**：每条规则只回答一个问题，命中后给出可解释的规则名与置信度，
  报告窗口据此决定要不要提示用户禁用插件。
- **宁可漏报，不可误报**：只有堆栈里真的出现了插件代码才归因；内置插件属于
  应用自身代码，永远不作为“可禁用的第三方插件”上报。
- **不依赖 Qt**：这里只处理路径、模块名和字符串，方便单元测试。
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from types import TracebackType
from typing import Optional, Sequence

#: 外部插件模块的导入前缀，见 :meth:`src.core.plugin.loader.PluginLoader._load_external_plugin`。
PLUGIN_MODULE_PREFIX = "cw_plugin_"

# 规则标识：报告窗口与日志用它解释“为什么怀疑这个插件”。
RULE_MODULE = "plugin-module"  # 堆栈落在 cw_plugin_<id> 模块里
RULE_PATH = "plugin-path"  # 堆栈落在插件目录内
RULE_MESSAGE = "plugin-message"  # 异常文本里提到了插件目录（如 QML 加载失败）
RULE_CONTEXT = "plugin-context"  # 异常发生在插件生命周期回调中

CONFIDENCE_HIGH = "high"
CONFIDENCE_MEDIUM = "medium"
CONFIDENCE_LOW = "low"


@dataclass(frozen=True)
class PluginRecord:
    """归因所需的最小插件描述，由崩溃上下文提供。"""

    plugin_id: str
    name: str = ""
    version: str = ""
    icon: str = ""
    path: str = ""
    builtin: bool = False

    @property
    def display_name(self) -> str:
        return self.name or self.plugin_id


@dataclass(frozen=True)
class TraceFrame:
    """堆栈中的一帧，只保留归因需要的字段。"""

    filename: str
    module: str = ""
    function: str = ""
    lineno: int = 0


@dataclass(frozen=True)
class PluginSuspect:
    """被怀疑引发崩溃的插件。"""

    plugin_id: str
    name: str = ""
    version: str = ""
    icon: str = ""
    builtin: bool = False
    rule: str = RULE_PATH
    confidence: str = CONFIDENCE_MEDIUM

    @property
    def display_name(self) -> str:
        return self.name or self.plugin_id


@dataclass(frozen=True)
class CrashDiagnosis:
    """一次崩溃的归因结论。"""

    suspect: Optional[PluginSuspect] = None
    evidence: tuple[str, ...] = ()

    @property
    def blames_plugin(self) -> bool:
        return self.suspect is not None

    @property
    def plugin_id(self) -> str:
        return self.suspect.plugin_id if self.suspect else ""

    @property
    def plugin_name(self) -> str:
        return self.suspect.display_name if self.suspect else ""

    @property
    def rule(self) -> str:
        return self.suspect.rule if self.suspect else ""

    @property
    def confidence(self) -> str:
        return self.suspect.confidence if self.suspect else ""


EMPTY_DIAGNOSIS = CrashDiagnosis()


# ---------------------------------------------------------------- 工具函数
def _normalize_path(path: str) -> str:
    """把路径归一化成可以可靠比较的形式；拿不到就返回空串。"""
    if not path:
        return ""
    try:
        return os.path.normcase(os.path.abspath(path))
    except (OSError, ValueError):
        return ""


def _is_within(child: str, parent: str) -> bool:
    """``child`` 是否位于 ``parent`` 目录内（都需先归一化）。"""
    if not child or not parent:
        return False
    parent = parent.rstrip("\\/")
    if child == parent:
        return True
    return child.startswith(parent + os.sep)


def iter_traceback_frames(exc_tb: Optional[TracebackType]) -> tuple[TraceFrame, ...]:
    """按“由外到内”的顺序展开 traceback，最后一帧是抛出点。"""
    frames: list[TraceFrame] = []
    current = exc_tb
    while current is not None:
        code = current.tb_frame.f_code
        frames.append(
            TraceFrame(
                filename=str(code.co_filename or ""),
                module=str(current.tb_frame.f_globals.get("__name__", "")),
                function=str(code.co_name or ""),
                lineno=int(current.tb_lineno or 0),
            )
        )
        current = current.tb_next
    return tuple(frames)


def plugin_id_from_module(module: str) -> str:
    """``cw_plugin_<id>`` → ``<id>``；不是插件模块时返回空串。"""
    if module.startswith(PLUGIN_MODULE_PREFIX):
        return module[len(PLUGIN_MODULE_PREFIX):]
    return ""


# ---------------------------------------------------------------- 插件索引
class _PluginIndex:
    """把插件清单整理成可以按 id / 路径查的索引。

    内置插件被排除在外：它们是应用自己的代码，出问题应该修应用，而不是让用户
    去“禁用插件”。
    """

    def __init__(self, plugins: Sequence[PluginRecord]) -> None:
        self._by_id: dict[str, PluginRecord] = {}
        self._builtin_ids: set[str] = set()
        self._paths: list[tuple[str, PluginRecord]] = []
        for record in plugins:
            if not record.plugin_id:
                continue
            if record.builtin:
                self._builtin_ids.add(record.plugin_id)
                continue
            self._by_id[record.plugin_id] = record
            normalized = _normalize_path(record.path)
            if normalized:
                self._paths.append((normalized, record))
        # 长路径优先，避免父目录抢先匹配到子插件的文件。
        self._paths.sort(key=lambda item: len(item[0]), reverse=True)

    def by_id(self, plugin_id: str) -> Optional[PluginRecord]:
        """按 id 查第三方插件；内置插件与未知 id 都返回 None。"""
        if not plugin_id:
            return None
        return self._by_id.get(plugin_id)

    def is_builtin(self, plugin_id: str) -> bool:
        """这个 id 是否对应一个内置插件（属于应用自身，不应被归因）。"""
        return plugin_id in self._builtin_ids

    def by_path(self, filename: str) -> Optional[PluginRecord]:
        normalized = _normalize_path(filename)
        if not normalized:
            return None
        for path, record in self._paths:
            if _is_within(normalized, path):
                return record
        return None

    def match_text(self, text: str) -> Optional[PluginRecord]:
        """异常文本里是否直接出现了某个插件的目录。"""
        normalized = _normalize_path(text)
        if not normalized:
            return None
        for path, record in self._paths:
            if path and path in normalized:
                return record
        return None


def _suspect_from_record(
    record: PluginRecord,
    *,
    rule: str,
    confidence: str,
) -> PluginSuspect:
    return PluginSuspect(
        plugin_id=record.plugin_id,
        name=record.display_name,
        version=record.version,
        icon=record.icon,
        builtin=record.builtin,
        rule=rule,
        confidence=confidence,
    )


def _suspect_from_id(plugin_id: str, index: _PluginIndex, *, rule: str, confidence: str) -> PluginSuspect:
    record = index.by_id(plugin_id)
    if record is None:
        # 元数据缺失（例如清单损坏）时仍然如实上报，只是没有名字和图标。
        record = PluginRecord(plugin_id=plugin_id)
    return _suspect_from_record(record, rule=rule, confidence=confidence)


# ---------------------------------------------------------------- 归因规则
def diagnose_exception(
    exc_tb: Optional[TracebackType],
    exc_value: Optional[BaseException] = None,
    *,
    plugins: Sequence[PluginRecord] = (),
    active_plugin_id: str = "",
    message: str = "",
) -> CrashDiagnosis:
    """按规则判断这次崩溃该不该归因到某个插件。

    规则按优先级执行，先命中先返回：

    1. ``plugin-path`` / ``plugin-module``：堆栈里出现插件代码。取**最深**的一帧，
       即离抛出点最近的那一帧；如果抛出点本身就是插件代码，置信度为 high。
    2. ``plugin-message``：异常文本里出现插件目录（QML/资源加载失败的典型形态）。
    3. ``plugin-context``：异常发生在插件生命周期回调中（堆栈里没有插件帧，
       但插件上下文尚未交还）。
    """
    index = _PluginIndex(plugins)
    frames = iter_traceback_frames(exc_tb)

    # 规则 1：帧级规则。
    matches: list[tuple[int, PluginSuspect]] = []
    for position, frame in enumerate(frames):
        record = index.by_path(frame.filename)
        if record is not None:
            matches.append(
                (position, _suspect_from_record(record, rule=RULE_PATH, confidence=CONFIDENCE_HIGH))
            )
            continue
        plugin_id = plugin_id_from_module(frame.module)
        # 内置插件用同样的前缀注册不了，但 id 可能来自其它途径，显式排除。
        if plugin_id and not index.is_builtin(plugin_id):
            matches.append(
                (position, _suspect_from_id(plugin_id, index, rule=RULE_MODULE, confidence=CONFIDENCE_HIGH))
            )

    if matches:
        position, suspect = matches[-1]
        # 抛出点就落在插件里 → high；插件只是调用链上的一环 → medium。
        if position != len(frames) - 1:
            suspect = PluginSuspect(
                plugin_id=suspect.plugin_id,
                name=suspect.name,
                version=suspect.version,
                icon=suspect.icon,
                builtin=suspect.builtin,
                rule=suspect.rule,
                confidence=CONFIDENCE_MEDIUM,
            )
        frame = frames[position]
        evidence = (f"{frame.filename}:{frame.lineno} in {frame.function or '<module>'}",)
        return CrashDiagnosis(suspect=suspect, evidence=evidence)

    # 规则 2：异常文本里直接提到了插件目录。
    text = message or (str(exc_value) if exc_value is not None else "")
    record = index.match_text(text)
    if record is not None:
        return CrashDiagnosis(
            suspect=_suspect_from_record(record, rule=RULE_MESSAGE, confidence=CONFIDENCE_MEDIUM),
            evidence=(f"插件目录出现在错误信息中：{record.path}",),
        )

    # 规则 3：插件生命周期回调中抛出，且堆栈已不可追溯。
    if active_plugin_id:
        record = index.by_id(active_plugin_id)
        if record is not None:
            return CrashDiagnosis(
                suspect=_suspect_from_record(
                    record, rule=RULE_CONTEXT, confidence=CONFIDENCE_LOW
                ),
                evidence=(f"异常发生在插件 {record.display_name} 的加载回调中",),
            )

    return EMPTY_DIAGNOSIS


__all__ = [
    "CONFIDENCE_HIGH",
    "CONFIDENCE_LOW",
    "CONFIDENCE_MEDIUM",
    "CrashDiagnosis",
    "EMPTY_DIAGNOSIS",
    "PLUGIN_MODULE_PREFIX",
    "PluginRecord",
    "PluginSuspect",
    "RULE_CONTEXT",
    "RULE_MESSAGE",
    "RULE_MODULE",
    "RULE_PATH",
    "TraceFrame",
    "diagnose_exception",
    "iter_traceback_frames",
    "plugin_id_from_module",
]
