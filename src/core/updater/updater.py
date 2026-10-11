import os
import shutil
import stat
import subprocess
from pathlib import Path
import zipfile


APP_NAME = "Class Widgets 2.exe"
PROTECTED_PATHS = {"portable", "data", "configs", "plugins", "themes", "logs", "cache", "temp", "audio"}


class WindowsUpdater:
    """
    解压并替换更新
    """

    def __init__(self, temp_dir: Path):
        self.temp_dir = temp_dir

    def apply_update(self, zip_path: Path, target_dir: Path):
        target_dir = Path(target_dir).resolve()
        # 解压到临时目录
        extract_dir = self.temp_dir / "extracted"
        if extract_dir.exists():
            shutil.rmtree(extract_dir)
        extract_dir.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(zip_path, "r") as z:
            members = []
            for member in z.infolist():
                name = member.filename.replace("\\", "/")
                parts = name.rstrip("/").split("/")
                if (
                    name.startswith("/")
                    or any(not part or part in (".", "..") or ":" in part
                           or part.rstrip(" .") != part for part in parts)
                    or stat.S_IFMT(member.external_attr >> 16) == stat.S_IFLNK
                ):
                    raise ValueError(f"Unsafe update path: {member.filename}")
                if parts[0].casefold() in PROTECTED_PATHS:
                    continue
                destination = target_dir.joinpath(*parts)
                if not destination.resolve().is_relative_to(target_dir):
                    raise ValueError(f"Update destination escapes installation: {destination}")
                members.append(member)
            z.extractall(extract_dir, members=members)
        if not (extract_dir / APP_NAME).is_file():
            raise ValueError(f"Update archive is missing {APP_NAME}")

        cmd_file = self.temp_dir / "replace_and_restart.cmd"
        with open(cmd_file, "w", encoding="utf-8") as f:
            f.write(
                f"""
                @echo off
                chcp 65001 >nul
                timeout /t 2 /nobreak >nul
                echo Updating files...
                xcopy /E /Y /Q "{extract_dir}" "{target_dir}"
                if errorlevel 1 exit /b 1
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
