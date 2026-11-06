
from __future__ import annotations

import json
import os
import time
from pathlib import Path

from loguru import logger
from PySide6.QtCore import Property, QObject, Signal, Slot

_OVERLAY_WIDGET_ID = "classwidgets.overlay"
_DEFAULT = "default"

def _data_dir() -> Path:
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

    membersChanged = Signal()
    classHideChanged = Signal()
    _class_hide = {"enabled": False, "days": "1,2,3,4,5", "start": "08:00", "end": "18:00"}

    def __init__(self, parent=None):
        super().__init__(parent)

        self._store: dict[str, dict] = {}
        self._members_file = _data_file(".overlay_members.json")
        self._settings_file = _data_file(".overlay_member_settings.json")
        self._class_hide_file = _data_file(".overlay_class_hide.json")
        self._load_members()
        self._load_member_settings()
        self._load_class_hide()

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
            logger.warning(f"[more_settings] Failed to save class period settings: {e}")

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

    def _claim(self, gid: str) -> None:
        if gid == _DEFAULT or gid in self._store:
            return
        if self._store.get(_DEFAULT):
            self._store[gid] = self._store.pop(_DEFAULT)
            self._save_all()

    def _group(self, instance_id) -> dict:
        gid = _normalize(instance_id)
        self._claim(gid)
        return self._store.setdefault(gid, {"members": [], "settings": {}})

    @Slot(str, result=list)
    def getMembers(self, instance_id: str) -> list:
        return [dict(m) for m in self._group(instance_id)["members"]]

    @Slot(str, result=int)
    def getMemberCount(self, instance_id: str) -> int:
        return len(self._group(instance_id)["members"])

    @Slot(str, str, result=str)
    def addMember(self, instance_id: str, widget_id: str) -> str:
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
        logger.info(f"[more_settings] overlay {_normalize(instance_id)} added member: {key}")
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
                logger.info(f"[more_settings] overlay {_normalize(instance_id)} removed member: {k}")
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
        logger.info(f"[more_settings] saved overlay member settings: {k}")

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
                    groups = {_DEFAULT: data}
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
                    self._store[str(gid)] = {"members": uniq, "settings": {}}
        except Exception:
            self._store = {}

    def _load_member_settings(self) -> None:
        try:
            if self._settings_file.exists():
                data = json.loads(self._settings_file.read_text(encoding="utf-8"))
                groups: dict = data.get("instances") if isinstance(data, dict) else None
                if groups is None and isinstance(data, dict) and "settings" in data:
                    groups = {_DEFAULT: data}
                for gid, obj in (groups or {}).items():
                    entry = self._store.setdefault(str(gid),
                                                   {"members": [], "settings": {}})
                    raw = obj.get("settings") if isinstance(obj, dict) else {}
                    for k, v in (raw or {}).items():
                        if isinstance(v, dict):
                            entry["settings"][str(k)] = dict(v)
        except Exception:
            pass

    def _save_all(self) -> None:
        self._save_members()
        self._save_member_settings()

    def _save_members(self) -> None:
        try:
            payload = {"instances": {gid: {"members": v["members"]}
                                     for gid, v in self._store.items()}}
            self._atomic_write_json(self._members_file, payload)
        except Exception as e:
            logger.warning(f"[more_settings] Failed to save member list: {e}")

    def _save_member_settings(self) -> None:
        try:
            payload = {"instances": {gid: {"settings": v["settings"]}
                                     for gid, v in self._store.items()}}
            self._atomic_write_json(self._settings_file, payload)
        except Exception as e:
            logger.warning(f"[more_settings] Failed to save member settings: {e}")
