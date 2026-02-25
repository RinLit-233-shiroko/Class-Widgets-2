import QtQuick 2.15
import QtQuick.Controls 2.15
import "../../themes"
import "../../components"


ItemDelegate {
    id: root
    property var itemData
    property int parentIndex: -1
    property var currentPage
    highlighted: String(navigationBar.currentPage) === String(itemData.page)

    height: 40

    focusPolicy: collapsed ? Qt.NoFocus : Qt.StrongFocus  // to get keyboard focus

    // accessibility
    FocusIndicator {
        control: parent
        anchors.margins: 2
    }

    width: parent ? parent.width : 200

    background: Rectangle {
        id: itemBg
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        clip: true
        radius: Theme.currentTheme.appearance.buttonRadius / 2
        color: pressed
            ? Theme.currentTheme.colors.subtleTertiaryColor
            : (root.highlighted || root.hovered)
                ? Theme.currentTheme.colors.subtleSecondaryColor
                : Theme.currentTheme.colors.subtleColor

        Row {
            id: left
            spacing: 16
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 11 + 34
            anchors.topMargin: 6
            anchors.bottomMargin: 8

            IconWidget {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                size: itemData.size !== undefined ? itemData.size : (itemData.icon || itemData.source ? 19 : 0)
                icon: itemData.icon || ""
                source: itemData.source || ""
                enableColorOverlay: itemData.enableColorOverlay || false
            }

            Text {
                id: text
                anchors.verticalCenter: parent.verticalCenter
                typography: Typography.Body
                text: itemData.title
                clip: true
                opacity: navigationBar.collapsed ? 0 : 1
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                width: itemBg.width - parent.anchors.leftMargin - x - 10

                Behavior on x {
                    NumberAnimation {
                        duration: Utils.appearanceSpeed
                        easing.type: Easing.InOutQuint
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Utils.appearanceSpeed
                    }
                }
            }
        }

        Indicator {
            id: indicator
            x: left.x - 11
            y: root.height / 2 - indicator.height / 2 -2
            currentItemHeight: root.height
            visible: highlighted ? 1 : 0
            width: 3
        }

        Behavior on color {
            ColorAnimation {
                duration: Utils.appearanceSpeed
                easing.type: Easing.InOutQuart
            }
        }
    }

    onClicked: {
        if (itemData.page && currentPage && !root.highlighted && !collapsed) {
            // monkey-patch: 透传 itemData.properties 给页面实例（如 pluginId）
            navigationView.safePush(itemData.page, false, false, itemData.properties || {})
        }
    }
}
