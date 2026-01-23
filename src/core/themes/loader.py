# ==============================
# file: src/core/themes/loader.py
# ==============================
"""ThemeLoader

- Uses packaging.version (PEP 440) for API compatibility checks
- No fallback logic (BUILTIN_THEMES must exist)
- Scans builtin themes from src.themes and external themes from THEMES_PATH
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import List, Dict, Any, Optional

from packaging.version import Version, InvalidVersion
from packaging.specifiers import SpecifierSet
from PySide6.QtCore import QUrl, QCoreApplication
from loguru import logger

from src.core.directories import THEMES_PATH
from src.themes import BUILTIN_THEMES

APP_API_VERSION = "2.0.0"


def is_compatible(theme_api_version: str, app_version: Version = APP_API_VERSION) -> bool:
    """检查主题API版本兼容性（使用 packaging.specifiers.SpecifierSet）"""
    if not theme_api_version or theme_api_version.strip() == "*":
        return True
        
    try:
        api_v = app_version
        required_specs = SpecifierSet(theme_api_version)
        return required_specs.contains(api_v)
    except Exception as e:
        logger.debug(
            f"Version check failed. Theme requirement: {theme_api_version}, "
            f"Host version: {app_version}. Error: {e}"
        )
        return False


class ThemeLoader:
    """Theme metadata loader (builtin + external)."""

    def scan_themes(self, external_path: Path = THEMES_PATH) -> List[Dict[str, Any]]:
        metas: List[Dict[str, Any]] = []

        # Built-in themes (authoritative, no fallback)
        logger.info("Loading built-in themes")
        for item in BUILTIN_THEMES:
            meta = dict(item["meta"])
            # 动态翻译内置主题的名称和描述
            meta["name"] = QCoreApplication.translate("Theme", meta["name"])
            meta["description"] = QCoreApplication.translate("Theme", meta["description"])
            meta["_type"] = "builtin"
            
            # Determine theme path
            theme_root = Path(__file__).resolve().parents[2] / "themes"
            theme_path = theme_root / meta["id"]
            if not theme_path.exists():
                plus_path = theme_root / meta['id']
                if plus_path.exists():
                    theme_path = plus_path
            
            meta["_path"] = str(theme_path)
            meta["_compatible"] = is_compatible(meta.get("api_version", "*"))
            
            # Convert preview path to QUrl
            if meta.get("preview"):
                preview_path = meta["preview"]
                if isinstance(preview_path, Path):
                    if preview_path.exists():
                        meta["preview"] = QUrl.fromLocalFile(str(preview_path))
                    else:
                        logger.warning(f"Preview file does not exist: {preview_path}")
                        meta["preview"] = None
                elif isinstance(preview_path, str):
                    preview_file = Path(preview_path)
                    if preview_file.exists():
                        meta["preview"] = QUrl.fromLocalFile(preview_file)
                    else:
                        logger.warning(f"Preview file does not exist: {preview_file}")
                        meta["preview"] = None
                else:
                    logger.warning(f"Invalid preview path type: {type(preview_path)}")
                    meta["preview"] = None
            else:
                meta["preview"] = None
            
            metas.append(meta)

        # External themes
        logger.info(f"Scanning external themes: {external_path}")
        if not external_path.exists():
            external_path.mkdir(parents=True, exist_ok=True)

        for theme_dir in external_path.iterdir():
            if not theme_dir.is_dir():
                continue
            logger.info(f"Found external theme directory: {theme_dir}")
            meta = self._load_external_meta(theme_dir)
            if not meta:
                continue
            meta["_compatible"] = is_compatible(meta.get("api_version", "*"))
            metas.append(meta)

        logger.info(f"Total themes loaded: {len(metas)}")
        return metas

    def _load_external_meta(self, theme_dir: Path) -> Optional[Dict[str, Any]]:
        meta_path = theme_dir / "cwtheme.json"
        if not meta_path.exists():
            return None

        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
            if not self._validate_meta(meta, theme_dir):
                return None

            meta = dict(meta)
            meta["_type"] = "external"
            meta["_path"] = str(theme_dir)

            if meta.get("preview"):
                preview = theme_dir / meta["preview"]
                meta["preview"] = QUrl.fromLocalFile(str(preview)) if preview.exists() else None
            else:
                meta["preview"] = None

            return meta
        except Exception:
            logger.exception(f"Failed to load theme meta: {theme_dir}")
            return None

    @staticmethod
    def _validate_meta(meta: Dict[str, Any], theme_dir: Path) -> bool:
        required = ["id", "name", "version", "api_version", "author"]
        for key in required:
            if not meta.get(key):
                logger.warning(f"Theme meta missing '{key}': {theme_dir}")
                return False
        return True
