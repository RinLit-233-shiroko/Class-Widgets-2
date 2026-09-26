# -*- mode: python ; coding: utf-8 -*-
import sys
from pathlib import Path

block_cipher = None

# Platform-specific icon
if sys.platform == 'win32':
    icon_file = 'assets/images/logo.ico'
elif sys.platform == 'darwin':
    icon_file = 'assets/images/logo.icns'
else:
    icon_file = None

a = Analysis(
    ['src/app.py'],
    pathex=['.'],
    binaries=[],
    datas=[
        ('src/qml', 'src/qml'),
        ('src/plugins', 'src/plugins'),
        ('src/themes', 'src/themes'),
        ('assets', 'assets'),
        ('LICENSE', '.'),
    ],
    hiddenimports=['sqlite3', 'tkinter'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Class Widgets 2',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=icon_file,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Class Widgets 2',
    contents_directory='.',
)

if sys.platform == 'darwin':
    app = BUNDLE(
        coll,
        name='Class Widgets 2.app',
        icon=icon_file,
        bundle_identifier=None,
    )
