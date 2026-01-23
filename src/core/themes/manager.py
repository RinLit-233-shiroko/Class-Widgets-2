from __future__ import annotations

from typing import List, Dict, Any, Optional
from pathlib import Path

from PySide6.QtCore import QObject, Signal, Slot, Property, QTimer, QThread, QUrl
from PySide6.QtGui import QDesktopServices
from PySide6.QtWidgets import QFileDialog
from loguru import logger

from src.core.themes.loader import ThemeLoader, APP_API_VERSION
from src.core.themes.worker import ThemeImportWorker
from src.core.directories import THEMES_PATH

DEFAULT_THEME_ID = "default"


class ThemeManager(QObject):
    themeChanged = Signal()
    themeListChanged = Signal()
    themeReadyToReload = Signal()
    themeImportSucceeded = Signal()
    themeImportFailed = Signal(str)

    def __init__(self, app_central, parent: Optional[QObject] = None):
        super().__init__(parent)
        self._app_central = app_central
        self._themes: List[Dict[str, Any]] = []
        self._currentTheme: str = ""

        self._cooldown = QTimer(self)
        self._cooldown.setSingleShot(True)
        self._cooldown.setInterval(500)
        self._cooldown.timeout.connect(self._apply_pending)
        self._pending: Optional[str] = None

        self.loader = ThemeLoader()
        
        # 连接到 retranslate 信号
        # app_central.retranslate.connect(self._on_retranslate)
        # self.scan()

    @Slot(result=list)
    def load(self):
        self.scan()
        return self._themes

    @Property('QVariant', notify=themeListChanged)
    def themes(self) -> List[Dict[str, Any]]:
        return list(self._themes)

    @Property(str, notify=themeChanged)
    def currentTheme(self) -> str:
        return self._currentTheme

    @Slot(result=str)
    def getAPIVersion(self) -> str:
        return str(APP_API_VERSION)

    @Slot(str, result=str)
    def getThemePath(self, theme_id: str) -> str:
        for theme in self._themes:
            if theme["id"] == theme_id:
                return theme.get("_path", "")
        return ""

    @Slot(str, result=dict)
    def getThemeById(self, theme_id: str):
        for theme in self._themes:
            if theme["id"] == theme_id:
                return theme
        return {}

    @Slot(str, result=str)
    def getThemeType(self, theme_id: str) -> str:
        """获取主题类型：'builtin' 或 'external'"""
        for theme in self._themes:
            if theme["id"] == theme_id:
                return theme.get("_type", "")
        return ""

    @Slot(str, result=bool)
    def isBuiltinTheme(self, theme_id: str) -> bool:
        """判断是否为内置主题"""
        return self.getThemeType(theme_id) == "builtin"

    @Slot(str, result=bool)
    def isThemePathValid(self, theme_id: str) -> bool:
        """验证主题路径是否存在"""
        theme_path = self.getThemePath(theme_id)
        if not theme_path:
            logger.warning(f"Theme '{theme_id}' path is empty")
            return False
        
        path = Path(theme_path)
        if not path.exists():
            logger.error(f"Theme path does not exist: {theme_path}")
            return False
        
        if not path.is_dir():
            logger.error(f"Theme path is not a directory: {theme_path}")
            return False
        
        logger.debug(f"Theme path is valid: {theme_path}")
        return True

    @Slot(str, result=bool)
    def isExternalTheme(self, theme_id: str) -> bool:
        """判断是否为外部主题"""
        return self.getThemeType(theme_id) == "external"

    @Slot(str, result=bool)
    def themeChange(self, theme_id: str) -> bool:
        if theme_id == self._currentTheme:
            return True

        if not any(t["id"] == theme_id for t in self._themes):
            logger.warning(f"Unknown theme: {theme_id}")
            return False

        if self._cooldown.isActive():
            self._pending = theme_id
            return True

        self._apply(theme_id)
        self._cooldown.start()
        return True

    def scan(self) -> None:
        self._themes = self.loader.scan_themes(THEMES_PATH)
        self._currentTheme = self._app_central.configs.preferences.current_theme
        
        if not self._is_theme_valid(self._currentTheme):
            logger.warning(f"Current theme '{self._currentTheme}' is invalid, falling back to default theme")
            self._currentTheme = DEFAULT_THEME_ID
            self._app_central.configs.preferences.current_theme = DEFAULT_THEME_ID
        
        self.themeListChanged.emit()
        self.themeChanged.emit()

    def _apply_pending(self) -> None:
        if self._pending:
            self._apply(self._pending)
            self._pending = None

    def _is_theme_valid(self, theme_id: str) -> bool:
        return any(t["id"] == theme_id for t in self._themes)

    def _on_retranslate(self):
        """翻译变更时重新扫描主题以更新翻译"""
        logger.info("Retranslating themes...")
        self.scan()

    def _apply(self, theme_id: str) -> None:
        """应用主题"""
        if not self._is_theme_valid(theme_id):
            logger.warning(f"Theme '{theme_id}' is invalid, falling back to default theme")
            theme_id = DEFAULT_THEME_ID
        
        # 验证主题路径是否存在
        if not self.isThemePathValid(theme_id):
            logger.error(f"Theme '{theme_id}' path is invalid, falling back to default theme")
            theme_id = DEFAULT_THEME_ID
            # 如果默认主题路径也不存在，记录严重错误
            if not self.isThemePathValid(theme_id):
                logger.critical(f"Default theme '{DEFAULT_THEME_ID}' path is also invalid! This should not happen.")
                return
        
        self._currentTheme = theme_id
        self._app_central.configs.preferences.current_theme = theme_id
        logger.info(f"Theme switched to {theme_id} (type: {self.getThemeType(theme_id)})")
        self.themeChanged.emit()

    # ---------------- 导入主题 ----------------
    @Slot(result='QVariant')
    def importTheme(self) -> List[dict]:
        """从 ZIP 导入主题（带冲突检测）
        
        返回值：
        - []: 用户取消或无冲突（无冲突时直接导入）
        - [冲突信息列表]: 有冲突需要确认
        """
        logger.info("Starting theme import process...")
        
        zip_path, _ = QFileDialog.getOpenFileName(
            None, "Import Theme", "", "Class Widgets Theme (*.cwtheme);;Theme ZIP (*.zip)"
        )
        if not zip_path:
            logger.info("Theme import cancelled by user")
            return []

        logger.info(f"Selected theme file: {zip_path}")
        logger.info("Checking for theme conflicts...")

        # 检查是否有冲突
        conflicts = self.get_conflicting_themes(zip_path)
        
        if conflicts:
            logger.warning(f"Found {len(conflicts)} conflicting theme(s): {[c['id'] for c in conflicts]}")
            # 有冲突，返回冲突信息供QML显示确认对话框
            for conflict in conflicts:
                conflict["zip_path"] = zip_path
            return conflicts
        else:
            logger.info("No conflicts found, proceeding with direct import")
            # 没有冲突，直接执行导入
            self.importThemeWithPath(zip_path)
            return []

    def get_conflicting_themes(self, zip_path: str) -> List[dict]:
        """检测ZIP文件中是否有与已安装主题冲突的主题"""
        import zipfile
        import json
        
        logger.debug(f"Analyzing zip file: {zip_path}")
        conflicting_themes = []
        
        try:
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                members = zip_ref.namelist()
                logger.debug(f"Found {len(members)} files in zip")
                
                theme_json_files = [m for m in members if m.endswith('cwtheme.json')]
                logger.debug(f"Found {len(theme_json_files)} theme.json files: {theme_json_files}")
                
                for member in theme_json_files:
                    try:
                        # 读取ZIP内的主题meta
                        meta_content = zip_ref.read(member).decode('utf-8')
                        theme_meta = json.loads(meta_content)
                        
                        theme_id = theme_meta.get("id")
                        logger.debug(f"Found theme ID: {theme_id} in {member}")
                        
                        if theme_id:
                            # 检查是否已存在此主题ID
                            existing_theme = next((m for m in self._themes if m["id"] == theme_id), None)
                            if existing_theme:
                                logger.warning(f"Theme conflict detected: {theme_id} (existing: {existing_theme.get('version', 'unknown')}, new: {theme_meta.get('version', 'unknown')})")
                                conflicting_themes.append({
                                    "id": theme_id,
                                    "name": theme_meta.get("name", theme_id),
                                    "version": theme_meta.get("version", "unknown"),
                                    "existing_version": existing_theme.get("version", "unknown"),
                                    "meta": theme_meta
                                })
                            else:
                                logger.debug(f"No conflict found for theme: {theme_id}")
                    except Exception as e:
                        logger.warning(f"Failed to read theme meta from {member}: {e}")
                        continue
        except Exception as e:
            logger.error(f"Failed to analyze zip file {zip_path}: {e}")
            
        return conflicting_themes

    @Slot(str, result='QVariant')
    def checkThemeConflicts(self, zip_path: str) -> List[dict]:
        """QML接口：检测ZIP文件中是否有与已安装主题冲突的主题"""
        return self.get_conflicting_themes(zip_path)

    @Slot(str, result=bool)
    def importThemeWithPath(self, zip_path: str) -> bool:
        """通过指定路径导入主题（带冲突检测）"""
        if not zip_path:
            return False

        self.thread = QThread()
        self.worker = ThemeImportWorker(zip_path, THEMES_PATH, self.scan, self._themes)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)

        def on_finished(result):
            if result and len(result) > 0:
                data = result[0]
                new_themes = data.get("new_themes", [])
                updated_themes = data.get("updated_themes", [])
                
                if new_themes or updated_themes:
                    if updated_themes:
                        logger.info(f"Updated theme(s): {', '.join(updated_themes)}")
                    if new_themes:
                        logger.info(f"Imported new theme(s): {', '.join(new_themes)}")
                    
                    self.themeListChanged.emit()
                    self.themeImportSucceeded.emit()
                else:
                    logger.warning(f"No themes were imported from: {zip_path}")
                    self.themeImportFailed.emit("No valid theme found in archive.")
            else:
                logger.warning(f"Theme import failed: {zip_path}")
                self.themeImportFailed.emit("No valid theme found in archive.")
            self.thread.quit()
            self.worker.deleteLater()
            self.thread.deleteLater()

        def on_error(msg):
            logger.error(f"Theme import error: {msg}")
            self.themeImportFailed.emit(msg)
            self.thread.quit()
            self.worker.deleteLater()
            self.thread.deleteLater()

        self.worker.finished.connect(on_finished)
        self.worker.error.connect(on_error)

        self.thread.start()
        return True

    @Slot(str, result=bool)
    def openThemeFolder(self, theme_id: str) -> bool:
        """
        打开指定主题的本地文件夹
        """
        meta = next((m for m in self._themes if m["id"] == theme_id), None)
        if not meta:
            logger.warning(f"Theme {theme_id} not found, cannot open folder.")
            return False

        folder_path = meta.get("_path")
        if not folder_path or not Path(folder_path).exists():
            logger.warning(f"Theme folder {folder_path} does not exist.")
            return False

        # 打开文件夹
        url = QUrl.fromLocalFile(str(folder_path))
        success = QDesktopServices.openUrl(url)
        if not success:
            logger.error(f"Failed to open theme folder: {folder_path}")
        return success

    @Slot(str, result=bool)
    def uninstallTheme(self, theme_id: str) -> bool:
        """
        卸载指定外部主题
        """
        meta = next((m for m in self._themes if m["id"] == theme_id), None)
        if not meta:
            logger.warning(f"Theme {theme_id} not found, cannot uninstall.")
            return False

        # 内置主题卸载不了
        if meta.get("_type") == "builtin":
            logger.warning(f"Theme {theme_id} is builtin and cannot be uninstalled.")
            return False

        try:
            # 如果是当前主题，切换到默认主题
            if theme_id == self._currentTheme:
                logger.info(f"Uninstalling current theme {theme_id}, switching to default theme")
                self.themeChange(DEFAULT_THEME_ID)

            # 删除主题目录
            theme_dir = Path(meta["_path"])
            if theme_dir.exists():
                import shutil
                shutil.rmtree(theme_dir)
                logger.info(f"Uninstalled theme {theme_id}, removed {theme_dir}")

            # 重新扫描主题列表
            self.scan()
            return True
        except Exception as e:
            logger.exception(f"Failed to uninstall theme {theme_id}: {e}")
            return False
