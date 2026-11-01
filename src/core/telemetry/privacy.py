"""仅保留远程定位问题所需的技术信息；本地报告仍保留原始详情。"""

import re

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


def technical_value(value) -> str:
    text = str(value)
    return text if re.fullmatch(r"[\w.+:-]{1,128}", text, flags=re.ASCII) else "unknown"


def technical_tags(context: dict) -> dict:
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


def sanitize_event(event: dict, _hint: dict) -> dict:
    # 使用白名单重建 payload，避免 SDK 升级增加未经审查的上下文。
    clean = {
        key: event[key]
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
        )
        if key in event
    }
    clean["tags"] = technical_tags(event.get("tags", {}))
    contexts = event.get("contexts", {})
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
    for exception in event.get("exception", {}).get("values", []):
        item = {"type": technical_value(exception.get("type", "Exception"))}
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
    elif "message" in event:
        clean["message"] = technical_value(event["message"])
    if event.get("type") == "transaction":
        clean["transaction"] = technical_value(event.get("transaction", "operation"))
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
            for span in event.get("spans", [])
        ]
    return clean
