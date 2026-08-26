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
        self.central_control = SimpleNamespace(
            schedule_manifest_url="",
            auto_fetch_enabled=False,
            auto_fetch_interval_minutes=15,
            executed_command_ids=[],
        )

    def set(self, key: str, value: object) -> None:
        group, field_name = key.split(".", 1)
        setattr(getattr(self, group), field_name, value)


class FakeNotificationManager:
    def __init__(self) -> None:
        self.configs = SimpleNamespace(
            notifications=SimpleNamespace(providers={})
        )
        self.providers = []
        self.dispatched = []

    def register_provider(self, provider: object) -> None:
        self.providers.append(provider)

    def dispatch(self, data: object, config: object) -> None:
        self.dispatched.append(data)


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
    payload = CentralControlScheduleService.fetch_manifest_payload(PAGES_MANIFEST_URL)
    assert payload["schedule_id"] == "class-schedule"
    assert payload["schedule"]["meta"]["version"] == 1
    assert len(payload["commands"]) == 1
    assert payload["commands"][0]["type"] == "announcement"
    assert payload["commands"][0]["message"] == "原神牛逼"

    with tempfile.TemporaryDirectory() as temp_dir:
        configs = FakeConfigs()
        manager = FakeScheduleManager(Path(temp_dir))
        notification_manager = FakeNotificationManager()
        service = CentralControlScheduleService(configs, manager, notification_manager)
        schedule_name, policy_version = service._cache_and_apply(payload)
        stored_schedule = manager.schedules_dir / f"{schedule_name}.json"
        assert schedule_name == "central_class-schedule"
        assert policy_version == payload["policy_version"]
        assert manager.loaded_name == schedule_name
        assert stored_schedule.exists()

        announcement_payload = {
            "commands": [
                {
                    "id": "announcement-test-001",
                    "type": "announcement",
                    "title": "集控公告",
                    "message": "原神牛逼",
                    "duration": 8000,
                    "expiresAt": None,
                }
            ]
        }
        assert service._apply_announcement_commands(announcement_payload) == 1
        assert len(notification_manager.dispatched) == 1
        assert notification_manager.dispatched[0].message == "原神牛逼"
        assert service._apply_announcement_commands(announcement_payload) == 0
        assert configs.central_control.executed_command_ids == ["announcement-test-001"]


def test_configuration_and_qml(project_root: Path) -> None:
    config = RootConfig().central_control
    assert config.schedule_manifest_url == ""
    assert config.auto_fetch_enabled is False
    assert config.auto_fetch_interval_minutes == 15

    qml = (project_root / "src/qml/ClassWidgets/pages/settings/CentralControl.qml").read_text(
        encoding="utf-8"
    )
    for fragment in (
        "集控地址",
        "setManifestUrl",
        "setAutoFetchEnabled",
        "setAutoFetchIntervalMinutes",
        "fetchAndApplySchedule",
        "自动拉取集控内容",
        "检查并应用集控内容",
    ):
        assert fragment in qml, f"Missing QML fragment: {fragment}"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    _application = QCoreApplication.instance() or QCoreApplication([])
    test_python_syntax(project_root)
    test_remote_manifest_and_cache()
    test_configuration_and_qml(project_root)
    print("Central-control schedule and announcement verification passed.")


if __name__ == "__main__":
    main()
