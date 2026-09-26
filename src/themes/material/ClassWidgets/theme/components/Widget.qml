import QtQuick
import ClassWidgets.Theme 1.0 as BaseTheme
import ClassWidgets.Theme.Material


// Material You 3 主题：跟随种子色的表面色，圆角随高度变化。
// 结构和全部 API 继承自 BaseWidget，这里只做样式覆盖。
BaseTheme.BaseWidget {
    id: root

    cornerRadius: height * 0.32
    borderWidth: 1.5
    lightingEffect: false

    backgroundColor: MaterialColor.surfaceBright

    clip: true
    opacity: hovered ? 0.8 : 1

    backgroundArea: Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.backgroundColor
        opacity: Configs.data.preferences.opacity
    }
}
