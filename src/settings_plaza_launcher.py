"""启动 Class Widgets 2 包体内的“设置与插件中心”模式。

此轻量启动器会查找同目录的主程序，并以 ``--settings-plaza`` 参数启动它。
因此独立入口无需重复打包 Qt、主题和插件资源，始终使用同一份 Class Widgets 2 包体。
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


MAIN_EXECUTABLE = "Class Widgets 2.exe"


def main() -> int:
    package_dir = Path(sys.executable).resolve().parent
    main_executable = package_dir / MAIN_EXECUTABLE

    if not main_executable.is_file():
        # 便于从源码环境直接调用和排查路径问题。
        raise FileNotFoundError(
            f"未在启动器同目录找到主程序：{main_executable}"
        )

    creationflags = 0
    if sys.platform == "win32":
        creationflags = subprocess.CREATE_NEW_PROCESS_GROUP

    subprocess.Popen(
        [str(main_executable), "--settings-plaza"],
        cwd=package_dir,
        creationflags=creationflags,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
