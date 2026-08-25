pragma Singleton
import QtQuick

/**
 * RGB主题 - 动态颜色定义
 * 所有颜色由效果引擎控制，通过 ThemeManager.rgbColor 动态更新
 */
QtObject {
    // 基础颜色（由效果引擎动态更新）
    property color primary: ThemeManager ? ThemeManager.rgbColor : "#4099b2"
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
