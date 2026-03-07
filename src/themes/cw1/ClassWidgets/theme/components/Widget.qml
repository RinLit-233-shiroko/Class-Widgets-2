import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Theme 1.0
import ClassWidgets.Easing


Item {
    id: widgetBase
    // 最小宽度 = 内容 + 边距，默认可以被拉伸
    readonly property bool miniMode: Configs.data.preferences.mini_mode
    readonly property bool hide: Configs.data.interactions.hide.state
    property bool editMode: false
    property bool lightingEffect: Configs.data.preferences.lighting_effect || true

    implicitWidth: Math.max(headerRow.implicitWidth, contentArea.childrenRect.width) + 48
    height: miniMode ? 56 : 100
    clip: true
    opacity: widgetHoverHandler.hovered? 0.9 : 1

    // colors
    property color backgroundColor: Theme.isDark()
        ? Qt.alpha("#0F1216", 0.85)
        : Qt.alpha("#FFFFFF", 0.85)
    property color borderColor: Theme.isDark()
        ? Qt.alpha("#000000", 0.36)
        : Qt.alpha("#000000", 0.14)

    // backend
    property var backend: null
    property var settings: null

    // properties
    property alias text: subtitleLabel.text
    property alias subtitle: subtitleArea.children
    property alias actions: actionButtons.children
    property alias backgroundArea: backgroundArea.children
    default property alias content: contentArea.data
    property real padding: miniMode ? 16 : 24

    // 背景
    readonly property real borderWidth: 1.5

    // 动画
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 400;
            easing.type: Easing.Bezier
            easing.bezierCurve: BezierCurve.liquidBack
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 400;
            easing.type: Easing.Bezier
            easing.bezierCurve: BezierCurve.liquidBack
        }
    }

    // 内部背景矩形
    Rectangle {
        id: background
        anchors.fill: parent
        radius: 8
        color: backgroundColor
        opacity: Configs.data.preferences.opacity
    }

    // 背景布局
    Item {
        id: backgroundArea
        anchors.fill: parent
    }

    // 主布局
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: miniMode ? 12 : 16
        anchors.bottomMargin: miniMode ? 10 : 18
        anchors.leftMargin: padding
        anchors.rightMargin: padding
        spacing: 8

        // 顶部 subtitle + actions
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            visible: opacity > 0
            opacity: !miniMode
            Behavior on opacity { NumberAnimation { duration: 100; easing.type: Easing.OutQuint } }

            RowLayout {
                id: subtitleArea
                Layout.fillHeight: true

                Subtitle {
                    id: subtitleLabel
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { id: actionsSeparator; Layout.fillWidth: actionButtons.children.length > 0 }

            RowLayout {
                id: actionButtons
                Layout.fillHeight: true
            }
        }

        // 内容区
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    HoverHandler {
        id: widgetHoverHandler
    }

    // 动画

    Behavior on backgroundColor {
        ColorAnimation {
            duration: 350
            easing.type: Easing.OutQuint
        }
    }
    Behavior on borderColor {
        ColorAnimation {
            duration: 250
            easing.type: Easing.OutQuint
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
}
