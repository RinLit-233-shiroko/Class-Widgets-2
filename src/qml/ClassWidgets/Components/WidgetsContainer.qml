import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Easing


Column {
    id: widgetsContainer
    property real scaleFactor: Configs.data.preferences.scale_factor || 1.0
    spacing: 8

    property bool editMode: false
    property bool menuVisible: false
    property bool hide: {
        return Configs.data.interactions.hide.state
    }
    property var preferences: Configs.data.preferences

    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real hideMargin: {
        switch (Qt.platform.os) {
            case "osx":
                return 48
            default:
                return 24
        }
    } // 隐藏时保留的可点击空间
    property bool isTopPosition: preferences.widgets_anchor.indexOf("top_") === 0
    property real hideFade: 0

    // 超宽自适应：编辑模式下若整体宽度超出屏幕，自动等比缩小并提示
    readonly property real availWidth: Math.max(240, Screen.width - 16)
    readonly property real overflowScale: width > availWidth ? availWidth / width : 1.0
    readonly property bool overflows: editMode && width > availWidth
    scale: editMode ? overflowScale : 1.0
    transformOrigin: Item.TopLeft

    signal contentGeometryChanged()

    // 超宽提示条：仅在编辑模式且超宽时显示（字号/高度按缩放补偿，保持视觉大小不变）
    Rectangle {
        visible: widgetsContainer.editMode && widgetsContainer.overflows
        width: parent.width
        height: 30 / widgetsContainer.overflowScale
        radius: 8
        color: "#CC1F2937"
        border.color: "#66FFC107"
        Text {
            anchors.centerIn: parent
            text: "⚠ 当前布局可能已超出屏幕宽度，建议减少组件数量"
            color: "#FFE082"
            font.pixelSize: 12 / widgetsContainer.overflowScale
        }
    }

    Behavior on hideFade {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutQuad
        }
    }

    layer.enabled: Qt.platform.os === "osx" && isTopPosition
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: widgetsContainer.width
            height: widgetsContainer.height
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0; color: Qt.alpha("white", 1.0 - hideFade) }
                GradientStop { position: 0.75; color: Qt.alpha("white", 1.0 - hideFade * 0.95) }
                GradientStop { position: 0.95; color: "white" }
            }
        }
    }

    onHideChanged: hideFade = hide ? 1.0 : 0.0

    // 编辑按钮高度：与首个小组件对齐，无小组件时回退默认值
    // property real buttonHeight: widgetRepeater.count > 0
    //     ? widgetRepeater.itemAt(0).height
    //     : 100 * scaleFactor

    Component.onCompleted: {
        editMode = widgetRepeater.count === 0
    }

    // 计算 X 坐标
    function calcX() {
        let x = 0
        switch (preferences.widgets_anchor) {
        case "top_left":
        case "bottom_left":
            x = preferences.widgets_offset_x
            if (hide) x = - width + hideMargin
            break
        case "top_center":
        case "bottom_center":
            x = (parent.width - width) / 2 + preferences.widgets_offset_x
            break
        case "top_right":
        case "bottom_right":
            x = parent.width - width - preferences.widgets_offset_x
            if (hide) x = parent.width - hideMargin
            break
        }
        // 编辑模式：整体居中并限制在屏幕内，避免两端组件被裁掉无法辨认
        if (editMode) {
            x = Math.max(8, (parent.width - width * overflowScale) / 2)
        }
        return x
    }

    // 计算 Y 坐标
    function calcY() {
        let y = 0
        switch (preferences.widgets_anchor) {
        case "top_left":
        case "top_right":
            if (editMode) {
                y = (Screen.height - height) / 2
            } else {
                y = preferences.widgets_offset_y
                // 左/右不受 hide 影响
            }
            break
        case "top_center":
            if (editMode) {
                y = (Screen.height - height) / 2
            } else {
                y = preferences.widgets_offset_y
                if (hide) y = -height + hideMargin  // 仅 center 生效
            }
            break
        case "bottom_left":
        case "bottom_right":
            y = parent.height - height - preferences.widgets_offset_y
            // 左/右不受 hide 影响
            break
        case "bottom_center":
            y = parent.height - height - preferences.widgets_offset_y
            if (hide) y = parent.height - hideMargin // 仅 center 生效
            break
        }

        return y
    }

    x: calcX() + dragOffsetX
    y: calcY() + dragOffsetY

    DragHandler {
        id: dragHandler
        enabled: !editMode
        target: null
        onActiveChanged: {
            if (!active) {
                dragOffsetX = 0
                dragOffsetY = 0
            }
        }
        onTranslationChanged: {
            if (active) {
                function damped(value, max, factor) {
                    return max * (1 - Math.exp(-Math.abs(value)/factor)) * Math.sign(value)
                }

                dragOffsetX = damped(translation.x, 8, 100)  // factor
                dragOffsetY = damped(translation.y, 6, 100)
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Flow {
        id: widgetsFlow
        objectName: "widgetsFlow"
        spacing: 8

        move: Transition {
            enabled: editMode
            NumberAnimation {
                properties: "x,y"
                duration: 300
                easing.type: Easing.OutQuint
            }
        }

        Repeater {
            id: widgetRepeater
            model: WidgetsModel

            delegate: Item {
                id: widgetContainer
                property real visualScale: scaleFactor
                width: loader.width * visualScale
                height: loader.height * visualScale
                rotation: editMode
                z: dragHandler.active ? 1 : 0
                opacity: dragHandler.active ? 0.5 : 1

                Behavior on visualScale {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                WidgetLoader {
                    id: loader
                    transformOrigin: Item.TopLeft
                    scale: tapHandler.pressed ? visualScale * 0.975 : visualScale
                    onWidthChanged: widgetsContainer.contentGeometryChanged()
                    onHeightChanged: widgetsContainer.contentGeometryChanged()

                    TapHandler {
                        id: tapHandler
                    }

                    Behavior on scale {
                        enabled: tapHandler.pressed
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.Bezier
                            easing.bezierCurve: BezierCurve.liquidBack
                        }
                    }

                }

                ToolButton {
                    id: deleteBtn
                    visible: widgetsContainer.editMode
                    icon.name: "ic_fluent_line_horizontal_1_20_filled"
                    size: 12
                    width: 24
                    height: 24
                    anchors.top: parent.top
                    anchors.left: parent.left
                    onClicked: WidgetsModel.removeInstance(model.instanceId)
                }

                // 拖拽
                DragHandler {
                    id: dragHandler
                    enabled: widgetsContainer.editMode
                    property var originalX: parent.x
                    property var originalY: parent.y
                    onActiveChanged: {
                        if (active) {
                            originalX = parent.x
                            originalY = parent.y
                        }
                        if (!active) {
                            var from = index
                            var to = Math.round(widgetContainer.x / (widgetContainer.width + widgetsFlow.spacing))
                            if (to < 0) to = 0
                            if (to >= widgetRepeater.count) to = widgetRepeater.count - 1
                            if (to !== from) {
                                WidgetsModel.moveInstance(from, to)
                            } else {
                                x = originalX
                                y = originalY
                            }
                        }
                    }
                }

                // 右键菜单
                Menu {
                    id: widgetMenu
                    onVisibleChanged: widgetsContainer.menuVisible = visible;
                    MenuItem {
                        icon.name: "ic_fluent_info_20_regular"
                        text: qsTr("Edit ") + "\"" + model.name + "\""
                        onTriggered: {
                            if (model.settingsQml) {
                                widgetsContainer.editMode = true
                                settingsDialog.setSource(model.settingsQml, {
                                    "settings": model.settings,
                                    "instanceId": model.instanceId
                                })
                                settingsDialog.open()
                            }
                        }
                        enabled: model.settingsQml
                    }
                    MenuItem {
                        icon.name: "ic_fluent_delete_20_regular"
                        text: qsTr("Delete")
                        onTriggered: {
                            // widgetsContainer.editMode = true
                            WidgetsModel.removeInstance(model.instanceId)
                        }
                    }
                    MenuSeparator { visible: true }
                    MenuItem {
                        icon.name: "ic_fluent_column_edit_20_regular"
                        text: qsTr("Edit Widgets Screen")
                        onTriggered: widgetsContainer.editMode = true
                    }
                }

                // 鼠标右键打开设置
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: (point, button) => {
                        if (button === Qt.RightButton) {
                            widgetMenu.open()
                        }
                    }
                }

                // 动画
                SequentialAnimation on rotation {
                    id: rotationAnim
                    property real angle1: 2.0
                    property real angle2: -2.0
                    running: editMode
                    loops: 3

                    NumberAnimation { to: rotationAnim.angle1; duration: 125; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: rotationAnim.angle2; duration: 125; easing.type: Easing.InOutQuad }

                    onRunningChanged: {
                        rotationAnim.angle1 = Math.random() * 2.0
                        rotationAnim.angle2 = -(Math.random() * 2.0)
                    }
                }

                // 入场动画
                SequentialAnimation {
                    id: anim
                    NumberAnimation { target: widgetContainer; property: "opacity"; from: 0; to: 0; duration: 1 }
                    PauseAnimation { duration: Math.min(index * 20, 100) }
                    ParallelAnimation {
                        NumberAnimation {
                            target: widgetContainer
                            property: "opacity"
                            from: 0; to: 1; duration: 200
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: widgetContainer;
                            property: "scale";
                            from: 0.9; to: 1; duration: 250;
                            easing.type: Easing.OutBack
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 100 }
                }
            }
        }
    }

    // 添加小组件&完成
    RowLayout {
        id: addWidgetsContainer
        objectName: "addWidgetsContainer"
        visible: widgetsContainer.editMode || widgetRepeater.count === 0
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4

        Button {
            id: addWidgetButton
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 40

            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("Add")

            onClicked: {
                widgetsContainer.editMode = true
                addDialog.open()
            }
        }

        Button {
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignCenter

            visible: widgetsContainer.editMode
            id: acceptButton
            highlighted: true
            icon.name: "ic_fluent_checkmark_20_regular"
            onClicked: widgetsContainer.editMode = false
        }
    }

    // 添加小组件窗口
    AddWidgetsDialog {
        id: addDialog
    }

    // 小组件设置窗口
    WidgetSettingsDialog {
        id: settingsDialog
    }
}
