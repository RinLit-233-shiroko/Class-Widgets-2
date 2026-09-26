import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme 1.0


// Windows 10 的副标题：除对齐方式外与默认 Subtitle 一致。
// Layout.fillWidth 让 subtitleArea 吃掉 header 的剩余宽度，
// horizontalAlignment 再把文字在这块宽度里居中。
Text {
    id: text
    opacity: 0.6

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignCenter
    horizontalAlignment: Qt.AlignHCenter

    font: {
        var f = AppCentral.getQFont(Configs.data.preferences.font, Utils.fontFamily)
        f.pixelSize = 16
        f.weight = Configs.data.preferences.font_weight || 600
        return f
    }
}
