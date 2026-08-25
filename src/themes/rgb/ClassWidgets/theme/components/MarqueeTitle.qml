import QtQuick
import QtQuick.Controls
import ClassWidgets.Theme

Item {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: ThemeManager ? ThemeManager.rgbColor : "#4099b2"
    property string title: ""
    
    width: 200
    height: 24
    clip: true
    
    Text {
        id: titleText
        text: title
        font.family: "Segoe UI"
        font.pixelSize: 14
        font.weight: Font.Medium
        color: Qt.luma(rgbColor) > 0.5 ? "#000000" : "#ffffff"
        
        Behavior on color {
            ColorAnimation {
                duration: 300
                easing.type: Easing.Bezier
            }
        }
    }
}
