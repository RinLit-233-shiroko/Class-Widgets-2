@echo off
setlocal EnableExtensions
cd /d "%~dp0"

py -3.12 -m pip install --upgrade pip
py -3.12 -m pip install -r requirements.txt pyinstaller

py -3.12 -m PyInstaller ^
  --noconfirm ^
  --clean ^
  --windowed ^
  --onefile ^
  --name "ClassWidgets2-Settings-Plaza" ^
  --icon "assets\images\logo.ico" ^
  --add-data "src\qml;src\qml" ^
  --add-data "src\plugins;src\plugins" ^
  --add-data "src\themes;src\themes" ^
  --add-data "themes;themes" ^
  --add-data "assets;assets" ^
  --add-data "LICENSE;." ^
  --paths "." ^
  src\settings_plaza_app.py

if errorlevel 1 (
  echo.
  echo Build failed.
  exit /b 1
)

echo.
echo Build complete: %CD%\dist\ClassWidgets2-Settings-Plaza.exe
endlocal
