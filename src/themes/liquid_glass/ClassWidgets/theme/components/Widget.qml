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

    implicitWidth: Math.max(headerRow.implicitWidth, contentArea.childrenRect.width) + 52
    height: miniMode ? 56 : 104
    opacity: widgetHoverHandler.hovered ? 0.94 : 1

    // 标准档强调轻量与可读性；增强档提供更深的投影、更明显的色彩层次和更强流光。
    readonly property bool enhancedGlass: Configs.data.preferences.liquid_glass_effect === "enhanced"
    property color glassBase: Theme.isDark() ? "#223348" : "#dff3ff"
    property color glassTint: Theme.isDark() ? "#496d8a" : "#80d7ff"
    property color glassBorder: Theme.isDark() ? "#a8dbff" : "#ffffff"
    property color textTint: Theme.isDark() ? "#e5f6ff" : "#18334a"
    readonly property real glassShadowRadius: enhancedGlass ? 34 : 22
    readonly property real glassShadowOffset: enhancedGlass ? 11 : 8
    readonly property real glassSheenOpacity: enhancedGlass ? 0.52 : 0.32

    property var backend: null
    property var settings: null

    property alias text: subtitleLabel.text
    property alias subtitle: subtitleArea.children
    property alias actions: actionButtons.children
    property alias backgroundArea: backgroundArea.children
    default property alias content: contentArea.data
    property real padding: miniMode ? 16 : 24
    property real cornerRadius: Math.min(width, height, Math.max(18, Configs.data.preferences.widget_corner_radius))
    readonly property real borderWidth: 1

    Behavior on implicitWidth {
        NumberAnimation { duration: 420; easing.type: Easing.Bezier; easing.bezierCurve: BezierCurve.liquidBack }
    }
    Behavior on height {
        NumberAnimation { duration: 420; easing.type: Easing.Bezier; easing.bezierCurve: BezierCurve.liquidBack }
    }

    Rectangle {
        id: glassShadowSource
        anchors.fill: parent
        radius: widgetBase.cornerRadius
        color: "#000000"
        visible: false
    }

    DropShadow {
        anchors.fill: glassShadowSource
        source: glassShadowSource
        horizontalOffset: 0
        verticalOffset: widgetBase.glassShadowOffset
        radius: widgetBase.glassShadowRadius
        samples: widgetBase.enhancedGlass ? 49 : 33
        color: Theme.isDark()
               ? (widgetBase.enhancedGlass ? "#bb000000" : "#99000000")
               : (widgetBase.enhancedGlass ? "#554078a5" : "#33235d7d")
        opacity: Configs.data.preferences.opacity
    }

    Rectangle {
        id: glassSurface
        anchors.fill: parent
        radius: widgetBase.cornerRadius
        opacity: Configs.data.preferences.opacity
        border.width: widgetBase.borderWidth
        border.color: Qt.alpha(widgetBase.glassBorder,
                               widgetBase.enhancedGlass ? (Theme.isDark() ? 0.58 : 0.94)
                                                         : (Theme.isDark() ? 0.38 : 0.72))
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(widgetBase.glassBase,
                                                            widgetBase.enhancedGlass ? (Theme.isDark() ? 0.78 : 0.82)
                                                                                      : (Theme.isDark() ? 0.72 : 0.72)) }
            GradientStop { position: 0.48; color: Qt.alpha(widgetBase.glassTint,
                                                            widgetBase.enhancedGlass ? (Theme.isDark() ? 0.50 : 0.58)
                                                                                      : (Theme.isDark() ? 0.26 : 0.32)) }
            GradientStop { position: 1.0; color: Qt.alpha(widgetBase.glassBase,
                                                            widgetBase.enhancedGlass ? (Theme.isDark() ? 0.68 : 0.62)
                                                                                      : (Theme.isDark() ? 0.60 : 0.52)) }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: "transparent"
            border.width: 1
            border.color: Qt.alpha("#ffffff", Theme.isDark() ? 0.12 : 0.48)
        }

        Rectangle {
            id: sheen
            width: parent.width * (widgetBase.enhancedGlass ? 0.62 : 0.45)
            height: parent.height * 1.8
            x: -width
            y: -parent.height * 0.4
            rotation: 18
            opacity: widgetHoverHandler.hovered
                     ? widgetBase.glassSheenOpacity
                     : widgetBase.glassSheenOpacity * 0.55
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00ffffff" }
                GradientStop { position: 0.48; color: widgetBase.enhancedGlass ? "#d6ffffff" : "#85ffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
            Behavior on opacity { NumberAnimation { duration: 220 } }

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: !widgetBase.miniMode
                NumberAnimation { from: -sheen.width; to: glassSurface.width; duration: widgetBase.enhancedGlass ? 2800 : 4200; easing.type: Easing.InOutSine }
                PauseAnimation { duration: widgetBase.enhancedGlass ? 900 : 1500 }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 2
            height: Math.max(12, parent.height * 0.23)
            radius: Math.max(0, parent.radius - 2)
            opacity: widgetBase.enhancedGlass
                     ? (Theme.isDark() ? 0.28 : 0.48)
                     : (Theme.isDark() ? 0.16 : 0.30)
            gradient: Gradient {
                GradientStop { position: 0; color: "#bfffffff" }
                GradientStop { position: 1; color: "#00ffffff" }
            }
        }
    }

    Item {
        id: backgroundArea
        anchors.fill: parent
        z: 1
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.topMargin: miniMode ? 12 : 16
        anchors.bottomMargin: miniMode ? 10 : 18
        anchors.leftMargin: padding
        anchors.rightMargin: padding
        spacing: 8
        z: 2

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
                    color: widgetBase.textTint
                }
            }

            Item { id: actionsSeparator; Layout.fillWidth: actionButtons.children.length > 0 }
            RowLayout { id: actionButtons; Layout.fillHeight: true }
        }

        Item {
            id: contentArea
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    HoverHandler { id: widgetHoverHandler }

    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
}
