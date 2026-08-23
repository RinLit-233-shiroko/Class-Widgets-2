import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import RinUI
import ClassWidgets.Easing


Item {
    id: widgetsContainer
    property real scaleFactor: Configs.data.preferences.scale_factor || 1.0
    property real spacing: 8

    property bool editMode: false
    property bool menuVisible: false
    property bool hide: {
        return Configs.data.interactions.hide.state
    }
    property var preferences: Configs.data.preferences

    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real hideMargin: 24  // 隐藏时保留的可点击空间
    signal contentGeometryChanged()

    width: editMode ? parent.width : widgetsFlow.implicitWidth
    height: editMode
                ? flickable.height + (horizontalScrollBar.visible ? horizontalScrollBar.height : 0)
                    + editButtons.anchors.topMargin + editButtons.height
        : widgetsFlow.implicitHeight

    onEditModeChanged: contentGeometryChanged()

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

    DragHandler {
        id: containerDragHandler
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


    Flickable {
        id: flickable
        objectName: "widgetsFlickable"
        anchors.left: parent.left
        anchors.top: parent.top
        width: editMode ? parent.width : widgetsFlow.implicitWidth
        height: widgetsFlow.implicitHeight
        contentWidth: Math.max(widgetsFlow.implicitWidth, width)
        contentHeight: widgetsFlow.implicitHeight
        clip: true
        interactive: widgetsContainer.editMode && contentWidth > width
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.horizontal: ScrollBar {
            id: horizontalScrollBar
            objectName: "widgetsHorizontalScrollBar"
            height: 12
            visible: widgetsContainer.editMode && flickable.contentWidth > flickable.width
            policy: widgetsContainer.editMode && flickable.contentWidth > flickable.width
                        ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }

        Row {
            id: widgetsFlow
            objectName: "widgetsFlow"
            x: widgetsFlow.implicitWidth < flickable.width
                ? (flickable.width - widgetsFlow.implicitWidth) / 2 : 0
            spacing: widgetsContainer.spacing
            height: implicitHeight

            Repeater {
                id: widgetRepeater
                model: WidgetsModel

                delegate: Item {
            id: widgetContainer
            property real visualScale: scaleFactor
            width: loader.width * visualScale
            height: loader.height * visualScale
            rotation: editMode
            z: widgetDragHandler.active ? 1 : 0
            opacity: widgetDragHandler.active ? 0.5 : 1

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
                id: widgetDragHandler
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
                        var to = Math.round(widgetContainer.x / (widgetContainer.width + widgetsContainer.spacing))
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
                loops: Animation.Infinite

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
    }

    // 添加小组件&完成
    Row {
        objectName: "addWidgetsContainer"
        id: editButtons
        visible: widgetsContainer.editMode
        anchors.top: flickable.bottom
        anchors.topMargin: 18
        anchors.horizontalCenter: parent.horizontalCenter
        width: 222
        height: visible ? 44 : 0
        spacing: 12
        z: 100
        opacity: 1
        clip: false

        Button {
            id: addWidgetButton
            // highlighted: true
            width: 100
            height: 40
            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("Add")

            onClicked: {
                widgetsContainer.editMode = true
                addDialog.open()
            }
        }

        Button {
            visible: widgetsContainer.editMode
            id: acceptButton
            highlighted: true
            width: 110
            height: 40
            icon.name: "ic_fluent_checkmark_20_regular"
            text: qsTr("Done")

            onClicked: {
                widgetsContainer.editMode = false
            }
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
