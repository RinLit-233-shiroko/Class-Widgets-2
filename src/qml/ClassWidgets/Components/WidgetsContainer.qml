import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Easing


Item {
    id: widgetsContainer
    objectName: "widgetsLoader"

    property real scaleFactor: Configs.data.preferences.scale_factor || 1.0
    property real spacing: 8

    property bool editMode: false
    property bool menuVisible: false
    property bool hide: Configs.data.interactions.hide.state
    property bool floatingMode: hide
        && (Configs.data.interactions.tapped_action === "floating_widget"
            || Configs.data.interactions.hide.action === "floating_widget")
    property var preferences: Configs.data.preferences

    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property bool settleContainerDrag: false
    property real hideMargin: {
        if (floatingMode) return 0
        return Qt.platform.os === "osx" ? 48 : 24
    }
    property bool isTopPosition: preferences.widgets_anchor.indexOf("top_") === 0
    property real hideFade: 0

    signal contentGeometryChanged()
    signal widgetTapped()

    // 「添加」按钮行固定高度，避免与父级高度形成绑定环
    readonly property int addRowHeight: 40

    implicitWidth: Math.max(widgetsLayout.implicitWidth,
                            addWidgetsContainer.visible ? addWidgetsContainer.width : 0)
    implicitHeight: widgetsLayout.implicitHeight
                    + (addWidgetsContainer.visible ? addRowHeight + spacing : 0)

    width: implicitWidth
    height: implicitHeight

    Behavior on hideFade {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
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

    // ============================================================
    //  离散状态进度：只有这两个属性挂动画
    // ============================================================

    // 直接绑定而非在 onXxxChanged 里赋值：后者在启动时不会触发，
    // 会导致初始就处于隐藏状态时完全没有过渡（甚至位置不对）。
    // 编辑模式优先于隐藏：隐藏状态下进入编辑时先回到正常/居中位置，
    // 退出编辑后 hide 仍为真，再滑回隐藏位置。
    property real hideProgress: (hide && !editMode) ? 1 : 0
    property real editProgress: editMode ? 1 : 0

    onHideChanged: hideFade = hide ? 1.0 : 0.0

    Component.onCompleted: editMode = widgetsLayout.count === 0

    Behavior on hideProgress {
        NumberAnimation { duration: 420; easing.type: Easing.OutQuint }
    }
    Behavior on editProgress {
        NumberAnimation { duration: 450; easing.type: Easing.OutQuint }
    }

    // ============================================================
    //  位置：纯绑定，随宽度/高度逐帧变化
    // ============================================================

    readonly property string anchorMode: preferences.widgets_anchor

    // 正常显示位置
    readonly property real shownX: {
        switch (anchorMode) {
        case "top_left":
        case "bottom_left":
            return preferences.widgets_offset_x
        case "top_center":
        case "bottom_center":
            return (parent.width - width) / 2 + preferences.widgets_offset_x
        case "top_right":
        case "bottom_right":
            return parent.width - width - preferences.widgets_offset_x
        }
        return 0
    }

    readonly property real shownY: {
        switch (anchorMode) {
        case "top_left":
        case "top_right":
        case "top_center":
            return preferences.widgets_offset_y
        case "bottom_left":
        case "bottom_right":
        case "bottom_center":
            return parent.height - height - preferences.widgets_offset_y
        }
        return 0
    }

    // 隐藏位置（左/右锚点的 Y、以及编辑模式不受隐藏影响）
    readonly property real hiddenX: {
        switch (anchorMode) {
        case "top_left":
        case "bottom_left":
            return -width + hideMargin
        case "top_center":
        case "bottom_center":
            return shownX          // 居中锚点不横向隐藏
        case "top_right":
        case "bottom_right":
            return parent.width - hideMargin
        }
        return shownX
    }

    readonly property real hiddenY: {
        switch (anchorMode) {
        case "top_center":
            return -height + hideMargin
        case "bottom_center":
            return parent.height - hideMargin
        }
        return shownY              // 左/右锚点不纵向隐藏
    }

    // 编辑模式位置：仅顶部锚点会垂直居中
    readonly property real editY: {
        switch (anchorMode) {
        case "top_left":
        case "top_right":
        case "top_center":
            return (Screen.height - height) / 2
        }
        return shownY
    }

    // x：正常位置 → 隐藏位置，按 hideProgress 混合
    x: shownX + (hiddenX - shownX) * hideProgress + dragOffsetX

    // y：先按 editProgress 混到编辑位置，再按 hideProgress 混到隐藏位置
    y: {
        var visibleY = shownY + (editY - shownY) * editProgress
        return visibleY + (hiddenY - visibleY) * hideProgress + dragOffsetY
    }

    onXChanged: contentGeometryChanged()
    onYChanged: contentGeometryChanged()
    onWidthChanged: contentGeometryChanged()
    onHeightChanged: contentGeometryChanged()

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    Behavior on dragOffsetX {
        enabled: widgetsContainer.settleContainerDrag
        NumberAnimation { duration: 460; easing.type: Easing.OutBack }
    }
    Behavior on dragOffsetY {
        enabled: widgetsContainer.settleContainerDrag
        NumberAnimation { duration: 460; easing.type: Easing.OutBack }
    }

    DragHandler {
        id: containerDragHandler
        enabled: !editMode
        target: null
        onActiveChanged: {
            if (!active) {
                settleContainerDrag = true
                dragOffsetX = 0
                dragOffsetY = 0
                return
            }
            settleContainerDrag = false
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

    WidgetsLayout {
        id: widgetsLayout
        editMode: widgetsContainer.editMode
        hide: widgetsContainer.hide
        scaleFactor: widgetsContainer.scaleFactor
        spacing: widgetsContainer.spacing
        // 水平视口足够大，保证所有 delegate 都被实例化而不被回收
        viewportWidth: 100000

        onGeometryChanged: widgetsContainer.contentGeometryChanged()
        onEditRequested: widgetsContainer.editMode = true
        onMenuVisibilityChanged: (visible) => widgetsContainer.menuVisible = visible
        onWidgetTapped: widgetsContainer.widgetTapped()
    }

    // 添加小组件&完成
    RowLayout {
        id: addWidgetsContainer
        objectName: "addWidgetsContainer"
        anchors.top: widgetsLayout.bottom
        anchors.topMargin: addWidgetsContainer.visible ? widgetsContainer.spacing : 0
        anchors.horizontalCenter: parent.horizontalCenter
        visible: widgetsContainer.editMode || widgetsLayout.count === 0
        spacing: 4

        Button {
            id: addWidgetButton
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: widgetsContainer.addRowHeight

            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("Add")

            onClicked: {
                widgetsContainer.editMode = true
                addDialog.open()
            }
        }

        Button {
            Layout.preferredHeight: widgetsContainer.addRowHeight
            Layout.alignment: Qt.AlignCenter

            visible: widgetsContainer.editMode
            id: acceptButton
            highlighted: true
            icon.name: "ic_fluent_checkmark_20_regular"
            onClicked: {
                WidgetsModel.save_config()
                widgetsContainer.editMode = false
            }
        }
    }

    AddWidgetsDialog {
        id: addDialog
    }
}
