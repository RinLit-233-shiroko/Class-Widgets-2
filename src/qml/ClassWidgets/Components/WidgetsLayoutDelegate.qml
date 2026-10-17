import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Easing

Item {
    id: widgetContainer

    property Item host: null
    property var settingsDialog: null
    property var overlayMemberDialog: null

    property int widgetIndex: index
    property real spacing: host.spacing
    property string widgetInstanceId: (typeof model !== "undefined" && model)
                                       ? (model.instanceId || "") : ""

    signal widgetTapped()

    readonly property bool contentHidden: loader.status === Loader.Ready
        && loader.item && loader.item.visible === false

    property real visualScale: host.scaleFactor
    Behavior on visualScale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    property real naturalWidth: 0
    property real naturalHeight: 0
    property real measuredWidth: 0
    property real measuredHeight: 0

    property real growFactor: 0
    property bool ready: false
    property bool collapsing: false

    Behavior on growFactor {
        enabled: widgetContainer.ready && !widgetContainer.removing
        NumberAnimation {
            duration: widgetContainer.collapsing ? 240 : 420
            easing.type: widgetContainer.collapsing ? Easing.InCubic : Easing.OutCubic
        }
    }

    width: (naturalWidth + spacing) * growFactor
    height: naturalHeight + (widgetContainer.overlayEditing ? editRow.height + 10 : 0)

    property real visOpacity: 0
    property real visScale: 0.8
    property bool removing: false
    property bool initialized: false
    property bool isOverlay: model.typeId === "classwidgets.overlay"
    property bool overlayEditing: isOverlay && host.overlayEditingId === model.instanceId

    opacity: (dragHandler.active ? 0.75 : 1) * visOpacity
    scale: visScale * dragRaiseScale
    rotation: (host.editMode && !widgetContainer.overlayEditing) ? shakeAngle : 0
    z: dragHandler.active ? 1 : 0

    property real dragRaiseScale: 1
    Behavior on dragRaiseScale {
        enabled: !dragHandler.active
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    property real shakeAngle: 0

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

    function requestRemove() {
        if (removing)
            return
        removing = true

        enterAnim.stop()
        exitAnim.stop()

        if (!ready) {
            host.removeWidget(widgetInstanceId)
            return
        }

        if (growFactor <= 0.001) {
            host.removeWidget(widgetInstanceId)
            return
        }

        removeAnim.restart()
    }

    SequentialAnimation {
        id: removeAnim

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

        NumberAnimation {
            target: widgetContainer
            property: "growFactor"
            to: 0; duration: 380
            easing.type: Easing.OutCubic
        }

        ScriptAction {
            script: host.removeWidget(widgetContainer.widgetInstanceId)
        }
    }

    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property real dragLift: 0
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

    onXChanged: if (dragHandler.active) dragHandler.pinToPointer()

    WidgetLoader {
        id: loader
        editMode: host.editMode
        transformOrigin: Item.Center
        scale: widgetContainer.visualScale

        onWidthChanged: widgetContainer.syncNaturalSize()
        onHeightChanged: widgetContainer.syncNaturalSize()
        onStatusChanged: widgetContainer.syncNaturalSize()

        x: (widgetContainer.naturalWidth * widgetContainer.growFactor - width) / 2
        y: (widgetContainer.height - height) / 2

        onContentLoaded: {
            widgetContainer.syncNaturalSize()
            widgetContainer.ready = true

            if (widgetContainer.removing)
                return
            if (widgetContainer.initialized) {
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
            acceptedButtons: Qt.LeftButton
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen | PointerDevice.TouchPad
            enabled: !host.editMode && Configs.data.interactions.hide.clicked
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onTapped: widgetContainer.widgetTapped()
        }
    }

    Connections {
        target: loader.item
        ignoreUnknownSignals: true

        function onVisibleChanged() { widgetContainer.syncNaturalSize() }
        function onWidthChanged()   { widgetContainer.syncNaturalSize() }
        function onHeightChanged()  { widgetContainer.syncNaturalSize() }
    }

    onOverlayEditingChanged: {
        if (widgetContainer.isOverlay && loader.item)
            loader.item.overlayListMode = widgetContainer.overlayEditing
    }

    RowLayout {
        id: editRow
        objectName: "editRow"
        visible: widgetContainer.overlayEditing
        anchors.top: loader.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: implicitWidth
        height: implicitHeight
        spacing: 8

        Button {
            id: addOverlayMemberButton
            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("Add Member")
            onClicked: {
                var dlg = widgetContainer.overlayMemberDialog
                if (dlg) {
                    dlg.active = true
                    if (dlg.item) {
                        dlg.item.overlayInstanceId = model.instanceId
                        dlg.item.open()
                    }
                }
            }
        }

        Button {
            id: acceptOverlayButton
            highlighted: true
            icon.name: "ic_fluent_checkmark_20_regular"
            text: qsTr("Done")
            onClicked: {
                host.editMode = false
                host.overlayEditingId = ""
            }
        }
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

    DragHandler {
        id: dragHandler
        enabled: host.editMode
        target: null

        property real anchorCenterX: 0
        property real anchorCenterY: 0

        function targetCenterX() {
            return anchorCenterX + dragHandler.translation.x
        }
        function targetCenterY() {
            return anchorCenterY + dragHandler.translation.y
        }

        function pinToPointer() {
            widgetContainer.dragOffsetX = targetCenterX()
                - (widgetContainer.x + widgetContainer.width / 2)
            widgetContainer.dragOffsetY = targetCenterY()
                - (widgetContainer.y + widgetContainer.height / 2)
        }

        onActiveChanged: {
            if (active) {
                settleDrag = false
                anchorCenterX = widgetContainer.x + widgetContainer.width / 2
                anchorCenterY = widgetContainer.y + widgetContainer.height / 2
                widgetContainer.dragRaiseScale = 1.08
                widgetContainer.dragLift = -6
                host.dragging = true
                return
            }

            host.dragging = false
            widgetContainer.dragRaiseScale = 1.0
            widgetContainer.dragLift = 0

            settleDrag = true
            widgetContainer.dragOffsetX = 0
            widgetContainer.dragOffsetY = 0
        }

        onTranslationChanged: {
            if (!active)
                return
            var to = host.dropIndexAt(targetCenterX(), widgetContainer.widgetIndex)
            if (to !== widgetContainer.widgetIndex)
                host.moveWidget(widgetContainer.widgetIndex, to)
            pinToPointer()
        }
    }

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
                    })
                    settingsDialog.open()
                }
            }
            enabled: model.settingsQml
        }
        MenuItem {
            visible: widgetContainer.isOverlay
            icon.name: "ic_fluent_layers_20_regular"
            text: qsTr("Edit Members")
            onTriggered: {
                widgetMenu.close()
                host.editRequested()
                host.overlayEditingId = model.instanceId
            }
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
        enabled: !widgetContainer.overlayEditing
        onTapped: (point, button) => {
            if (button === Qt.RightButton)
                widgetMenu.open()
        }
    }

    SequentialAnimation on shakeAngle {
        running: host.editMode && !widgetContainer.overlayEditing
        loops: Animation.Infinite
        NumberAnimation { to: 2;  duration: 250; easing.type: Easing.InOutQuad }
        NumberAnimation { to: -2; duration: 250; easing.type: Easing.InOutQuad }
    }

    Component.onCompleted: syncNaturalSize()
}
