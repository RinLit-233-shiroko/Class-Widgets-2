from pathlib import Path
from PySide6.QtCore import QObject, Slot, Property, Signal, QRect, Qt, QTimer
import RinUI
from PySide6.QtGui import QRegion, QCursor
from PySide6.QtWidgets import QApplication
from loguru import logger

from src.core import QML_PATH


class WidgetsWindow(RinUI.RinUIWindow, QObject):
    def __init__(self, app_central):
        super().__init__()
        self.app_central = app_central
        self.accepts_input = True

        self._setup_qml_context()
        self.qml_main_path = Path(QML_PATH / "MainInterface.qml")
        self.interactive_rect = QRegion()

        self.engine.objectCreated.connect(self.on_qml_ready, type=Qt.ConnectionType.QueuedConnection)

    def _setup_qml_context(self):
        """设置QML上下文属性"""
        self.app_central.setup_qml_context(self)

    def _start_listening(self):
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_mouse_state)
        self.timer.start(33)  # 大约每秒30帧检测一次

    def run(self):
        """启动widgets窗口"""
        self.app_central.widgets_model.load_config()
        self._load_with_theme()
        self.app_central.theme_manager.themeChanged.connect(self.on_theme_changed)
        self.app_central.retranslate.connect(self.engine.retranslate)

    def _load_with_theme(self):
        """加载QML并应用主题"""
        current_theme = self.app_central.theme_manager.currentTheme
        if current_theme:
            self.engine.addImportPath(str(current_theme))
        self.load(self.qml_main_path)

        self._start_listening()

    def on_theme_changed(self):
        """主题变更时重新加载界面"""
        self.engine.clearComponentCache()
        self._load_with_theme()

    def on_qml_ready(self, obj, objUrl):
        if obj is None:
            logger.error("Main QML Load Failed")
            return

        # 初始化防抖定时器
        self.mask_timer = QTimer(self)
        self.mask_timer.setSingleShot(True)
        self.mask_timer.setInterval(16)  # 约60fps，但也起到了合并同帧多次调用的作用
        self.mask_timer.timeout.connect(self._do_update_mask)

        widgets_loader = self.root_window.findChild(QObject, "widgetsLoader")
        if widgets_loader:
            widgets_loader.geometryChanged.connect(self.update_mask)
            # 延迟初始化掩码，确保 QML 布局已完成且窗口句柄已准备好
            QTimer.singleShot(500, self.update_mask)
            return
        logger.error("'widgetsLoader' object has not found'")

    # 裁剪窗口
    def update_mask(self):
        """
        请求更新窗口掩码（带防抖处理）。
        
        由于顶部栏在隐藏/显示时会有位置动画，频繁调用 setMask 会导致 macOS WindowServer 负载过高甚至程序死机。
        通过 QTimer 进行防抖，确保在动画期间掩码更新是平滑且受控的。
        """
        if hasattr(self, 'mask_timer'):
            self.mask_timer.start()

    def _do_update_mask(self):
        """
        实际执行掩码更新和交互区域计算。
        """
        widgets_loader = self.root_window.findChild(QObject, "widgetsLoader")
        if not widgets_loader:
            return

        menu_show = widgets_loader.property("menuVisible") or False
        edit_mode = widgets_loader.property("editMode") or False
        hide = widgets_loader.property("hide") or False

        if menu_show or edit_mode:
            # 在编辑模式或显示菜单时，允许点击整个屏幕
            self.root_window.setMask(QRegion())
            self.interactive_rect = QRegion(QRect(0, 0, int(self.root_window.width()), int(self.root_window.height())))
            return

        # 简化掩码计算：直接使用 widgetsLoader 的外接矩形
        # 这确保了整个组件区域（包括间隙）在 OS 层面都是可点击的
        win_w = int(self.root_window.width())
        win_h = int(self.root_window.height())
        
        rect = QRect(
            int(widgets_loader.x()),
            int(widgets_loader.y()),
            int(widgets_loader.width()),
            int(widgets_loader.height())
        ).intersected(QRect(0, 0, win_w, win_h))
        
        mask = QRegion(rect)
        self.interactive_rect = mask
        self.root_window.setMask(mask)
        logger.debug(f"Mask updated: {rect.x()}, {rect.y()}, {rect.width()}x{rect.height()}")

    def update_mouse_state(self):
        if not self.interactive_rect:
            return  # 没有 mask 就不处理
        if not self.app_central.configs.interactions.hover_fade:
            return  # 配置文件

        global_pos = QCursor.pos()
        # 获取窗口相对于屏幕的坐标
        win_pos = self.root_window.position()
        # 将全局坐标转换为相对于窗口的坐标
        local_pos = global_pos - win_pos

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