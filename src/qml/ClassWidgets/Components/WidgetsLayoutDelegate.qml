import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Easing

Item {
    id: widgetContainer

    // ---- 由 WidgetsLayout 注入 ----
    property Item host: null
    property var settingsDialog: null

    property int widgetIndex: index
    property real spacing: host.spacing
    property string widgetInstanceId: (typeof model !== "undefined" && model)
                                       ? (model.instanceId || "") : ""

    // 是否处于「应该显示」的状态（用于出现/消失判定）
    readonly property bool contentHidden: loader.status === Loader.Ready
        && loader.item && loader.item.visible === false

    property real visualScale: host.scaleFactor
    Behavior on visualScale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    // ---- 尺寸 ----
    // naturalWidth/Height 是乘过 visualScale 的最终尺寸；
    // measuredWidth/Height 是未经缩放的原始尺寸，并且在内容隐藏期间保留。
    property real naturalWidth: 0
    property real naturalHeight: 0
    property real measuredWidth: 0
    property real measuredHeight: 0

    // 宽度因子：0 = 收起（不占位），1 = 展开
    property real growFactor: 0
    property bool ready: false
    // 是否正在合拢：用来给同一组动画选不同曲线，
    // 展开平滑铺开（OutCubic），合拢快速收闸（InCubic）避免慢尾。
    property bool collapsing: false

    // 删除期间由 removeAnim 显式驱动 growFactor，这里必须让开，
    // 否则两条动画会互相重定向，收宽度时机重新变得不可控。
    Behavior on growFactor {
        enabled: widgetContainer.ready && !widgetContainer.removing
        NumberAnimation {
            duration: widgetContainer.collapsing ? 240 : 420
            easing.type: widgetContainer.collapsing ? Easing.InCubic : Easing.OutCubic
        }
    }

    width: (naturalWidth + spacing) * growFactor
    height: naturalHeight

    property real visOpacity: 0
    property real visScale: 0.8
    property bool removing: false
    property bool initialized: false   // 入场只播一次，避免切主题重播

    opacity: (dragHandler.active ? 0.75 : 1) * visOpacity * containerFade
    scale: visScale * dragRaiseScale
    rotation: host.editMode ? shakeAngle : 0
    z: dragHandler.active ? 1 : 0

    // 拖拽被拿起
    property real dragRaiseScale: 1
    Behavior on dragRaiseScale {
        enabled: !dragHandler.active
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    // 编辑模式摇晃角度
    property real shakeAngle: 0

    // 容器整体隐藏时的视觉收缩
    property real containerFade: host.hide ? 0 : 1
    Behavior on containerFade {
        NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
    }

    function syncNaturalSize() {
        if (loader.loadFailed && !host.editMode) {
            naturalWidth = 0
            naturalHeight = 0
            measuredWidth = 0
            measuredHeight = 0
        } else if (loader.status === Loader.Ready) {
            if (!contentHidden && loader.width > 0) {
                measuredWidth = loader.width
                measuredHeight = loader.height
            } else if (measuredWidth <= 0) {
                measuredWidth = loader.width
                measuredHeight = loader.height
            }
            naturalWidth = measuredWidth * visualScale
            naturalHeight = measuredHeight * visualScale
        }
        host.refreshContentHeight()
        host.notifyGeometry()
    }

    onVisualScaleChanged: syncNaturalSize()
    onContentHiddenChanged: {
        syncNaturalSize()
        if (contentHidden)
            hide()
        else
            show()
    }

    // 出现
    function show() {
        if (removing)
            return
        exitAnim.stop()
        collapsing = false
        growFactor = 1
        if (ready)
            enterAnim.restart()
    }

    function hide() {
        if (removing)
            return
        enterAnim.stop()
        collapsing = true
        growFactor = 0
        if (ready)
            exitAnim.restart()
    }

    SequentialAnimation {
        id: enterAnim
        PauseAnimation { duration: Math.max(0, widgetContainer.widgetIndex) * 125 }
        ParallelAnimation {
            NumberAnimation {
                target: widgetContainer
                property: "visOpacity"
                from: 0; to: 1; duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: widgetContainer
                property: "visScale"
                from: 0.8; to: 1; duration: 400
                easing.type: Easing.Bezier
                easing.bezierCurve: BezierCurve.popBack
            }
        }
    }

    // 消失：只负责「自己隐藏」的视觉逆行程，绝不在这里移除模型行。
    // 与宽度合拢（走 growFactor 的 InCubic）保持一致的快节奏，收得干脆。
    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation {
                target: widgetContainer
                property: "visOpacity"
                from: 1; to: 0; duration: 240
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: widgetContainer
                property: "visScale"
                from: 1; to: 0.8; duration: 320
                easing.type: Easing.Bezier
                easing.bezierCurve: BezierCurve.popBackIn
            }
        }
    }

    // 删除
    function requestRemove() {
        if (removing)
            return
        removing = true

        enterAnim.stop()
        exitAnim.stop()

        if (!ready) {
            WidgetsModel.removeInstance(widgetInstanceId)
            return
        }

        if (growFactor <= 0.001) {
            WidgetsModel.removeInstance(widgetInstanceId)
            return
        }

        removeAnim.restart()
    }

    SequentialAnimation {
        id: removeAnim

        // 第一阶段：内容从「当前」状态淡出（不写 from，避免动画中途被删除时跳变）。
        // 此时宽度不动，邻居留在原地，所以不会重叠。
        ParallelAnimation {
            NumberAnimation {
                target: widgetContainer
                property: "visOpacity"
                to: 0; duration: 220
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: widgetContainer
                property: "visScale"
                to: 0.9; duration: 260
                easing.type: Easing.InCubic
            }
        }

        // 第二阶段：内容已不可见，再收起占位宽度让邻居平滑补位
        NumberAnimation {
            target: widgetContainer
            property: "growFactor"
            to: 0; duration: 380
            easing.type: Easing.OutCubic
        }

        // 第三阶段：宽度归零后才真正移除，ListView 重排时已无可见内容
        ScriptAction {
            script: WidgetsModel.removeInstance(widgetContainer.widgetInstanceId)
        }
    }

    // ---- 拖拽视觉偏移（不改 x/y，那是 ListView 的属性）----
    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real dragLift: 0          // 拿起时的上浮量
    property bool settleDrag: false

    Behavior on dragOffsetX {
        enabled: widgetContainer.settleDrag
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on dragOffsetY {
        enabled: widgetContainer.settleDrag
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on dragLift {
        enabled: !dragHandler.active
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    transform: Translate {
        x: widgetContainer.dragOffsetX
        y: widgetContainer.dragOffsetY + widgetContainer.dragLift
    }

    WidgetLoader {
        id: loader
        editMode: host.editMode
        transformOrigin: Item.Center
        scale: widgetContainer.visualScale  // 补漏掉的scale参

        onWidthChanged: widgetContainer.syncNaturalSize()
        onHeightChanged: widgetContainer.syncNaturalSize()
        onStatusChanged: widgetContainer.syncNaturalSize()

        // 宽度含右侧间距，居中时要排除
        x: (widgetContainer.naturalWidth * widgetContainer.growFactor - width) / 2
        y: (widgetContainer.height - height) / 2

        onContentLoaded: {
            widgetContainer.syncNaturalSize()
            widgetContainer.ready = true

            if (widgetContainer.removing)
                return                      // 正在删除，别播入场
            if (widgetContainer.initialized) {
                // 切主题重载：只补齐可见性，不重播动画
                widgetContainer.growFactor = widgetContainer.contentHidden ? 0 : 1
                widgetContainer.visOpacity = widgetContainer.contentHidden ? 0 : 1
                widgetContainer.visScale = widgetContainer.contentHidden ? 0.8 : 1
                return
            }
            widgetContainer.initialized = true

            if (widgetContainer.contentHidden)
                widgetContainer.hide()
            else
                widgetContainer.show()
        }
        onContentFailed: widgetContainer.syncNaturalSize()
        onRemovalRequested: widgetContainer.requestRemove()

        TapHandler {
            id: tapHandler
        }
    }

    // 组件自身显隐 / 尺寸变化（通知展开收起等）也要重算布局
    Connections {
        target: loader.item
        ignoreUnknownSignals: true

        function onVisibleChanged() { widgetContainer.syncNaturalSize() }
        function onWidthChanged()   { widgetContainer.syncNaturalSize() }
        function onHeightChanged()  { widgetContainer.syncNaturalSize() }
    }

    ToolButton {
        id: deleteBtn
        visible: host.editMode
        icon.name: "ic_fluent_line_horizontal_1_20_filled"
        size: 12
        width: 24
        height: 24
        anchors.top: parent.top
        anchors.left: parent.left
        onClicked: widgetContainer.requestRemove()
    }

    // ---- 编辑模式拖拽排序 ----
    DragHandler {
        id: dragHandler
        enabled: host.editMode
        target: null
        property real startOffsetX: 0
        property real startOffsetY: 0
        property bool moved: false

        onActiveChanged: {
            if (active) {
                settleDrag = false
                startOffsetX = widgetContainer.dragOffsetX
                startOffsetY = widgetContainer.dragOffsetY
                moved = false
                widgetContainer.dragRaiseScale = 1.08
                widgetContainer.dragLift = -6
                return
            }

            widgetContainer.dragRaiseScale = 1.0
            widgetContainer.dragLift = 0

            if (!moved) {
                settleDrag = true
                widgetContainer.dragOffsetX = 0
                widgetContainer.dragOffsetY = 0
                return
            }

            var from = widgetContainer.widgetIndex
            var to = host.dropIndex(widgetContainer, from)
            settleDrag = true
            widgetContainer.dragOffsetX = 0
            widgetContainer.dragOffsetY = 0
            if (to !== from)
                host.moveWidget(from, to)
        }

        onTranslationChanged: {
            if (!active)
                return
            if (Math.abs(translation.x) > 4 || Math.abs(translation.y) > 4)
                moved = true
            widgetContainer.dragOffsetX = startOffsetX + translation.x
            widgetContainer.dragOffsetY = startOffsetY + translation.y
        }
    }

    // ---- 右键菜单 ----
    Menu {
        id: widgetMenu
        onVisibleChanged: host.menuVisibilityChanged(visible)

        MenuItem {
            icon.name: "ic_fluent_info_20_regular"
            text: qsTr("Edit ") + "\"" + model.name + "\""
            onTriggered: {
                if (model.settingsQml) {
                    host.editRequested()
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
            onTriggered: widgetContainer.requestRemove()
        }
        MenuSeparator { visible: true }
        MenuItem {
            icon.name: "ic_fluent_column_edit_20_regular"
            text: qsTr("Edit Widgets Screen")
            onTriggered: host.editRequested()
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: (point, button) => {
            if (button === Qt.RightButton)
                widgetMenu.open()
        }
    }

    // ---- 编辑模式摇晃 ----
    SequentialAnimation on shakeAngle {
        running: host.editMode
        loops: Animation.Infinite
        NumberAnimation { to: 2;  duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { to: -2; duration: 250; easing.type: Easing.InOutQuad }
    }

    Component.onCompleted: syncNaturalSize()
}