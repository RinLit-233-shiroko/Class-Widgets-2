from pathlib import Path
from PySide6.QtCore import QObject, Signal, QRect, Qt, QTimer
from PySide6.QtGui import QRegion, QCursor
from loguru import logger

from src.core import QML_PATH
from src.core.directories import CW_PATH

from src.core.themes.manager import DEFAULT_THEME_ID

from src.core.themes.interceptor import ThemeUrlInterceptor
from src.core.windows.windows import ReleasableWindow


class WidgetsWindow(ReleasableWindow, QObject):
    themeReadyToReload = Signal()
    qmlReady = Signal()

    def __init__(self, app_central: QObject):
        super().__init__(app_central)
        self.app_central = app_central
        self.accepts_input = True
        self._theme_reloading = False

        self.engine.addImportPath(CW_PATH)
        self.qml_main_path = Path(QML_PATH / "MainInterface.qml")
        self.interactive_rect = QRegion()
        self._mask_update_pending = False
        self._qml_ready = False
        
        # 初始化主题拦截器
        self.interceptor = ThemeUrlInterceptor(self)
        self.engine.setUrlInterceptor(self.interceptor)

        self.engine.objectCreated.connect(self.on_qml_ready, type=Qt.ConnectionType.QueuedConnection)

    def _start_listening(self):
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_mouse_state)
        self.timer.start(33)  # 大约每秒30帧检测一次

    def run(self):
        """启动widgets窗口"""
        self.app_central.widgets_model.load_config()
        self._load_with_theme()
        self.app_central.theme_manager.themeChanged.connect(self.on_theme_changed)

    def release(self):
        if self.is_released:
            return

        timer = getattr(self, "timer", None)
        if timer:
            timer.stop()
        try:
            self.app_central.theme_manager.themeChanged.disconnect(self.on_theme_changed)
        except (RuntimeError, TypeError):
            pass
        super().release()

    def _load_with_theme(self):
        """加载QML并应用主题"""
        # 确保 src/qml 在导入路径中，以便能找到 ClassWidgets 模块
        self.engine.addImportPath(str(QML_PATH))

        current_theme_id = self.app_central.theme_manager.currentTheme
        if current_theme_id:
            # 验证主题是否存在
            if not self.app_central.theme_manager.isThemePathValid(current_theme_id):
                logger.error(f"Current theme '{current_theme_id}' path is invalid during initial load")
                logger.info(f"Falling back to default theme: {DEFAULT_THEME_ID}")
                # 切换到默认主题
                self.app_central.theme_manager.themeChange(DEFAULT_THEME_ID)
                current_theme_id = self.app_central.theme_manager.currentTheme

            current_theme_path = self.app_central.theme_manager.getThemePath(current_theme_id)
            if current_theme_path:
                logger.info(f"Setting theme interceptor path: {current_theme_path}")
                self.interceptor.set_theme(current_theme_path)
            else:
                logger.warning(f"Theme path is empty for theme: {current_theme_id}")
        else:
            logger.warning("No current theme ID set")

        self.load(self.qml_main_path)

        self._start_listening()

    @property
    def is_qml_ready(self) -> bool:
        return self._qml_ready

    def on_theme_changed(self):
        """主题变更时重新加载界面"""
        if self._theme_reloading:
            logger.info("Theme reload in progress, skipping")
            return

        self._theme_reloading = True
        logger.info("Theme changed, starting reload process")

        current_theme_id = self.app_central.theme_manager.currentTheme

        if not self.app_central.theme_manager.isThemePathValid(current_theme_id):
            logger.error(f"Theme '{current_theme_id}' path is invalid during theme change")
            logger.info(f"Falling back to default theme: {DEFAULT_THEME_ID}")
            self.app_central.theme_manager.themeChange(DEFAULT_THEME_ID)
            current_theme_id = self.app_central.theme_manager.currentTheme

        if current_theme_id:
            current_theme_path = self.app_central.theme_manager.getThemePath(current_theme_id)
            if current_theme_path:
                logger.info(f"Updating theme interceptor path: {current_theme_path}")
                self.interceptor.set_theme(current_theme_path)
            else:
                logger.warning(f"Theme path is empty for theme: {current_theme_id}")
                self.interceptor.set_theme(None)
        else:
            logger.warning("No current theme ID set during theme change")
            self.interceptor.set_theme(None)

        self.engine.clearComponentCache()
        self.engine.collectGarbage()
        logger.info("Component cache cleared")

        if self.root_window:
            self.root_window.setProperty("_force_theme_reload", True)
            self.root_window.setProperty("_force_theme_reload", False)
            logger.info("Force theme reload signal sent")

        self._trigger_widget_reload()
        self.engine.retranslate()

    
    def _trigger_widget_reload(self):
        """触发 widgets 重新加载"""
        logger.info("Triggering widget reload")
        self.app_central.theme_manager.themeReadyToReload.emit()

        self._theme_reloading = False
        logger.debug("Theme reloading flag reset to False")

    def on_qml_ready(self, obj, obj_url):
        if obj is None:
            logger.error("Main QML Load Failed")
            return

        if Path(obj_url.toLocalFile()).resolve() != self.qml_main_path.resolve():
            return

        if self._qml_ready:
            return

        widgets_loader = obj.findChild(QObject, "widgetsLoader")
        if widgets_loader:
            widgets_loader.geometryChanged.connect(self.schedule_mask_update)
            widgets_loader.contentGeometryChanged.connect(self.schedule_mask_update)
            self.schedule_mask_update()
            self._qml_ready = True
            self.qmlReady.emit()
            return
        logger.error("'widgetsLoader' object has not found'")

    def schedule_mask_update(self):
        if self._mask_update_pending:
            return

        self._mask_update_pending = True
        QTimer.singleShot(0, self.update_mask)

    # 裁剪窗口
    def update_mask(self):
        self._mask_update_pending = False
        if not self.root_window:
            return

        mask = QRegion()
        widgets_loader = self.root_window.findChild(QObject, "widgetsLoader")
        if not widgets_loader:
            return

        menu_show = widgets_loader.property("menuVisible") or False
        edit_mode = widgets_loader.property("editMode") or False

        if menu_show or edit_mode:
            self.interactive_rect = QRegion()
            self.root_window.setMask(QRegion())
            return

        # 小组件现位于 Flow 内部，Flow 是根容器的直接子项
        widgets_flow = widgets_loader.findChild(QObject, "widgetsFlow")
        if not widgets_flow:
            return

        base_x = widgets_loader.x()
        base_y = widgets_loader.y()
        flow_x = widgets_flow.x()
        flow_y = widgets_flow.y()

        for w in widgets_flow.childItems():
            if w.width() <= 0 or w.height() <= 0 or not w.isVisible():
                continue
            rect = QRect(
                int(w.x() + flow_x + base_x),
                int(w.y() + flow_y + base_y),
                int(w.width()),
                int(w.height())
            )
            mask = mask.united(QRegion(rect))

        self.interactive_rect = mask
        # An empty mask clips the whole transparent window. This is common while
        # asynchronous widget loaders are still resolving their item sizes.
        self.root_window.setMask(mask)

    def update_mouse_state(self):
        if not self.interactive_rect:
            return  # 没有 mask 就不处理
        if not self.app_central.configs.interactions.hover_fade:
            return  # 配置文件

        global_pos = QCursor.pos()
        local_pos = self.root_window.mapFromGlobal(global_pos)

        in_mask = self.interactive_rect.contains(local_pos)

        if in_mask and not self.accepts_input:
            self.root_window.setProperty(
                "mouseHovered",
                True
            )
            self.accepts_input = True

            # 鼠标不在有效区域
        elif not in_mask and self.accepts_input:
            self.root_window.setProperty(
                "mouseHovered",
                False
            )
            self.accepts_input = False
