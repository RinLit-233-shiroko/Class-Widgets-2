from __future__ import annotations

import importlib
import json
import tempfile
from pathlib import Path
from types import SimpleNamespace


class FakeNotificationManager:
    def __init__(self) -> None:
        self.configs = SimpleNamespace(notifications=SimpleNamespace(providers={}))

    def register_provider(self, _provider: object) -> None:
        pass

    def dispatch(self, _data: object, _config: object = None) -> None:
        pass


class FakeCentral:
    def __init__(self) -> None:
        self.notification = FakeNotificationManager()
        self.runtime = SimpleNamespace(current_status=None, current_day=None, current_offset_time=None)


def test_plugin_project_registration_and_persistence() -> None:
    service_module = importlib.import_module("src.core.automations.user_profiles")
    with tempfile.TemporaryDirectory() as temp_dir:
        original_configs_path = service_module.CONFIGS_PATH
        service_module.CONFIGS_PATH = Path(temp_dir)
        try:
            callbacks: list[bool] = []
            opened: list[bool] = []
            service = service_module.AutomationProfilesService(FakeCentral())
            project_id = service.register_plugin_project(
                plugin_id="org.example.exam",
                project_id="exam-mode",
                title="考试模式",
                description="考试时由插件接管提醒。",
                on_enabled_changed=callbacks.append,
                on_open_settings=lambda: opened.append(True),
            )
            assert project_id == "org.example.exam.exam-mode"
            assert callbacks == [False]
            assert service.pluginProjects == [
                {
                    "id": project_id,
                    "pluginId": "org.example.exam",
                    "title": "考试模式",
                    "description": "考试时由插件接管提醒。",
                    "icon": "ic_fluent_plug_connected_20_regular",
                    "enabled": False,
                    "hasSettings": True,
                }
            ]
            assert service.setPluginProjectEnabled(project_id, True) is True
            assert callbacks == [False, True]
            assert service.openPluginProjectSettings(project_id) is True
            assert opened == [True]

            state_path = Path(temp_dir) / "automation_plugin_projects.json"
            persisted = json.loads(state_path.read_text(encoding="utf-8"))
            assert persisted["schemaVersion"] == 1
            assert persisted["projects"] == {project_id: True}

            restored_callbacks: list[bool] = []
            restored = service_module.AutomationProfilesService(FakeCentral())
            restored_id = restored.register_plugin_project(
                plugin_id="org.example.exam",
                project_id="exam-mode",
                title="考试模式",
                on_enabled_changed=restored_callbacks.append,
            )
            assert restored_id == project_id
            assert restored.pluginProjects[0]["enabled"] is True
            assert restored_callbacks == [True]

            restored.unregister_plugin_projects("org.example.exam")
            assert restored.pluginProjects == []
            persisted_after_unload = json.loads(state_path.read_text(encoding="utf-8"))
            assert persisted_after_unload["projects"] == {project_id: True}
        finally:
            service_module.CONFIGS_PATH = original_configs_path


def test_plugin_api_namespaces_and_validates_projects() -> None:
    service_module = importlib.import_module("src.core.automations.user_profiles")
    components = importlib.import_module("src.core.plugin.components")
    with tempfile.TemporaryDirectory() as temp_dir:
        original_configs_path = service_module.CONFIGS_PATH
        service_module.CONFIGS_PATH = Path(temp_dir)
        try:
            service = service_module.AutomationProfilesService(FakeCentral())
            manager = SimpleNamespace(init_user_profiles=lambda: service)
            plugin = SimpleNamespace(meta={"id": "org.example.plugin"})
            plugin_api = SimpleNamespace(
                _app=SimpleNamespace(automation_manager=manager),
                current_plugin=plugin,
            )
            api = components.AutomationAPI(plugin_api)
            project_id = api.register_project("focus", "专注模式")
            assert project_id == "org.example.plugin.focus"

            try:
                api.register_project("../../unsafe", "不应注册")
            except ValueError:
                pass
            else:
                raise AssertionError("unsafe plugin project ID must be rejected")

            api.unregister_plugin_projects("org.example.plugin")
            assert service.pluginProjects == []
        finally:
            service_module.CONFIGS_PATH = original_configs_path


def test_source_and_qml_contract(project_root: Path) -> None:
    components = (project_root / "src/core/plugin/components.py").read_text(encoding="utf-8")
    manager = (project_root / "src/core/plugin/manager.py").read_text(encoding="utf-8")
    service = (project_root / "src/core/automations/user_profiles.py").read_text(encoding="utf-8")
    page = (project_root / "src/qml/ClassWidgets/pages/settings/Automation.qml").read_text(encoding="utf-8")
    documentation = (project_root / "README_PLUGIN_AUTOMATION_PROJECTS.md").read_text(encoding="utf-8")

    assert "def register_project(" in components
    assert "def unregister_plugin_projects(" in components
    assert "register_plugin_project(" in components
    assert "unregister_plugin_projects(pid)" in manager
    assert "unregister_plugin_projects(plugin_id)" in manager
    assert "class PluginAutomationProject" in service
    assert "def register_plugin_project(" in service
    assert "def setPluginProjectEnabled(" in service
    assert "def openPluginProjectSettings(" in service
    assert "automation_plugin_projects.json" in service
    assert "插件自动化项目" in page
    assert "pluginProjects" in page
    assert "setPluginProjectEnabled" in page
    assert "openPluginProjectSettings" in page
    assert page.count("{") == page.count("}"), "unbalanced QML braces"
    assert "插件自动化项目开发指南" in documentation
    assert "register_project" in documentation
    assert "on_enabled_changed" in documentation
    assert "on_open_settings" in documentation
    assert "安全边界" in documentation


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    test_plugin_project_registration_and_persistence()
    test_plugin_api_namespaces_and_validates_projects()
    test_source_and_qml_contract(project_root)
    print("Plugin automation projects verification passed.")


if __name__ == "__main__":
    main()
