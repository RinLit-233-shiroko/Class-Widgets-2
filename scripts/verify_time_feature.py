from __future__ import annotations

from dataclasses import dataclass, field
from datetime import timedelta
import importlib.util
from pathlib import Path
import py_compile
from types import SimpleNamespace

from PySide6.QtCore import QCoreApplication


def load_time_service(project_root: Path):
    module_path = project_root / "src/core/time_service.py"
    spec = importlib.util.spec_from_file_location("time_service_under_test", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load time service module")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.TimeService


@dataclass
class FakeConfigs:
    time: object = field(
        default_factory=lambda: SimpleNamespace(
            use_precise_time=False,
            ntp_server="time.cloudflare.com",
        )
    )
    schedule: object = field(default_factory=lambda: SimpleNamespace(time_offset=0))

    def set(self, key: str, value: object) -> None:
        group, field_name = key.split(".", 1)
        setattr(getattr(self, group), field_name, value)


def test_python_syntax(project_root: Path) -> None:
    source_files = [
        project_root / "src/core/time_service.py",
        project_root / "src/core/config/model.py",
        project_root / "src/core/config/manager.py",
        project_root / "src/core/central.py",
        project_root / "src/core/schedule/runtime.py",
        project_root / "src/plugins/cw_widgets/widgets.py",
    ]
    for source_file in source_files:
        py_compile.compile(str(source_file), doraise=True)


def test_time_service_fallback_and_offset(project_root: Path) -> None:
    configs = FakeConfigs()
    TimeService = load_time_service(project_root)
    service = TimeService(configs)
    try:
        initial_now = service.now()
        assert abs((service.now() - initial_now).total_seconds()) < 1

        configs.schedule.time_offset = 17
        assert abs((service.display_now() - service.now() - timedelta(seconds=17)).total_seconds()) < 1

        service.setPreciseTimeEnabled(True)
        assert configs.time.use_precise_time is True

        configs.time.ntp_server = ""
        service.sync()
        assert service.preciseTimeAvailable is False
        assert "system time" in service.statusText.lower()
    finally:
        service.stop()


def test_qml_contains_required_controls(project_root: Path) -> None:
    qml_file = project_root / "src/qml/ClassWidgets/pages/settings/General/Index.qml"
    qml = qml_file.read_text(encoding="utf-8")
    required_fragments = (
        "AppCentral.timeService.currentTime",
        "AppCentral.timeService.currentDate",
        "Use Precise Time",
        "NTP Server",
        "Synchronize Time",
        "Custom NTP server",
        "Time Offset (Seconds)",
        "setPreciseTimeEnabled",
        "synchronizeTime",
    )
    for fragment in required_fragments:
        assert fragment in qml, f"Missing QML fragment: {fragment}"
    assert qml.count("{") == qml.count("}"), "Unbalanced QML braces"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    _app = QCoreApplication.instance() or QCoreApplication([])
    test_python_syntax(project_root)
    test_time_service_fallback_and_offset(project_root)
    test_qml_contains_required_controls(project_root)
    print("Time feature verification passed.")


if __name__ == "__main__":
    main()
