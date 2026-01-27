#!/usr/bin/env python3
"""
scripts/test_qml_import.py

Quick diagnostic script to verify QML import path resolution and whether
the `ClassWidgets.Components` QML module can be found by QQmlEngine.

This is intended to reproduce and help debug errors like:
    QQmlApplicationEngine failed to load component
    ... module "ClassWidgets.Components" is not installed

Usage:
    ./scripts/test_qml_import.py
"""

from __future__ import annotations

import os
import sys
import textwrap
from pathlib import Path

# Try to avoid requiring a visible GUI (use offscreen platform)
os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")


def safe_import_pyside():
    try:
        from PySide6.QtCore import QCoreApplication, QUrl
        from PySide6.QtQml import QQmlComponent, QQmlEngine
    except Exception as exc:  # pragma: no cover - runtime dependency
        print("ERROR: PySide6 is required to run this script.")
        print("Install it in your virtualenv: pip install PySide6")
        print("Import error details:", exc)
        sys.exit(2)
    return QUrl, QCoreApplication, QQmlEngine, QQmlComponent


QUrl, QCoreApplication, QQmlEngine, QQmlComponent = safe_import_pyside()


def read_head(path: Path, n: int = 40):
    try:
        return "\n".join(path.read_text(encoding="utf-8").splitlines()[:n])
    except Exception as exc:
        return f"<unable to read {path}: {exc}>"


def format_error_list(errs):
    out = []
    for e in errs:
        try:
            out.append(str(e))
        except Exception:
            out.append(repr(e))
    return "\n".join(out)


def check_component_status(component, label: str = "component"):
    status = component.status()
    ok = status == QQmlComponent.Ready
    print(f"[{label}] status: {status} ({'Ready' if ok else 'Not Ready'})")
    errs = component.errors()
    if errs:
        print(f"[{label}] errors ({len(errs)}):")
        print(format_error_list(errs))
    else:
        print(f"[{label}] no errors reported")
    return ok


def test_module_import(engine, module_line: str, label: str = None):
    label = label or f"import-{module_line}"
    qml = textwrap.dedent(
        f"""\
        import QtQml 2.0
        import {module_line}
        QtObject {{}}
        """
    )
    comp = QQmlComponent(engine)
    comp.setData(qml.encode("utf-8"), QUrl())
    ok = check_component_status(comp, label)
    return ok


def test_load_qml_file(engine, qml_path: Path, label: str = None):
    label = label or f"file-{qml_path.name}"
    if not qml_path.exists():
        print(f"[{label}] file not found: {qml_path}")
        return False
    url = QUrl.fromLocalFile(str(qml_path.resolve()))
    comp = QQmlComponent(engine, url)
    ok = check_component_status(comp, label)
    return ok


