"""启动 Class Widgets 2 包体内的独立“设置”窗口。"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


MAIN_EXECUTABLE = "Class Widgets 2.exe"


def main() -> int:
    package_dir = Path(sys.executable).resolve().parent
    main_executable = package_dir / MAIN_EXECUTABLE
    if not main_executable.is_file():
        raise FileNotFoundError(f"未在启动器同目录找到主程序：{main_executable}")

    creationflags = subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == "win32" else 0
    subprocess.Popen(
        [str(main_executable), "--settings-only"],
        cwd=package_dir,
        creationflags=creationflags,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
