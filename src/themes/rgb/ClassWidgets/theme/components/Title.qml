import QtQuick
import QtQuick.Controls
import ClassWidgets.Theme

Text {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: ThemeManager ? ThemeManager.rgbColor : "#4099b2"
    color: Qt.luma(rgbColor) > 0.5 ? "#000000" : "#ffffff"
    
    font.family: "Segoe UI"
    font.pixelSize: 18
    font.weight: Font.Bold
    elide: Text.ElideRight
    
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }
}
