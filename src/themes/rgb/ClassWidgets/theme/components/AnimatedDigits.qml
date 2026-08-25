import QtQuick
import QtQuick.Controls
import ClassWidgets.Theme

Item {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: ThemeManager ? ThemeManager.rgbColor : "#4099b2"
    property string digits: "00"
    
    width: childrenRect.width
    height: 24
    
    Row {
        spacing: 2
        Repeater {
            model: digits.length
            delegate: Text {
                text: digits[index]
                font.family: "Segoe UI Mono"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: Qt.luma(rgbColor) > 0.5 ? "#000000" : "#ffffff"
                
                Behavior on color {
                    ColorAnimation {
                        duration: 300
                        easing.type: Easing.Bezier
                    }
                }
            }
        }
    }
}
