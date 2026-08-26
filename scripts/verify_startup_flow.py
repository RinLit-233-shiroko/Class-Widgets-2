from __future__ import annotations

import importlib
from pathlib import Path
import py_compile
from types import SimpleNamespace

def load_module(_project_root: Path, module_name: str):
    return importlib.import_module(module_name)


class FakeConfigs:
    def __init__(self, *, skip_once: bool = False) -> None:
        self.app = SimpleNamespace(startup_animation_skip_once=skip_once)
        self.saved = False

    def set(self, key: str, value: object) -> None:
        group, field_name = key.split(".", 1)
        setattr(getattr(self, group), field_name, value)

    def save(self, *, silent: bool = False) -> None:
        self.saved = silent


class FakeStartupAnimation:
    def __init__(self, started: bool) -> None:
        self.started = started
        self.start_calls = 0

    def start(self) -> bool:
        self.start_calls += 1
        return self.started


class SignalRecorder:
    def __init__(self) -> None:
        self.count = 0

    def emit(self) -> None:
        self.count += 1


class FakeWidgetsWindow:
    def __init__(self) -> None:
        self.run_calls = 0

    def run(self) -> None:
        self.run_calls += 1


def test_python_syntax(project_root: Path) -> None:
    source_files = (
        project_root / "src/core/central.py",
        project_root / "src/core/startup_animation.py",
        project_root / "src/core/config/model.py",
    )
    for source_file in source_files:
        py_compile.compile(str(source_file), doraise=True)


def test_config_defaults(project_root: Path) -> None:
    model = load_module(project_root, "src.core.config.model")
    config = model.AppConfig()
    assert config.startup_animation_skip_once is False
    assert config.startup_animation_force_video_completion is False
    assert config.show_update_summary is True


def test_animation_wait_and_skip_once(project_root: Path) -> None:
    central_module = load_module(project_root, "src.core.central")
    app_central = central_module.AppCentral

    skip_configs = FakeConfigs(skip_once=True)
    skip_animation = FakeStartupAnimation(started=True)
    skip_context = SimpleNamespace(configs=skip_configs, startup_animation=skip_animation)
    assert app_central._start_startup_animation_if_needed(skip_context) is False
    assert skip_configs.app.startup_animation_skip_once is False
    assert skip_configs.saved is True
    assert skip_animation.start_calls == 0

    normal_configs = FakeConfigs(skip_once=False)
    normal_animation = FakeStartupAnimation(started=True)
    normal_context = SimpleNamespace(configs=normal_configs, startup_animation=normal_animation)
    assert app_central._start_startup_animation_if_needed(normal_context) is True
    assert normal_animation.start_calls == 1


def test_preview_session_does_not_finish_normal_startup(project_root: Path) -> None:
    startup_module = load_module(project_root, "src.core.startup_animation")
    controller = startup_module.StartupAnimation

    preview_signal = SignalRecorder()
    preview_context = SimpleNamespace(
        engine=None,
        _preview_active=False,
        changed=preview_signal,
        _open_window=lambda: True,
    )
    assert controller.preview(preview_context) is True
    assert preview_context._preview_active is True
    assert preview_signal.count == 1

    preview_finished = SignalRecorder()
    preview_close_context = SimpleNamespace(
        engine=object(),
        root_window=None,
        _preview_active=True,
        finished=preview_finished,
        release=lambda: None,
    )
    controller.finish(preview_close_context)
    assert preview_finished.count == 0

    normal_finished = SignalRecorder()
    normal_close_context = SimpleNamespace(
        engine=object(),
        root_window=None,
        _preview_active=False,
        finished=normal_finished,
        release=lambda: None,
    )
    controller.finish(normal_close_context)
    assert normal_finished.count == 1


def test_widget_start_is_gated_by_animation(project_root: Path) -> None:
    central_module = load_module(project_root, "src.core.central")
    app_central = central_module.AppCentral
    widgets = FakeWidgetsWindow()
    context = SimpleNamespace(
        _widgets_start_ready=True,
        _startup_animation_waiting=True,
        _widgets_started=False,
        widgets_window=widgets,
    )
    app_central._start_widgets_if_ready(context)
    assert widgets.run_calls == 0

    context._startup_animation_waiting = False
    app_central._start_widgets_if_ready(context)
    app_central._start_widgets_if_ready(context)
    assert widgets.run_calls == 1
    assert context._widgets_started is True


def test_qml_and_lifecycle_contract(project_root: Path) -> None:
    startup_controller = (project_root / "src/core/startup_animation.py").read_text(encoding="utf-8")
    central = (project_root / "src/core/central.py").read_text(encoding="utf-8")
    tutorial = (project_root / "src/qml/ClassWidgets/Windows/Tutorial.qml").read_text(encoding="utf-8")
    about = (project_root / "src/qml/ClassWidgets/pages/settings/About.qml").read_text(encoding="utf-8")
    update = (project_root / "src/qml/ClassWidgets/pages/settings/Update.qml").read_text(encoding="utf-8")
    general = (project_root / "src/qml/ClassWidgets/pages/settings/General/Index.qml").read_text(encoding="utf-8")
    startup_qml = (project_root / "src/qml/StartupAnimation.qml").read_text(encoding="utf-8")

    assert "finished = Signal()" in startup_controller
    assert "def start(self) -> bool:" in startup_controller
    assert "self.finished.emit()" in startup_controller
    assert "def preview(self) -> bool:" in startup_controller
    assert "StartupAnimationPreview" in startup_controller
    assert "if not preview_was_active:" in startup_controller
    assert "self.startup_animation.finished.connect(self._on_startup_animation_finished)" in central
    assert "self._start_widgets_if_ready()" in central
    assert "self._update_summary_pending = getattr(" in central
    assert "self.window_manager.open_whatsnew()" in central

    assert 'Configs.set("app.startup_animation_skip_once", true)' in tutorial
    assert "AppCentral.restart(\"--update-done\")" not in tutorial
    assert 'Configs.set("app.startup_animation_skip_once", false)' in about
    assert 'Configs.data.app.show_update_summary' in update
    assert 'Configs.set("app.show_update_summary", checked)' in update
    assert 'title: qsTr("显示更新摘要")' in update

    assert 'Configs.set("app.startup_animation_force_video_completion", checked)' in general
    assert 'AppCentral.startupAnimation.preview()' in general
    assert 'title: qsTr("预览启动动画")' in general
    assert 'title: qsTr("强制播放完视频")' in general
    assert 'title: qsTr("启动动画")' in general

    assert "import Qt5Compat.GraphicalEffects" in startup_qml
    assert "layer.effect: OpacityMask" in startup_qml
    assert "radius: mediaSurface.radius" in startup_qml
    assert "property bool forceCompleteVideo" in startup_qml
    assert "running: !root.forceCompleteVideo" in startup_qml
    assert "property bool previewMode: StartupAnimationPreview" in startup_qml


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    test_python_syntax(project_root)
    test_config_defaults(project_root)
    test_animation_wait_and_skip_once(project_root)
    test_preview_session_does_not_finish_normal_startup(project_root)
    test_widget_start_is_gated_by_animation(project_root)
    test_qml_and_lifecycle_contract(project_root)
    print("Startup flow verification passed.")


if __name__ == "__main__":
    main()
