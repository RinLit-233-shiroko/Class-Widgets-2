pragma Singleton
import QtQuick

/**
 * RGB主题 - 动态颜色定义
 * 注意：此单例提供默认颜色，实际动态颜色由各组件的 rgbColor 属性控制
 */
QtObject {
    // 基础颜色（默认值，实际由组件 rgbColor 属性动态控制）
    property color primary: "#4099b2"
    property color onPrimary: Qt.luma(primary) > 0.5 ? "#000000" : "#ffffff"
    
    // 表面颜色（基于主色调的变体）
    property color surfaceBright: Qt.lighter(primary, 3.0)
    property color surfaceDim: Qt.darker(primary, 2.0)
    property color surface: Qt.luma(primary) > 0.5 ? surfaceDim : surfaceBright
    
    // 文字颜色
    property color textPrimary: Qt.luma(primary) > 0.5 ? "#000000" : "#ffffff"
    property color textSecondary: Qt.alpha(textPrimary, 0.7)
    property color textDisabled: Qt.alpha(textPrimary, 0.3)
    
    // 边框和分隔线
    property color outline: Qt.alpha(textPrimary, 0.2)
    property color divider: Qt.alpha(textPrimary, 0.1)
    
    // 状态颜色
    property color error: "#ff5449"
    property color success: "#4caf50"
    property color warning: "#ff9800"
    
    // 发光/阴影颜色
    property color glow: Qt.alpha(primary, 0.3)
}
