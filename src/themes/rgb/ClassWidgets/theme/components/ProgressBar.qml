import QtQuick
import QtQuick.Controls
import ClassWidgets.Theme

ProgressBar {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: "#4099b2"
    
    from: 0
    to: 100
    
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 8
        color: Qt.alpha(rgbColor, 0.2)
        radius: 4
        
        Behavior on color {
            ColorAnimation {
                duration: 300
                easing.type: Easing.Bezier
            }
        }
    }
    
    contentItem: Rectangle {
        implicitWidth: 200
        implicitHeight: 8
        color: rgbColor
        radius: 4
        
        Behavior on color {
            ColorAnimation {
                duration: 300
                easing.type: Easing.Bezier
            }
        }
    }
}
