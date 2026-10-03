# -*- mode: python ; coding: utf-8 -*-
import sys
import os
import sysconfig
from pathlib import Path
from PyInstaller.utils.hooks import collect_submodules

block_cipher = None

# Platform-specific icon
if sys.platform == 'win32':
    icon_file = 'assets/images/logo.ico'
elif sys.platform == 'darwin':
    icon_file = 'assets/images/logo.icns'
else:
    icon_file = None

# ==================== 1. 动态收集全量标准库 ====================
stdlib_dir = sysconfig.get_path('stdlib')
stdlib_modules = set()

# 忽略环境内部的三方库、缓存和测试文件夹
ignored_names = {
    'site-packages', 'dist-packages', 'test', 'tests', 
    '__pycache__', 'idlelib', 'turtledemo'
}

if stdlib_dir and os.path.exists(stdlib_dir):
    for item in os.listdir(stdlib_dir):
        if item in ignored_names:
            continue
        full_path = os.path.join(stdlib_dir, item)
        # 包目录（含有 __init__.py）
        if os.path.isdir(full_path) and os.path.exists(os.path.join(full_path, '__init__.py')):
            stdlib_modules.add(item)
        # 纯 Python 模块文件
        elif item.endswith('.py') and not item.startswith('_'):
            stdlib_modules.add(item[:-3])

# 使用 collect_submodules 展开各包的子模块
all_stdlib_imports = set()
for mod in stdlib_modules:
    try:
        submods = collect_submodules(mod)
        if submods:
            all_stdlib_imports.update(submods)
        else:
            all_stdlib_imports.add(mod)
    except Exception:
        all_stdlib_imports.add(mod)

# 原项目中指定的 hiddenimports
base_hiddenimports = [
    'sqlite3', 
    'tkinter',
    'xml.etree.ElementTree',
    '_elementtree',
    'mmap',
    'winsound',
]

# 合并去重
combined_hiddenimports = list(set(base_hiddenimports) | all_stdlib_imports)
# ===============================================================

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
    hiddenimports=combined_hiddenimports,
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
    contents_directory='.',
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
)

if sys.platform == 'darwin':
    app = BUNDLE(
        coll,
        name='Class Widgets 2.app',
        icon=icon_file,
        bundle_identifier=None,
    )
