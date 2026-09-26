import QtQuick
import RinUI
import ClassWidgets.Theme 1.0 as BaseTheme


// Class Widgets 1 经典主题：纯色圆角卡片。
// 结构和全部 API 继承自 BaseWidget，这里只做样式覆盖。
BaseTheme.BaseWidget {
    id: root

    cornerRadius: 8
    borderWidth: 1.5

    backgroundColor: Theme.isDark()
        ? Qt.alpha("#0F1216", 0.85)
        : Qt.alpha("#FFFFFF", 0.85)
    borderColor: Theme.isDark()
        ? Qt.alpha("#000000", 0.36)
        : Qt.alpha("#000000", 0.14)

    clip: true
    opacity: hovered ? 0.9 : 1

    backgroundArea: Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.backgroundColor
        opacity: Configs.data.preferences.opacity
    }
}
