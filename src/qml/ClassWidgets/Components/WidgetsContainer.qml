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
    property bool floatingMode: hide
        && (Configs.data.interactions.tapped_action === "floating_widget"
            || Configs.data.interactions.hide.action === "floating_widget")
    property bool fullyHide: Configs.data.interactions.hide.fully_hide
    property var preferences: Configs.data.preferences

    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real hideMargin: {
        if (floatingMode) return 0  // 浮窗模式下完全移出窗口
        if (fullyHide) return 0  // 完全隐藏：不残留边缘小条
        switch (Qt.platform.os) {
            case "osx":
                return 48
            default:
                return 24
        }
    } // 隐藏时保留的可点击空间（非完全隐藏时）
    property bool isTopPosition: preferences.widgets_anchor.indexOf("top_") === 0
    property real hideFade: 0

    signal contentGeometryChanged()

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

    // Flow items can have different widths, so an index cannot be inferred
    // from a fixed item width. Compare the dragged item's center with the
    // centers of the other delegates instead.
    function dropIndex(draggedItem, fromIndex) {
        var draggedCenter = draggedItem.x + draggedItem.width / 2
        var targetIndex = 0

        for (var i = 0; i < widgetRepeater.count; ++i) {
            if (i === fromIndex)
                continue

            var item = widgetRepeater.itemAt(i)
            if (item && draggedCenter > item.x + item.width / 2)
                ++targetIndex
        }

        return targetIndex
    }

    // The window mask must follow the hide/show transition frame by frame.
    onXChanged: contentGeometryChanged()
    onYChanged: contentGeometryChanged()

    // 浮窗模式由 MainInterface 的独立容器接管显示。保留这里的坐标动画，
    // 使退出浮窗模式时普通小组件仍沿原有的边缘动画返回。

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
                    transformOrigin: Item.Center
                    // widgetContainer is sized to the scaled content while
                    // the loader keeps its native size. Offset the loader so
                    // its transform center stays at widgetContainer's center.
                    x: (widgetContainer.width - width) / 2
                    y: (widgetContainer.height - height) / 2
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
                    target: widgetContainer
                    property var originalX: parent.x
                    property var originalY: parent.y
                    onActiveChanged: {
                        if (active) {
                            originalX = widgetContainer.x
                            originalY = widgetContainer.y
                        }
                        if (!active) {
                            var from = index
                            var to = widgetsContainer.dropIndex(widgetContainer, from)
                            if (to !== from) {
                                WidgetsModel.moveInstance(from, to)
                            } else {
                                widgetContainer.x = originalX
                                widgetContainer.y = originalY
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
                                    "instanceId": model.instanceId,
                                    "widget_id": model.widget_id
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
                    loops: Animation.Infinite

                    NumberAnimation { to: rotationAnim.angle1; duration: 250; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: rotationAnim.angle2; duration: 250; easing.type: Easing.InOutQuad }

                    onRunningChanged: {
                        rotationAnim.angle1 = Math.random() * 2.0
                        rotationAnim.angle2 = -(Math.random() * 2.0)
                    }
                }

                // 入场动画
                SequentialAnimation {
                    id: anim
                    NumberAnimation { target: widgetContainer; property: "opacity"; from: 0; to: 0; duration: 1 }
                    PauseAnimation { duration: index * 125 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: widgetContainer
                            property: "opacity"
                            from: 0; to: 1; duration: 300
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: widgetContainer;
                            property: "scale";
                            from: 0.8; to: 1; duration: 400;
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
