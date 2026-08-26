import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Theme 1.0
import ClassWidgets.Easing


Item {
    id: widgetBase
    readonly property bool miniMode: Configs.data.preferences.mini_mode
    readonly property bool hide: Configs.data.interactions.hide.state
    property bool editMode: false
    property bool lightingEffect: Configs.data.preferences.lighting_effect || true

    implicitWidth: Math.max(headerRow.implicitWidth, contentArea.childrenRect.width) + 48
    height: miniMode ? 56 : 100
    opacity: widgetHoverHandler.hovered? 0.8 : 1

    // RGB主题：动态颜色
    property color rgbColor: Theme.isDark() ? "#4099b2" : "#4099b2"
    property color backgroundColor: Qt.luma(rgbColor) > 0.5
        ? Qt.darker(rgbColor, 2.5)
        : Qt.lighter(rgbColor, 2.5)
    property color textColor: Qt.luma(rgbColor) > 0.5 ? "#000000" : "#ffffff"

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
    property real cornerRadius: Configs.data.preferences.widget_corner_radius

    // 背景
    readonly property real borderWidth: 1

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

    // 颜色过渡动画
    Behavior on rgbColor {
        ColorAnimation { duration: 300 }
    }

    // 内部背景矩形
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Math.min(width, height, widgetBase.cornerRadius)
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
                }
            }

            Item { id: actionsSeparator; Layout.fillWidth: actionButtons.children.length > 0 }

            RowLayout {
                id: actionButtons
                Layout.fillHeight: true
            }
        }

        // 内容区域
        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    // 悬停处理
    HoverHandler {
        id: widgetHoverHandler
    }
}
