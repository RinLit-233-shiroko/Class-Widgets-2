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
    themeLoadFailed = Signal(str)

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
        self.engine.warnings.connect(self._on_qml_warnings)

    def _start_listening(self):
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_mouse_state)
        self.timer.start(33)  # 大约每秒30帧检测一次

    def run(self):
        """启动widgets窗口"""
        self.app_central.widgets_model.load_config()
        # Connect before the first load so an invalid startup theme can be
        # replaced immediately when the failure handler selects the default.
        self.app_central.theme_manager.themeChanged.connect(self.on_theme_changed)
        self._load_with_theme()

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

        # Do not collect QML garbage from inside a Loader warning/object
        # creation callback. On some Qt versions this blocks the GUI thread
        # while the failing component is still being torn down.
        QTimer.singleShot(0, self._finish_theme_reload)

    def _finish_theme_reload(self):
        # Theme components are resolved by QML's type cache. Clear it before
        # recreating the theme-owned Loader contents. The widget reload is
        # intentionally deferred until the theme Loader reports Ready.
        try:
            self.engine.clearComponentCache()
            self.app_central.theme_manager.themeReadyToReload.emit()
        except Exception:
            logger.exception("Theme component reload failed")
            self.abort_theme_reload()
            return
        logger.info("Theme component cache cleared; waiting for theme readiness")


    def _trigger_widget_reload(self):
        """触发 widgets 重新加载"""
        logger.info("Triggering widget reload")
        self.app_central.theme_manager.widgetsReadyToReload.emit()

    def confirm_theme_load_ready(self):
        """Release the theme reload gate after a theme component is Ready."""
        if not self._theme_reloading:
            return

        self._trigger_widget_reload()
        self._theme_reloading = False
        logger.info("Theme component is ready; widget reload signal sent")

    def abort_theme_reload(self):
        """Allow the recovery path to select and load the fallback theme."""
        if self._theme_reloading:
            self._theme_reloading = False
            logger.info("Theme reload aborted; waiting for fallback theme")

    def on_qml_ready(self, obj, obj_url):
        if Path(obj_url.toLocalFile()).resolve() != self.qml_main_path.resolve():
            return

        if obj is None:
            failed_theme = self.app_central.theme_manager.currentTheme
            logger.error(f"Main QML Load Failed for theme '{failed_theme}'")
            self._apply_empty_mask()
            self._qml_ready = False
            self.abort_theme_reload()
            self.themeLoadFailed.emit(failed_theme)
            return

        if self._qml_ready:
            return

        widgets_loader = obj.findChild(QObject, "widgetsLoader")
        if widgets_loader:
            widgets_loader.geometryChanged.connect(self.schedule_mask_update)
            widgets_loader.contentGeometryChanged.connect(self.schedule_mask_update)

            # 连接浮窗容器的几何变化信号
            floating_container = obj.findChild(QObject, "floatingWidgetContainer")
            if floating_container:
                floating_container.geometryChanged.connect(self.schedule_mask_update)
                logger.info("Floating widget container connected for mask updates")

            self.schedule_mask_update()
            self._qml_ready = True
            self.qmlReady.emit()
            return
        logger.error("'widgetsLoader' object has not found'")
        self._apply_empty_mask()
        self.abort_theme_reload()
        self.themeLoadFailed.emit(self.app_central.theme_manager.currentTheme)

    def _on_qml_warnings(self, warnings):
        """Log QML warnings without treating runtime diagnostics as load failures.

        Qt reports binding loops and non-bindable-property notices through the
        same warnings channel as component errors. The main QML object and
        Loader status are the authoritative signals for a failed theme load;
        warnings alone are not.
        """
        theme_path = self.app_central.theme_manager.getThemePath(
            self.app_central.theme_manager.currentTheme
        )
        if not theme_path:
            return

        theme_root = Path(theme_path).resolve()
        for warning in warnings:
            source_path = Path(warning.url().toLocalFile()).resolve()
            try:
                source_path.relative_to(theme_root)
            except ValueError:
                continue

            description = warning.description()
            logger.warning("Theme QML warning at {}: {}", source_path, description)

    def _apply_empty_mask(self):
        """Keep a failed or incomplete QML load from exposing the full window."""
        self.interactive_rect = QRegion()
        if self.root_window:
            self.root_window.setMask(QRegion(QRect(0, 0, 1, 1)))

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
            # An empty region clears the native mask and makes this full-screen
            # transparent window cover the entire desktop while QML is loading.
            self._apply_empty_mask()
            return

        menu_show = widgets_loader.property("menuVisible") or False
        edit_mode = widgets_loader.property("editMode") or False
        if menu_show or edit_mode:
            self.interactive_rect = QRegion()
            self.root_window.setMask(QRegion())
            return

        # 小组件现位于 Flow 内部，Flow 是根容器的直接子项。浮窗模式切换时
        # 仍需保留实际几何，才能让小组件完成自身的移出动画后再消失。
        widgets_flow = widgets_loader.findChild(QObject, "widgetsFlow")
        if widgets_flow:
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

        # 浮窗区域加入 mask
        floating_container = self.root_window.findChild(QObject, "floatingWidgetContainer")
        # 非浮窗模式下容器不可见，因此不会扩大透明窗口的可交互区域。
        if floating_container and floating_container.isVisible():
            fw_x = int(floating_container.x())
            fw_y = int(floating_container.y())
            fw_scale = float(floating_container.property("scale") or 1.0)
            fw_w = int(floating_container.width() * fw_scale)
            fw_h = int(floating_container.height() * fw_scale)
            if fw_w > 0 and fw_h > 0:
                rect = QRect(fw_x, fw_y, fw_w, fw_h)
                mask = mask.united(QRegion(rect))

        self.interactive_rect = mask
        if mask.isEmpty():
            # setMask(QRegion()) clears the native mask, which makes the
            # full-screen transparent window cover the entire desktop. Keep a
            # minimal non-empty mask until a widget has a valid geometry.
            mask = QRegion(QRect(0, 0, 1, 1))
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
