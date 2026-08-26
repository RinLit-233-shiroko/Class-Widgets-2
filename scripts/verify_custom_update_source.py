from __future__ import annotations

from pathlib import Path
import py_compile

from src.core.config.manager import RootConfig
from src.core.updater.workers import CheckUpdateWorker


GITHUB_RELEASES_URL = "https://github.com/MMCKB/Class-Widgets-2/releases"


def test_python_syntax(project_root: Path) -> None:
    for source_file in (
        project_root / "src/core/config/model.py",
        project_root / "src/core/updater/workers.py",
        project_root / "src/core/updater/bridge.py",
    ):
        py_compile.compile(str(source_file), doraise=True)


def test_github_release_source() -> None:
    worker = CheckUpdateWorker("alpha", "0.0.0", GITHUB_RELEASES_URL)
    assert worker._github_releases_api_url(GITHUB_RELEASES_URL) == (
        "https://api.github.com/repos/MMCKB/Class-Widgets-2/releases?per_page=100"
    )

    try:
        worker._github_releases_api_url("https://example.com/releases")
    except ValueError:
        pass
    else:
        raise AssertionError("Non-GitHub source should be rejected")

    version, asset_url = worker._check_github_releases()
    assert version == "2.0.0.Dev2608261"
    assert asset_url.endswith("ClassWidgets-2-Windows.zip")


def test_configuration_and_qml(project_root: Path) -> None:
    assert RootConfig().network.github_releases_url == ""

    qml = (project_root / "src/qml/ClassWidgets/pages/settings/Update.qml").read_text(
        encoding="utf-8"
    )
    for required_fragment in (
        "GitHub Releases 更新源",
        "network.github_releases_url",
        "githubReleasesField",
        "不再使用默认更新服务器",
    ):
        assert required_fragment in qml, f"Missing QML fragment: {required_fragment}"
    assert qml.count("{") == qml.count("}"), "Unbalanced QML braces"


def main() -> None:
    project_root = Path(__file__).resolve().parents[1]
    test_python_syntax(project_root)
    test_github_release_source()
    test_configuration_and_qml(project_root)
    print("Custom GitHub Releases update source verification passed.")


if __name__ == "__main__":
    main()
