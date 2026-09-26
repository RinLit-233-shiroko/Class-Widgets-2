import QtQuick
import RinUI
import ClassWidgets.Theme 1.0 as BaseTheme


// Windows 10 Fluent 风格：平铺底色 + 1px 描边，固定 4px 圆角。
// 结构和全部 API 继承自 BaseWidget，这里只做样式覆盖。
BaseTheme.BaseWidget {
    id: root

    cornerRadius: 4
    borderWidth: 1.5

    backgroundColor: Theme.isDark()
        ? Qt.alpha("#2D2D2D", 0.8)
        : Qt.alpha("#EFEFEF", 0.8)
    borderColor: Theme.isDark()
        ? Qt.alpha("#000000", 0.36)
        : Qt.alpha("#000000", 0.14)

    clip: true
    opacity: hovered ? 0.9 : 1

    backgroundArea: Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.backgroundColor
        // 与原实现一致：只给颜色，边框宽度用 Rectangle 默认的 1px。
        border.color: root.borderColor
        opacity: Configs.data.preferences.opacity
    }
}
