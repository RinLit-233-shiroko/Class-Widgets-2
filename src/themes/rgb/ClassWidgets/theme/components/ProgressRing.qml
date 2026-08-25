import QtQuick
import QtQuick.Controls
import ClassWidgets.THEME

Rectangle {
    // RGB主题：颜色由效果引擎动态控制
    property color rgbColor: ThemeManager ? ThemeManager.rgbColor : "#4099b2"
    property real progress: 0.5
    
    width: 40
    height: 40
    radius: width / 2
    color: "transparent"
    border.width: 4
    border.color: Qt.alpha(rgbColor, 0.2)
    
    // 进度圆弧
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()
            ctx.strokeStyle = rgbColor
            ctx.lineWidth = 4
            ctx.lineCap = "round"
            var startAngle = -Math.PI / 2
            var endAngle = startAngle + (2 * Math.PI * parent.progress)
            ctx.arc(width/2, height/2, width/2 - 2, startAngle, endAngle)
            ctx.stroke()
        }
    }
    
    // 重新绘制的触发器
    onProgressChanged: requestPaint()
    onRgbColorChanged: requestPaint()
    
    Behavior on border.color {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }
}
