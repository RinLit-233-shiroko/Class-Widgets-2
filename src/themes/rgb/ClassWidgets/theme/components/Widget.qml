import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Theme
import ClassWidgets.Easing
import ClassWidgets.Theme.Material


Item {
    id: widgetBase
    // 最小宽度 = 内容 + 边距，默认可以被拉伸
    readonly property bool miniMode: Configs.data.preferences.mini_mode
    readonly property bool hide: Configs.data.interactions.hide.state
    property bool editMode: false
    property bool lightingEffect: false

    implicitWidth: Math.max(headerRow.implicitWidth, contentArea.childrenRect.width) + 48
    height: miniMode ? 56 : 100
    clip: true
    opacity: widgetHoverHandler.hovered? 0.8 : 1

    // RGB主题：颜色由效果引擎动态控制
    // 通过 ThemeManager.rgbColor 获取当前颜色
    property color rgbColor: ThemeManager ? ThemeManager.rgbColor : "#4099b2"
    property color backgroundColor: Qt.luma(rgbColor) > 0.5 
        ? Qt.darker(rgbColor, 3.0) 
        : Qt.lighter(rgbColor, 3.0)
    property color foregroundColor: Qt.luma(rgbColor) > 0.5 
        ? "#000000" 
        : "#ffffff"
    property color accentColor: rgbColor

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

    // 颜色平滑过渡动画
    Behavior on backgroundColor {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }

    Behavior on foregroundColor {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }

    Behavior on accentColor {
        ColorAnimation {
            duration: 300
            easing.type: Easing.Bezier
        }
    }

    // 背景圆角矩形
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: backgroundColor
        radius: 16
        border.width: borderWidth
        borderColor: Qt.alpha(foregroundColor, 0.1)

        // 发光效果
        layer.enabled: true
        layer.effect: Glow {
            radius: 8
            samples: 16
            color: Qt.alpha(accentColor, 0.3)
            source: backgroundRect
        }
    }

    // 内容布局
    RowLayout {
        id: headerRow
        anchors.fill: parent
        anchors.margins: padding
        spacing: 12

        // 图标区域
        Item {
            id: iconArea
            Layout.preferredWidth: miniMode ? 24 : 32
            Layout.preferredHeight: miniMode ? 24 : 32

            // 默认图标（可由子组件覆盖）
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: accentColor
                visible: iconArea.children.length <= 1
            }
        }

        // 文本区域
        ColumnLayout {
            id: subtitleArea
            Layout.fillWidth: true
            spacing: 2

            Text {
                id: subtitleLabel
                text: ""
                font.pixelSize: miniMode ? 14 : 16
                font.weight: Font.Medium
                color: foregroundColor
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // 操作按钮区域
        RowLayout {
            id: actionButtons
            spacing: 4
        }
    }

    // 内容区域
    Item {
        id: contentArea
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: padding / 2
    }

    // 悬停处理
    HoverHandler {
        id: widgetHoverHandler
    }
}
