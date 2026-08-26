from __future__ import annotations

import importlib
import tempfile
from pathlib import Path
from types import SimpleNamespace

class FakeNotificationManager:
    def __init__(self) -> None:
        self.configs = SimpleNamespace(
            notifications=SimpleNamespace(providers={})
        )
        self.providers: list[object] = []
        self.dispatched: list[object] = []

    def register_provider(self, provider: object) -> None:
        self.providers.append(provider)

    def dispatch(self, data: object, _config: object = None) -> None:
        self.dispatched.append(data)


class FakeCentral:
    def __init__(self) -> None:
        self.notification = FakeNotificationManager()
        self.runtime = SimpleNamespace(
            current_status=None,
            current_day=None,
            current_offset_time=None,
        )


def load_service_module():
    return importlib.import_module("src.core.automations.user_profiles")


def test_profile_defaults_and_storage(project_root: Path) -> None:
    module = load_service_module()
    with tempfile.TemporaryDirectory() as temp_dir:
        original_path = module.CONFIGS_PATH
        module.CONFIGS_PATH = Path(temp_dir)
        try:
            service = module.AutomationProfilesService(FakeCentral())
            service.start()
            profile_id = service.createProfile("教室自动化")
            profile = service._get_profile(profile_id)
            assert profile is not None
            assert profile.enabled is False
            assert profile.rules == []
            assert (Path(temp_dir) / "automation_profiles" / f"{profile_id}.json").is_file()

            rule_id = service.addRule(profile_id)
            assert rule_id
            service.updateRule(
                profile_id,
                rule_id,
                "CPU 过热时满速散热",
                "temperature_at_or_above",
                "",
                "cpu",
                85.0,
                0,
            )
            action_id = service.addAction(profile_id, rule_id)
            service.updateAction(
                profile_id,
                rule_id,
                action_id,
                "fan_full_speed",
                "风扇满速",
                "",
                "C:/Tools/fan-full-speed.cmd",
                '--profile "full speed"',
                8000,
            )
            profile = service._get_profile(profile_id)
            rule = profile.rules[0]
            assert rule.trigger.type == "temperature_at_or_above"
            assert rule.trigger.threshold_celsius == 85.0
            assert rule.actions[-1].type == "fan_full_speed"
            assert rule.actions[-1].arguments == ["--profile", "full speed"]
        finally:
            module.CONFIGS_PATH = original_path


def test_temperature_edge_trigger_and_safe_fan_command() -> None:
    module = load_service_module()
    with tempfile.TemporaryDirectory() as temp_dir:
        original_path = module.CONFIGS_PATH
        original_qprocess = module.QProcess
        module.CONFIGS_PATH = Path(temp_dir)
        starts: list[tuple[str, list[str]]] = []

        class FakeQProcess:
            @staticmethod
            def startDetached(program: str, arguments: list[str]) -> bool:
                starts.append((program, list(arguments)))
                return True

        module.QProcess = FakeQProcess
        try:
            central = FakeCentral()
            service = module.AutomationProfilesService(central)
            service.start()
            profile_id = service.createProfile("热保护")
            service.setProfileEnabled(profile_id, True)
            rule_id = service.addRule(profile_id)
            service.updateRule(
                profile_id,
                rule_id,
                "CPU 高温",
                "temperature_at_or_above",
                "",
                "cpu",
                80.0,
                0,
            )
            action_id = service.addAction(profile_id, rule_id)
            service.updateAction(
                profile_id,
                rule_id,
                action_id,
                "fan_full_speed",
                "风扇满速",
                "",
                "fan-control.exe",
                "--set full",
                8000,
            )

            service._on_temperature_probe_completed(profile_id, True, {"cpu": 75.0}, "")
            assert starts == []
            service._on_temperature_probe_completed(profile_id, True, {"cpu": 82.0}, "")
            assert starts == [("fan-control.exe", ["--set", "full"])]
            service._on_temperature_probe_completed(profile_id, True, {"cpu": 90.0}, "")
            assert len(starts) == 1, "same high-temperature interval must not repeat the action"
            service._on_temperature_probe_completed(profile_id, True, {"cpu": 70.0}, "")
            service._on_temperature_probe_completed(profile_id, True, {"cpu": 83.0}, "")
            assert len(starts) == 2, "temperature must fall below threshold before a new rise triggers again"
        finally:
            module.QProcess = original_qprocess
            module.CONFIGS_PATH = original_path


