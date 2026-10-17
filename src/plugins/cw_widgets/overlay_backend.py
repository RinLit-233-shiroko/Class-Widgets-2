# -*- coding: utf-8 -*-
"""堆叠组件后端（QObject，供组件/对话框/设置页调用）。

自 v3 起支持"按实例隔离"：桌面上可同时放置多个堆叠组件（com.overlay），
每个实例（instanceId）拥有独立的成员列表、成员设置与自定义框尺寸，
互不干扰。调用方（overlay.qml / AddOverlayMemberDialog / overlay-settings.qml）
把当前实例的 instanceId 作为首个参数传入。

持久化（兼容旧单组格式，旧数据自动归入 default 组；第一个被识别的实例
会把 default 组"认领"走，其余实例从空组开始，天然互不干扰）：
  .overlay_members.json          每实例成员列表
  .overlay_member_settings.json  每实例成员个性化设置（按成员 key）
  .overlay_frames.json           每实例自定义框宽高（0 = 跟随内容自适应）
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path

from loguru import logger
from PySide6.QtCore import Property, QObject, Signal, Slot

_OVERLAY_WIDGET_ID = "classwidgets.overlay"  # 堆叠组件自身 widget id（禁止添加自己）
_DEFAULT = "default"                # 旧单组数据的归属组


def _data_dir() -> Path:
    """堆叠组件的数据目录：<主程序工作目录>/configs/overlay。

    放在主程序的 configs/ 下而不是组件所在目录，便于随工作目录一起迁移，
    也不会被程序更新覆盖。
    """
    try:
        try:
            from src.core.storage.directories import CONFIGS_PATH
        except ImportError:
            from core.storage.directories import CONFIGS_PATH

        d = CONFIGS_PATH / "overlay"
        d.mkdir(parents=True, exist_ok=True)
        return d
    except Exception:
        return Path(__file__).resolve().parent


def _data_file(name: str) -> Path:
    """数据文件路径；顺带把旧版写在插件目录里的同名文件迁移一次。"""
    old = Path(__file__).resolve().parent / name
    new = _data_dir() / name
    try:
        if old.exists() and not new.exists():
            new.parent.mkdir(parents=True, exist_ok=True)
            new.write_bytes(old.read_bytes())
    except Exception:
        pass
    return new


def _normalize(instance_id) -> str:
    return str(instance_id or "").strip() or _DEFAULT


class OverlayBackend(QObject):
    """堆叠组件后端：按实例隔离的成员管理 + 轮播/框尺寸 + 上课隐藏切换条。"""

    membersChanged = Signal()
    frameChanged = Signal()
    classHideChanged = Signal()
    _class_hide = {"enabled": False, "days": "1,2,3,4,5", "start": "08:00", "end": "18:00"}

    def __init__(self, parent=None):
        super().__init__(parent)
        # store: gid -> {"members": [{key,typeId}...], "settings": {key: {...}}, "frame": {"w":0,"h":0}}
        self._store: dict[str, dict] = {}
        self._members_file = _data_file(".overlay_members.json")
        self._settings_file = _data_file(".overlay_member_settings.json")
        self._frames_file = _data_file(".overlay_frames.json")
        self._class_hide_file = _data_file(".overlay_class_hide.json")
        self._load_members()
        self._load_member_settings()
        self._load_frames()
        self._load_class_hide()

    # ── 上课隐藏切换条（全局，各实例共用同一时段配置）────────────

    def _load_class_hide(self) -> None:
        try:
            data = json.loads(self._class_hide_file.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                for k in ("enabled", "days", "start", "end"):
                    if k in data:
                        self._class_hide[k] = data[k]
        except Exception:
            pass

    def _save_class_hide(self) -> None:
        try:
            self._class_hide_file.write_text(
                json.dumps(self._class_hide, ensure_ascii=False, indent=2), encoding="utf-8")
        except Exception as e:
            logger.warning(f"[more_settings] 保存上课时段配置失败: {e}")

    def _get_class_hide_enabled(self) -> bool:
        return bool(self._class_hide.get("enabled"))

    def _get_class_hide_days(self) -> str:
        return str(self._class_hide.get("days") or "")

    def _get_class_hide_start(self) -> str:
        return str(self._class_hide.get("start") or "")

    def _get_class_hide_end(self) -> str:
        return str(self._class_hide.get("end") or "")

    classHideEnabled = Property(bool, _get_class_hide_enabled, notify=classHideChanged)
    classHideDays = Property(str, _get_class_hide_days, notify=classHideChanged)
    classHideStart = Property(str, _get_class_hide_start, notify=classHideChanged)
    classHideEnd = Property(str, _get_class_hide_end, notify=classHideChanged)

    @Slot(bool, str, str, str)
    def setClassHide(self, enabled: bool, days: str, start: str, end: str) -> None:
        self._class_hide.update(enabled=bool(enabled), days=str(days or ""),
                                start=str(start or ""), end=str(end or ""))
        self._save_class_hide()
        self.classHideChanged.emit()

    @Slot()
    def refreshClassHide(self) -> None:
        self.classHideChanged.emit()

    # ── 实例分组 ─────────────────────────────────────────────

    def _claim(self, gid: str) -> None:
        """旧数据认领：default 组仅被第一个遇到的实名实例取走，并立即落盘。"""
        if gid == _DEFAULT or gid in self._store:
            return
        if self._store.get(_DEFAULT):
            self._store[gid] = self._store.pop(_DEFAULT)
            self._save_all()  # 迁移立即持久化，避免旧成员设置丢失

    def _group(self, instance_id) -> dict:
        gid = _normalize(instance_id)
        self._claim(gid)
        return self._store.setdefault(gid, {"members": [], "settings": {}, "frame": {"w": 0, "h": 0}})

    # ── 成员管理（按实例）────────────────────────────────────

    @Slot(str, result=list)
    def getMembers(self, instance_id: str) -> list:
        """返回该实例成员对象列表：[{"key", "typeId"}, ...]（副本）。"""
        return [dict(m) for m in self._group(instance_id)["members"]]

    @Slot(str, result=int)
    def getMemberCount(self, instance_id: str) -> int:
        return len(self._group(instance_id)["members"])

    @Slot(str, str, result=str)
    def addMember(self, instance_id: str, widget_id: str) -> str:
        """为该实例添加成员（允许同一组件 id 重复）。返回新成员 key，失败返回空串。"""
        if not isinstance(widget_id, str):
            return ""
        wid = widget_id.strip()
        if not wid or wid == _OVERLAY_WIDGET_ID:
            return ""
        grp = self._group(instance_id)
        key = f"{wid}#{int(time.time() * 1000)}"
        grp["members"].append({"key": key, "typeId": wid})
        self._save_members()
        self.membersChanged.emit()
        logger.info(f"[more_settings] 堆叠 {_normalize(instance_id)} 添加成员: {key}")
        return key

    @Slot(str, str)
    def removeMember(self, instance_id: str, key: str) -> None:
        k = str(key).strip()
        grp = self._group(instance_id)
        for m in grp["members"]:
            if m["key"] == k:
                grp["members"].remove(m)
                grp["settings"].pop(k, None)
                self._save_members()
                self._save_member_settings()
                self.membersChanged.emit()
                logger.info(f"[more_settings] 堆叠 {_normalize(instance_id)} 移除成员: {k}")
                return

    @Slot(str, str, result=dict)
    def getMemberSettings(self, instance_id: str, key: str) -> dict:
        grp = self._group(instance_id)
        return dict(grp["settings"].get(str(key), {}))

    @Slot(str, str, dict)
    def saveMemberSettings(self, instance_id: str, key: str, settings: dict) -> None:
        k = str(key).strip()
        if not k:
            return
        grp = self._group(instance_id)
        grp["settings"][k] = dict(settings or {})
        self._save_member_settings()
        logger.info(f"[more_settings] 已保存堆叠成员设置: {k}")

    # ── 自定义组件框尺寸（按实例，0 = 跟随内容自适应）──────────

    @Slot(str, result=dict)
    def getFrameSize(self, instance_id: str) -> dict:
        return dict(self._group(instance_id)["frame"])

    @Slot(str, int, int)
    def setFrameSize(self, instance_id: str, w: int, h: int) -> None:
        grp = self._group(instance_id)
        grp["frame"]["w"] = max(0, int(w or 0))
        grp["frame"]["h"] = max(0, int(h or 0))
        self._save_frames()
        self.frameChanged.emit()
        logger.info(f"[more_settings] 堆叠 {_normalize(instance_id)} 框尺寸 -> {grp['frame']}")

    # ── 持久化 ───────────────────────────────────────────────

    @staticmethod
    def _atomic_write_json(path: Path, payload: dict) -> None:
        tmp = path.with_suffix(path.suffix + ".tmp")
        tmp.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
        os.replace(tmp, path)

    def _load_members(self) -> None:
        try:
            if self._members_file.exists():
                data = json.loads(self._members_file.read_text(encoding="utf-8"))
                groups: dict = data.get("instances") if isinstance(data, dict) else None
                if groups is None and isinstance(data, dict) and "members" in data:
                    groups = {_DEFAULT: data}  # 旧格式 {"members": [...]}
                self._store = {}
                for gid, obj in (groups or {}).items():
                    raw = obj.get("members") if isinstance(obj, dict) else obj
                    members = []
                    for x in (raw or []):
                        if isinstance(x, str):
                            wid = x.strip()
                            if wid and wid != _OVERLAY_WIDGET_ID:
                                members.append({"key": wid, "typeId": wid})
                        elif isinstance(x, dict) and str(x.get("typeId", "")).strip():
                            wid = str(x["typeId"]).strip()
                            if wid == _OVERLAY_WIDGET_ID:
                                continue
                            key = str(x.get("key") or "").strip() or f"{wid}#{int(time.time() * 1000)}"
                            members.append({"key": key, "typeId": wid})
                    seen = set()
                    uniq = []
                    for m in members:
                        if m["key"] not in seen:
                            seen.add(m["key"])
                            uniq.append(m)
                    self._store[str(gid)] = {"members": uniq, "settings": {}, "frame": {"w": 0, "h": 0}}
        except Exception:
            self._store = {}

    def _load_member_settings(self) -> None:
        try:
            if self._settings_file.exists():
                data = json.loads(self._settings_file.read_text(encoding="utf-8"))
                groups: dict = data.get("instances") if isinstance(data, dict) else None
                if groups is None and isinstance(data, dict) and "settings" in data:
                    groups = {_DEFAULT: data}  # 旧格式 {"settings": {...}}
                for gid, obj in (groups or {}).items():
                    entry = self._store.setdefault(str(gid),
                                                   {"members": [], "settings": {}, "frame": {"w": 0, "h": 0}})
                    raw = obj.get("settings") if isinstance(obj, dict) else {}
                    for k, v in (raw or {}).items():
                        if isinstance(v, dict):
                            entry["settings"][str(k)] = dict(v)
        except Exception:
            pass

    def _load_frames(self) -> None:
        try:
            if self._frames_file.exists():
                data = json.loads(self._frames_file.read_text(encoding="utf-8"))
                groups: dict = data.get("instances") if isinstance(data, dict) else None
                for gid, obj in (groups or {}).items():
                    if not isinstance(obj, dict):
                        continue
                    entry = self._store.setdefault(str(gid),
                                                   {"members": [], "settings": {}, "frame": {"w": 0, "h": 0}})
                    entry["frame"] = {"w": max(0, int(obj.get("w") or 0)),
                                      "h": max(0, int(obj.get("h") or 0))}
        except Exception:
            pass

    def _save_all(self) -> None:
        self._save_members()
        self._save_member_settings()
        self._save_frames()

    def _save_members(self) -> None:
        try:
            payload = {"instances": {gid: {"members": v["members"]}
                                     for gid, v in self._store.items()}}
            self._atomic_write_json(self._members_file, payload)
        except Exception as e:
            logger.warning(f"[more_settings] 保存成员列表失败: {e}")

    def _save_member_settings(self) -> None:
        try:
            payload = {"instances": {gid: {"settings": v["settings"]}
                                     for gid, v in self._store.items()}}
            self._atomic_write_json(self._settings_file, payload)
        except Exception as e:
            logger.warning(f"[more_settings] 保存成员设置失败: {e}")

    def _save_frames(self) -> None:
        try:
            payload = {"instances": {gid: dict(v["frame"]) for gid, v in self._store.items()}}
            self._atomic_write_json(self._frames_file, payload)
        except Exception as e:
            logger.warning(f"[more_settings] 保存框尺寸失败: {e}")
