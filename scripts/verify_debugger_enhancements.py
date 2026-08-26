from __future__ import annotations

import py_compile
from pathlib import Path


def test_python_syntax(project_root: Path) -> None:
    py_compile.compile(str(project_root / "src/core/utils/backend.py"), doraise=True)


def test_backend_log_capabilities(project_root: Path) -> None:
    backend = (project_root / "src/core/utils/backend.py").read_text(encoding="utf-8")
    required_fragments = (
        "MAX_LOG_LINES = 200",
        "def logCount",
        "def maxLogLines",
        "def logBufferBytes",
        "def logBufferPeakBytes",
        "def logFirstTime",
        "def logLastTime",
        "def clearMemoryLogs",
        "json.dumps(log_entry, ensure_ascii=False).encode(\"utf-8\")",
    )
    for fragment in required_fragments:
        assert fragment in backend, f"Missing backend log capability: {fragment}"


def test_debugger_qml(project_root: Path) -> None:
    dashboard = (project_root / "src/qml/Debugger/contents/Dashboard.qml").read_text(
        encoding="utf-8"
    )
    overview = (project_root / "src/qml/Debugger/contents/Overview.qml").read_text(
        encoding="utf-8"
    )

    for fragment in (
        "UtilsBackend.logCount",
        "UtilsBackend.maxLogLines",
        "UtilsBackend.logBufferBytes",
        "UtilsBackend.logBufferPeakBytes",
        "UtilsBackend.logFirstTime",
        "UtilsBackend.logLastTime",
        "UtilsBackend.clearMemoryLogs()",
        "暂停自动滚动",
        "复制全部",
        "清空内存日志",
    ):
        assert fragment in dashboard, f"Missing dashboard feature: {fragment}"

    for fragment in (
        "notificationTestStatus",
        "测试通知已发送",
        "调试通知提供者不可用",
    ):
        assert fragment in overview, f"Missing notification feedback: {fragment}"

    assert dashboard.count("{") == dashboard.count("}"), "Unbalanced Dashboard.qml braces"
    assert overview.count("{") == overview.count("}"), "Unbalanced Overview.qml braces"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    test_python_syntax(project_root)
    test_backend_log_capabilities(project_root)
    test_debugger_qml(project_root)
    print("Debugger enhancement verification passed.")


if __name__ == "__main__":
    main()
