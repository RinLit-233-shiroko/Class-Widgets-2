import os
import subprocess
from pathlib import Path
import zipfile


APP_NAME = "Class Widgets 2.exe"


class WindowsUpdater:
    """
    解压并替换更新
    """

    def __init__(self, temp_dir: Path):
        self.temp_dir = temp_dir

    def apply_update(self, zip_path: Path, target_dir: Path):
        # 解压到临时目录
        extract_dir = self.temp_dir / "extracted"
        extract_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path, "r") as z:
            z.extractall(extract_dir)

        cmd_file = self.temp_dir / "replace_and_restart.cmd"
        with open(cmd_file, "w", encoding="utf-8") as f:
            f.write(
                f"""
                @echo off
                timeout /t 2 /nobreak >nul
                echo Updating files...
                xcopy /E /Y /Q "{extract_dir}" "{target_dir}"
                echo Done. Restarting...
                start "" "{target_dir / APP_NAME}" --update-done
                """
            )

        subprocess.Popen(
            ["cmd", "/c", str(cmd_file)],
            creationflags=subprocess.CREATE_NO_WINDOW,  # 静默执行w
            close_fds=True
        )
        os._exit(0)