def main():
    ROOT = Path(__file__).resolve().parents[1]
    SRC = ROOT / "src"
    QML_PATH = SRC / "qml"
    CW_PATH = QML_PATH / "ClassWidgets"

    print("=" * 72)
    print("QML import diagnostic")
    print(f"Project root: {ROOT}")
    print(f"SRC: {SRC}")
    print(f"QML_PATH: {QML_PATH} (exists={QML_PATH.exists()})")
    print(f"CW_PATH: {CW_PATH} (exists={CW_PATH.exists()})")
    print()

    # Check qmldir files and components folder name variants
    top_qmldir = CW_PATH / "qmldir"
    comp_lower = CW_PATH / "Components"
    comp_upper = CW_PATH / "Components"
    comp_lower_qmldir = comp_lower / "qmldir"
    comp_upper_qmldir = comp_upper / "qmldir"

    print("-- qmldir / components check --")
    print(f"Top-level qmldir: {top_qmldir} (exists={top_qmldir.exists()})")
    if top_qmldir.exists():
        print(read_head(top_qmldir, 8))
    print()
    print(f"components (lowercase) dir: {comp_lower} (exists={comp_lower.exists()})")
    if comp_lower_qmldir.exists():
        print(f"  {comp_lower_qmldir} content:\n{read_head(comp_lower_qmldir, 20)}")
    print()
    print(f"Components (capitalized) dir: {comp_upper} (exists={comp_upper.exists()})")
    if comp_upper_qmldir.exists():
        print(f"  {comp_upper_qmldir} content:\n{read_head(comp_upper_qmldir, 20)}")
    print()

    # Attempt to start a QCoreApplication so QQmlEngine can do its job
    if QCoreApplication.instance() is None:
        app = QCoreApplication(sys.argv[:1])  # minimal non-GUI app
    else:
        app = QCoreApplication.instance()

    engine = QQmlEngine()

    print("-- initial engine.importPathList() --")
    try:
        paths = engine.importPathList()
    except Exception:
        # older/newer PySide may expose importPathList differently; try attribute
        paths = getattr(engine, "importPathList", lambda: [])()
    print(paths)
    print()

    # Test 1: try import without adding any project paths
    print("Test A: try importing ClassWidgets.Components WITHOUT adding project paths")
    a_ok = test_module_import(
        engine, "ClassWidgets.Components 1.0", label="A:raw-import"
    )
    print()

    # Add standard project import paths (as the app should)
    print("Adding candidate import paths (as strings):")
    candidates = [
        QML_PATH,
        CW_PATH,
        CW_PATH / "Components",
        CW_PATH / "Components",
    ]
    for p in candidates:
        if p.exists():
            engine.addImportPath(str(p))
            print(f"  added: {p}")
        else:
            print(f"  (skipped, not exists) {p}")
    # Try to add RinUI package's QML import path (if RinUI is installed in the environment)
    try:
        import importlib

        rinui_config = importlib.import_module("RinUI.core.config")
        rinui_qml = getattr(rinui_config, "RINUI_PATH", None)
        if rinui_qml:
            engine.addImportPath(str(rinui_qml))
            print(f"  added RinUI module import path: {rinui_qml}")
    except Exception as exc:
        print(f"  (skipped, RinUI not importable): {exc}")
    print()

    print("-- engine.importPathList() AFTER adding paths --")
    print(engine.importPathList())
    print()

    # Test 2: try importing again
    print("Test B: try importing ClassWidgets.Components AFTER adding project paths")
    b_ok = test_module_import(
        engine, "ClassWidgets.Components 1.0", label="B:after-add"
    )
    print()

    # Test 3: try loading Settings.qml directly (reproduce original error)
    # Be robust to common case variants of the 'Windows' directory that differ across filesystems.
    print("Test C: try loading Settings.qml at case-variant locations")
    settings_candidates = [
        CW_PATH / "Windows" / "Settings.qml",
        # CW_PATH / "Windows" / "Settings.qml",
    ]
    c_ok = False
    for p in settings_candidates:
        print(f"Checking {p} (exists={p.exists()})")
        c_ok = test_load_qml_file(engine, p, label=f"C:Settings ({p.parent.name})")
        if c_ok:
            break
    print()

    # Summary and suggestions
    print("=" * 72)
    success = a_ok or b_ok or c_ok
    if success:
        print(
            "RESULT: At least one test succeeded. The 'ClassWidgets.Components' module appears to be reachable."
        )
        # If initial attempt failed but later succeeded, it's likely an import path ordering issue
        if not a_ok and (b_ok or c_ok):
            print(
                "NOTE: The tests suggest adding the project's QML paths (QML_PATH/CW_PATH) to the engine\n"
                "      before attempting to load windows that import ClassWidgets.Components.\n"
                "      In Python code, prefer calling `engine.addImportPath(str(QML_PATH))`\n"
                "      and/or `engine.addImportPath(str(CW_PATH))` early."
            )
    else:
        print("RESULT: All tests failed to import 'ClassWidgets.Components'.")
        print("Common causes & checks:")
        print(
            "  * Make sure the project's QML path (src/qml) is added to the QQmlEngine import paths."
        )
        print(
            "  * Verify there is a directory at: src/qml/ClassWidgets/Components with a `qmldir` file."
        )
        print(
            "  * On case-sensitive filesystems (Linux), the directory name must match the module name\n"
            "    exactly. If the module is `ClassWidgets.Components`, the directory must be\n"
            "    `ClassWidgets/Components` (capital C)."
        )
        print()
        # Inspect qmldir contents if present and show mismatches
        if comp_lower_qmldir.exists():
            txt = read_head(comp_lower_qmldir, 10)
            print(f"Found components/qmldir (lowercase) content:\n{txt}\n")
            if "ClassWidgets.Components" in txt and not comp_upper.exists():
                print(
                    "Suggestion: The qmldir declares 'module ClassWidgets.Components' but the folder\n"
                    "is named 'components' (lowercase). On Linux you should rename the folder to\n"
                    "`Components` (capitalized) so the module path and folder name match:\n"
                    "    mv src/qml/ClassWidgets/components src/qml/ClassWidgets/Components"
                )
        elif comp_upper_qmldir.exists():
            txt = read_head(comp_upper_qmldir, 10)
            print(f"Found Components/qmldir (capitalized) content:\n{txt}\n")
        else:
            print(
                "No qmldir for ClassWidgets.Components found under either 'components' or 'Components'."
            )
            print(
                "Ensure that a qmldir declaring `module ClassWidgets.Components` exists under:"
            )
            print("    src/qml/ClassWidgets/Components/qmldir")
        print()
        print(
            "If you expect the import to work but it still doesn't, re-run this script and"
        )
        print(
            "observe the exact error text printed by the QQmlComponent errors: it often contains"
        )
        print(
            "the root cause (e.g. path missing, permission error, syntax error in qmldir)."
        )
        sys.exit(1)

    return 0


if __name__ == "__main__":
    sys.exit(main())
