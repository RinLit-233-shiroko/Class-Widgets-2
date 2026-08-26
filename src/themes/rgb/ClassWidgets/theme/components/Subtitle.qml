import QtQuick
import QtQuick.Controls
import ClassWidgets.Theme 1.0

Text {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: "#4099b2"
    color: Qt.alpha(Qt.luma(rgbColor) > 0.5 ? "#000000" : "#ffffff", 0.7)
    
    font.family: "Segoe UI"
    font.pixelSize: 12
    elide: Text.ElideRight
    
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }
}
