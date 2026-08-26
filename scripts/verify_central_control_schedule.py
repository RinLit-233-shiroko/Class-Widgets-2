from __future__ import annotations

import py_compile
import tempfile
from pathlib import Path
from types import SimpleNamespace

from PySide6.QtCore import QCoreApplication

from src.core.central_control import CentralControlScheduleService
from src.core.config.manager import RootConfig


PAGES_MANIFEST_URL = "https://mmckb.github.io/Test/manifest.json"


class FakeConfigs:
    def __init__(self) -> None:
        self.central_control = SimpleNamespace(schedule_manifest_url="")

    def set(self, key: str, value: object) -> None:
        group, field_name = key.split(".", 1)
        setattr(getattr(self, group), field_name, value)


class FakeScheduleManager:
    def __init__(self, schedules_dir: Path) -> None:
        self.schedules_dir = schedules_dir
        self.loaded_name = ""

    def load(self, name: str, force: bool = False) -> bool:
        self.loaded_name = name
        return force and (self.schedules_dir / f"{name}.json").exists()


def test_python_syntax(project_root: Path) -> None:
    for source_file in (
        project_root / "src/core/central_control.py",
        project_root / "src/core/config/model.py",
        project_root / "src/core/config/manager.py",
        project_root / "src/core/central.py",
    ):
        py_compile.compile(str(source_file), doraise=True)


def test_remote_manifest_and_cache() -> None:
    payload = CentralControlScheduleService.fetch_schedule_payload(PAGES_MANIFEST_URL)
    assert payload["schedule_id"] == "class-schedule"
    assert payload["policy_version"] == "2026.08.26-01"
    assert payload["schedule"]["meta"]["version"] == 1

    with tempfile.TemporaryDirectory() as temp_dir:
        manager = FakeScheduleManager(Path(temp_dir))
        service = CentralControlScheduleService(FakeConfigs(), manager)
        schedule_name, policy_version = service._cache_and_apply(payload)
        stored_schedule = manager.schedules_dir / f"{schedule_name}.json"
        assert schedule_name == "central_class-schedule"
        assert policy_version == "2026.08.26-01"
        assert manager.loaded_name == schedule_name
        assert stored_schedule.exists()


def test_configuration_and_qml(project_root: Path) -> None:
    assert RootConfig().central_control.schedule_manifest_url == PAGES_MANIFEST_URL
    qml = (project_root / "src/qml/ClassWidgets/pages/settings/CentralControl.qml").read_text(
        encoding="utf-8"
    )
    for fragment in (
        "课程表下发地址",
        "setManifestUrl",
        "fetchAndApplySchedule",
        "检查并应用课程表",
    ):
        assert fragment in qml, f"Missing QML fragment: {fragment}"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    _application = QCoreApplication.instance() or QCoreApplication([])
    test_python_syntax(project_root)
    test_remote_manifest_and_cache()
    test_configuration_and_qml(project_root)
    print("Central-control schedule verification passed.")


if __name__ == "__main__":
    main()
