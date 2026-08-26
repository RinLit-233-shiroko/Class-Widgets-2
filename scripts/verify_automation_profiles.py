from __future__ import annotations

import importlib
import json
import tempfile
from pathlib import Path
from types import SimpleNamespace


class FakeNotificationManager:
    def __init__(self) -> None:
        self.configs = SimpleNamespace(notifications=SimpleNamespace(providers={}))
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


def test_profile_defaults_and_program_action() -> None:
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
            service.updateRule(
                profile_id,
                rule_id,
                "启动演示程序",
                "process_started",
                "demo.exe",
                0,
            )
            action_id = service.addAction(profile_id, rule_id)
            service.updateAction(
                profile_id,
                rule_id,
                action_id,
                "run_program",
                "启动程序",
                "",
                "C:/Tools/demo.exe",
                "--class 1",
                8000,
            )
            profile = service._get_profile(profile_id)
            rule = profile.rules[0]
            assert rule.trigger.type == "process_started"
            assert rule.trigger.process_name == "demo.exe"
            assert rule.actions[-1].type == "run_program"
            assert rule.actions[-1].arguments == ["--class", "1"]
        finally:
            module.CONFIGS_PATH = original_path


def test_legacy_temperature_configuration_is_cleaned() -> None:
    module = load_service_module()
    with tempfile.TemporaryDirectory() as temp_dir:
        original_path = module.CONFIGS_PATH
        module.CONFIGS_PATH = Path(temp_dir)
        try:
            profiles_dir = Path(temp_dir) / "automation_profiles"
            profiles_dir.mkdir(parents=True)
            legacy_path = profiles_dir / "legacy.json"
            legacy_path.write_text(
                json.dumps(
                    {
                        "id": "legacy-profile",
                        "name": "旧配置",
                        "enabled": True,
                        "temperature_command": "read-temperature.exe",
                        "temperature_arguments": ["--json"],
                        "temperature_poll_seconds": 5,
                        "rules": [
                            {
                                "id": "temperature-rule",
                                "name": "旧温度规则",
                                "trigger": {"type": "temperature_at_or_above"},
                                "actions": [{"type": "fan_full_speed", "program": "fan.exe"}],
                            },
                            {
                                "id": "process-rule",
                                "name": "保留进程规则",
                                "trigger": {"type": "process_started", "process_name": "demo.exe"},
                                "actions": [
                                    {"type": "fan_full_speed", "program": "fan.exe"},
                                    {"type": "notification", "title": "已启动"},
                                ],
                            },
                        ],
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            service = module.AutomationProfilesService(FakeCentral())
            service.start()
            profile = service._get_profile("legacy-profile")
            assert profile is not None
            assert len(profile.rules) == 1
            assert profile.rules[0].trigger.type == "process_started"
            assert [action.type for action in profile.rules[0].actions] == ["notification"]

            persisted = json.loads(legacy_path.read_text(encoding="utf-8"))
            assert "temperature_command" not in persisted
            assert "temperature_arguments" not in persisted
            assert "temperature_poll_seconds" not in persisted
            assert all(
                rule["trigger"]["type"] != "temperature_at_or_above"
                for rule in persisted["rules"]
            )
            assert all(
                action["type"] != "fan_full_speed"
                for rule in persisted["rules"]
                for action in rule["actions"]
            )
        finally:
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
                    0,
                )

            snapshots = iter([{}, {"demo.exe": {100}}, {}])
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


def test_service_and_ui_contract(project_root: Path) -> None:
    module = load_service_module()
    assert module.AutomationProfile().enabled is False
    assert {"app_started", "app_exiting", "process_started", "process_running", "process_exited"} <= module.TRIGGER_TYPES
    assert {"class_started", "break_started", "school_dismissal", "noon_dismissal"} <= module.TRIGGER_TYPES
    assert "temperature_at_or_above" not in module.TRIGGER_TYPES
    assert "fan_full_speed" not in module.ACTION_TYPES

    manager = (project_root / "src/core/automations/manager.py").read_text(encoding="utf-8")
    central = (project_root / "src/core/central.py").read_text(encoding="utf-8")
    settings = (project_root / "src/qml/ClassWidgets/Windows/Settings.qml").read_text(encoding="utf-8")
    page = (project_root / "src/qml/ClassWidgets/pages/settings/Automation.qml").read_text(encoding="utf-8")
    automation_service = (project_root / "src/core/automations/user_profiles.py").read_text(encoding="utf-8")

    assert "AutomationProfilesService" in manager
    assert "def init_user_profiles" in manager
    assert "self.user_profiles.start()" in manager
    assert "def automationProfiles" in central
    assert "automation_manager.init_user_profiles()" in central
    assert "automation_manager.stop" in central
    assert 'title: qsTr("自动化")' in settings
    assert 'pages/settings/Automation.qml' in settings
    assert "createProfile" in page
    assert "addRule" in page
    assert "addAction" in page
    assert "temperature_at_or_above" not in page
    assert "fan_full_speed" not in page
    assert "温度传感器命令" not in page
    assert page.count("{") == page.count("}"), "unbalanced QML braces"
    assert "property string currentValue" not in page
    assert "property string automationValue" in page

    assert 'ctypes.WinDLL("psapi", use_last_error=True)' in automation_service
    assert "EnumProcesses" in automation_service
    assert "QueryFullProcessImageNameW" in automation_service
    assert '["tasklist"' not in automation_service
    assert automation_service.count('"temperature_at_or_above"') == 1
    assert automation_service.count('"fan_full_speed"') == 1
    assert "_schedule_temperature_probes" not in automation_service
    assert "_on_temperature_probe_completed" not in automation_service


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    test_profile_defaults_and_program_action()
    test_legacy_temperature_configuration_is_cleaned()
    test_process_triggers()
    test_schedule_triggers()
    test_service_and_ui_contract(project_root)
    print("Automation profiles verification passed.")


if __name__ == "__main__":
    main()
