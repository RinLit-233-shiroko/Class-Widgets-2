"""仅保留远程定位问题所需的技术信息；本地报告仍保留原始详情。"""

import re
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, cast

if TYPE_CHECKING:
    from sentry_sdk._types import Event, Hint

TAG_KEYS = {
    "component",
    "stage",
    "plugin_id",
    "plugin_version",
    "plugin_type",
    "theme_id",
    "safe_mode",
    "phase",
    "source",
    "recovered",
    "status_code",
    "failure_code",
    "attribution_rule",
    "attribution_confidence",
}


def technical_value(value: object) -> str:
    text = str(value)
    return text if re.fullmatch(r"[\w.+:-]{1,128}", text, flags=re.ASCII) else "unknown"


def technical_tags(context: Mapping[str, object]) -> dict[str, str]:
    return {key: technical_value(value) for key, value in context.items() if key in TAG_KEYS}


def relative_filename(filename: str) -> str:
    normalized = filename.replace("\\", "/")
    for marker in ("src/", "site-packages/", "plugins/", "themes/"):
        start = normalized.find(marker)
        if start >= 0:
            relative = normalized[start:]
            if ".." not in relative.split("/"):
                return relative
    return "<external>"


def sanitize_log_message(message: str) -> str:
    text = re.sub(r"https?://[^\s<>]+", "<url>", message[:4000])
    text = re.sub(r"\b[A-Za-z]:[\\/][^\r\n]*|(?<!\w)/[^\r\n]*", "<path>", text)
    text = re.sub(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", "<email>", text)
    text = re.sub(r"(?i)\bBearer\s+\S+", "Bearer <redacted>", text)
    text = re.sub(
        r'''(?i)\b(password|passwd|(?:access_|refresh_|api_)?token|(?:client_)?secret|api[_-]?key|authorization)\b["']?\s*[:=]\s*(?:"[^"]*"|'[^']*'|[^\s,;]+)''',
        r"\1=<redacted>",
        text,
    )
    return text[:1000]


def sanitize_event(event: "Event", _hint: "Hint") -> "Event":
    # SDK payload 包含可选键和异构字段，在此边界解包后按白名单重建。
    data: dict[str, Any] = dict(event)
    clean: dict[str, Any] = {
        key: data[key]
        for key in (
            "event_id",
            "timestamp",
            "start_timestamp",
            "platform",
            "level",
            "release",
            "environment",
            "dist",
            "type",
            "fingerprint",
        )
        if key in data
    }
    clean["tags"] = technical_tags(data.get("tags", {}))
    contexts = data.get("contexts", {})
    clean["contexts"] = {
        name: {
            key: technical_value(value)
            for key, value in contexts.get(name, {}).items()
            if key in allowed and value is not None
        }
        for name, allowed in {
            "os": {"name", "version", "build", "kernel_version"},
            "runtime": {"name", "version"},
            "trace": {"trace_id", "span_id", "parent_span_id", "op", "status", "origin"},
        }.items()
        if name in contexts
    }
    values = []
    for exception in data.get("exception", {}).get("values", []):
        item: dict[str, Any] = {"type": technical_value(exception.get("type", "Exception"))}
        # 异常文本可能含课表、校验输入或第三方 Token，保留类型和堆栈即可。
        frames = []
        for frame in exception.get("stacktrace", {}).get("frames", []):
            frames.append(
                {
                    "filename": relative_filename(frame.get("filename", "")),
                    "function": technical_value(frame.get("function", "unknown")),
                    "lineno": frame.get("lineno"),
                    "in_app": bool(frame.get("in_app")),
                }
            )
        item["stacktrace"] = {"frames": frames}
        item["mechanism"] = {
            "type": "classwidgets",
            "handled": exception.get("mechanism", {}).get("handled", True),
        }
        values.append(item)
    if values:
        clean["exception"] = {"values": values}
    elif "logentry" in data:
        entry = data["logentry"]
        clean["logentry"] = {
            "message": sanitize_log_message(str(entry.get("formatted") or entry.get("message", "")))
        }
    elif "message" in data:
        clean["message"] = technical_value(data["message"])
    if "logger" in data:
        clean["logger"] = technical_value(data["logger"])
    if data.get("type") == "transaction":
        clean["transaction"] = technical_value(data.get("transaction", "operation"))
        clean["spans"] = [
            {
                key: (technical_value(value) if isinstance(value, str) else value)
                for key, value in span.items()
                if key
                in {
                    "span_id",
                    "trace_id",
                    "parent_span_id",
                    "op",
                    "description",
                    "start_timestamp",
                    "timestamp",
                    "status",
                }
            }
            for span in data.get("spans", [])
        ]
    return cast("Event", clean)
