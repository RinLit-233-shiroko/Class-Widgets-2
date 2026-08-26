import QtQuick
import QtQuick.Controls
import ClassWidgets.Theme 1.0

Text {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: "#4099b2"
    color: rgbColor
    
    font.family: "Segoe UI"
    font.pixelSize: 16
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    
    Behavior on color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }
}