def test_process_triggers() -> None:
    module = load_service_module()
    with tempfile.TemporaryDirectory() as temp_dir:
        original_path = module.CONFIGS_PATH
        module.CONFIGS_PATH = Path(temp_dir)
        try:
            central = FakeCentral()
            service = module.AutomationProfilesService(central)
            service.start()
            profile_id = service.createProfile("进程规则")
            service.setProfileEnabled(profile_id, True)
            for trigger_type in ("process_started", "process_running", "process_exited"):
                rule_id = service.addRule(profile_id)
                service.updateRule(
                    profile_id,
                    rule_id,
                    trigger_type,
                    trigger_type,
                    "demo.exe",
                    "cpu",
                    80.0,
                    0,
                )

            snapshots = iter([
                {},
                {"demo.exe": {100}},
                {},
            ])
            service._snapshot_processes = lambda: next(snapshots)
            service._check_process_events()
            assert central.notification.dispatched == []
            service._check_process_events()
            assert len(central.notification.dispatched) == 2
            service._check_process_events()
            assert len(central.notification.dispatched) == 3
        finally:
            module.CONFIGS_PATH = original_path


def test_schedule_triggers() -> None:
    module = load_service_module()
    with tempfile.TemporaryDirectory() as temp_dir:
        original_path = module.CONFIGS_PATH
        module.CONFIGS_PATH = Path(temp_dir)
        try:
            central = FakeCentral()
            service = module.AutomationProfilesService(central)
            service.start()
            profile_id = service.createProfile("课程规则")
            service.setProfileEnabled(profile_id, True)
            for trigger_type in ("class_started", "break_started", "school_dismissal"):
                rule_id = service.addRule(profile_id)
                service.updateRule(
                    profile_id,
                    rule_id,
                    trigger_type,
                    trigger_type,
                    "",
                    "cpu",
                    80.0,
                    0,
                )

            service._has_future_classes_today = lambda: False
            service._is_noon_dismissal = lambda: False
            central.runtime.current_status = module.EntryType.CLASS
            service._check_schedule_events()
            assert len(central.notification.dispatched) == 1
            central.runtime.current_status = module.EntryType.BREAK
            service._check_schedule_events()
            assert len(central.notification.dispatched) == 3
        finally:
            module.CONFIGS_PATH = original_path


def test_process_and_ui_contract(project_root: Path) -> None:
    module = load_service_module()
    assert module.AutomationProfile().enabled is False
    assert {"app_started", "app_exiting", "process_started", "process_running", "process_exited"} <= module.TRIGGER_TYPES
    assert {"class_started", "break_started", "school_dismissal", "noon_dismissal"} <= module.TRIGGER_TYPES
    assert "temperature_at_or_above" in module.TRIGGER_TYPES
    assert "fan_full_speed" in module.ACTION_TYPES

    manager = (project_root / "src/core/automations/manager.py").read_text(encoding="utf-8")
    central = (project_root / "src/core/central.py").read_text(encoding="utf-8")
    settings = (project_root / "src/qml/ClassWidgets/Windows/Settings.qml").read_text(encoding="utf-8")
    page = (project_root / "src/qml/ClassWidgets/pages/settings/Automation.qml").read_text(encoding="utf-8")

    assert "AutomationProfilesService" in manager
    assert "def init_user_profiles" in manager
    assert "self.user_profiles.start()" in manager
    assert "def automationProfiles" in central
    assert "automation_manager.init_user_profiles()" in central
    assert "automation_manager.stop" in central
    assert 'title: qsTr("自动化")' in settings
    assert 'pages/settings/Automation.qml' in settings
    assert "temperature_at_or_above" in page
    assert "fan_full_speed" in page
    assert "createProfile" in page
    assert "addRule" in page
    assert "addAction" in page
    assert page.count("{") == page.count("}"), "unbalanced QML braces"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    test_profile_defaults_and_storage(project_root)
    test_temperature_edge_trigger_and_safe_fan_command()
    test_process_triggers()
    test_schedule_triggers()
    test_process_and_ui_contract(project_root)
    print("Automation profiles verification passed.")


if __name__ == "__main__":
    main()
