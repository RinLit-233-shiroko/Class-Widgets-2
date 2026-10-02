import QtQuick
import QtQuick.Controls
import RinUI

// Fluent 拆分按钮 / Split button
// 左侧为主操作，右侧箭头展开下拉菜单（"重新启动并进入安全模式" 这类默认动作）。
Item {
    id: root

    property string text: ""
    default property alias menuItems: menu.contentData

    signal accepted()

    readonly property int buttonHeight: 32
    implicitHeight: buttonHeight
    implicitWidth: mainButton.implicitWidth + separator.width + arrowButton.width

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Theme.currentTheme.appearance.buttonRadius
        color: {
            const accent = Theme.currentTheme.colors.primaryColor
            if (mainButton.pressed || arrowButton.pressed)
                return Qt.darker(accent, 1.12)
            if (mainButton.hovered || arrowButton.hovered || menu.opened)
                return Qt.lighter(accent, 1.06)
            return accent
        }
        border.width: Theme.currentTheme.appearance.borderWidth
        border.color: Qt.alpha("#FFFFFF", 0.08)

        Behavior on color {
            ColorAnimation { duration: Utils.appearanceSpeed; easing.type: Easing.OutQuart }
        }
    }

    Button {
        id: mainButton
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: implicitWidth
        text: root.text
        highlighted: true
        // 强调色背景由 SplitButton 自己绘制（保证圆角/分隔线一致）。
        background: Rectangle { color: "transparent"; border.width: 0 }
        onClicked: root.accepted()
    }

    // 主操作和下拉区之间的分隔线
    Rectangle {
        id: separator
        anchors.right: arrowButton.left
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 2
        color: Qt.alpha("#FFFFFF", 0.12)
    }

    Button {
        id: arrowButton
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 35
        highlighted: true
        background: Rectangle { color: "transparent"; border.width: 0 }
        icon.name: "ic_fluent_chevron_down_20_regular"
        onClicked: menu.opened ? menu.close() : menu.open()
    }

    Menu {
        id: menu
        position: Position.Top
    }
}
