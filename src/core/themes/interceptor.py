from __future__ import annotations

from pathlib import Path
from PySide6.QtCore import QUrl, Qt, QObject
from PySide6.QtQml import QQmlAbstractUrlInterceptor
from loguru import logger
from src.core.directories import QML_PATH
import time

class ThemeUrlInterceptor(QQmlAbstractUrlInterceptor):
    def __init__(self, parent=None):
        super().__init__(parent)
        self._current_theme_path: Path | None = None
        self._nonce: str = str(int(time.time() * 1000))
        self._target_path = "ClassWidgets/theme"

    def set_theme(self, theme_path: str | Path):
        """设置当前主题路径"""
        if not theme_path:
            self._current_theme_path = None
            self._nonce = str(int(time.time() * 1000))
            return

        path = Path(theme_path)
        if path.exists() and path.is_dir():
            self._current_theme_path = path
            self._nonce = str(int(time.time() * 1000))
            logger.info(f"Theme interceptor set to: {self._current_theme_path}")
        else:
            logger.warning(f"Invalid theme path set: {theme_path}")
            self._current_theme_path = None

    def intercept(self, url: QUrl, type: QQmlAbstractUrlInterceptor.DataType) -> QUrl:
        """
        拦截 QML 引擎的文件请求。
        """
        if not self._current_theme_path:
            return url

        # 获取本地文件路径
        # QUrl("file:///C:/path/to/file").toLocalFile() -> "C:/path/to/file"
        source_path_str = url.toLocalFile()
        if not source_path_str:
            return url

        # 统一路径分隔符以便匹配
        source_path_str = source_path_str.replace('\\', '/')
        
        lower_source = source_path_str.lower()
        lower_target = self._target_path.lower()
        idx = lower_source.rfind(lower_target)
        if idx == -1:
            return url

        # 提取相对路径

        relative_part = source_path_str[idx:]

        # 防止循环重定向：如果当前路径已经在当前主题目录下
        current_theme_str = str(self._current_theme_path).replace('\\', '/')
        if source_path_str.lower().startswith(current_theme_str.lower()):
            p = Path(source_path_str)
            if p.exists():
                return url
            default_file = QML_PATH / relative_part
            if default_file.exists():
                q = QUrl.fromLocalFile(str(default_file))
                q.setQuery(f"t={self._nonce}")
                return q
            return url

        try:
            # 获得各个主题 ClassWidgets/theme 在路径中的实际的位置
            # 构建目标路径
            target_file = self._current_theme_path / relative_part
            
            if target_file.exists():
                q = QUrl.fromLocalFile(str(target_file))
                q.setQuery(f"t={self._nonce}")
                return q
            else:
                default_file = QML_PATH / relative_part
                if default_file.exists():
                    q = QUrl.fromLocalFile(str(default_file))
                    q.setQuery(f"t={self._nonce}")
                    return q
            
        except Exception as e:
            logger.error(f"Error intercepting URL {url}: {e}")

        return url
