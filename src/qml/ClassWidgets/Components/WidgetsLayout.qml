import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Easing
import "dialogs"
Item {
    id: layoutRoot

    objectName: "widgetsFlow"

    property bool editMode: false
    property string overlayEditingId: ""
    property bool dragging: false
    property bool hide: false
    property real scaleFactor: 1.0
    property real spacing: 8

    property real viewportWidth: 100000
    property real viewportHeight: 4096

    readonly property alias count: listView.count
    readonly property real contentWidth: listView.contentWidth
    property real contentHeight: 0

    width: contentWidth
    height: contentHeight
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    signal geometryChanged()
    signal editRequested()
    signal menuVisibilityChanged(bool visible)
    signal widgetTapped()

    function refreshContentHeight() {
        var tallest = 0
        for (var i = 0; i < listView.count; ++i) {
            var it = listView.itemAtIndex(i)
            if (it && it.visible && it.height > tallest)
                tallest = it.height
        }
        contentHeight = tallest
    }

    Timer {
        id: geometryCoalesce
        interval: 0
        repeat: false
        onTriggered: layoutRoot.geometryChanged()
    }

    function notifyGeometry() {
        geometryCoalesce.restart()
    }

    function restingWidths() {
        var widths = []
        for (var i = 0; i < listView.count; ++i) {
            var it = listView.itemAtIndex(i)
            if (it && it.widgetIndex >= 0 && it.widgetIndex < listView.count)
                widths[it.widgetIndex] = it.width
        }
        return widths
    }

    function dropIndexAt(centerX, fromIndex) {
        var widths = restingWidths()
        var x = 0
        var target = 0
        for (var i = 0; i < widths.length; ++i) {
            var w = widths[i] || 0
            if (i !== fromIndex && centerX > x + w / 2)
                ++target
            x += w
        }
        return target
    }

    function moveWidget(fromIndex, toIndex) {
        WidgetsModel.moveInstance(fromIndex, toIndex)
    }

    function removeWidget(instanceId) {
        WidgetsModel.removeInstance(instanceId)
        if (!editMode)
            WidgetsModel.save_config()
    }

    function itemAt(i) {
        return listView.itemAtIndex(i)
    }

    ListView {
        id: listView

        width: layoutRoot.viewportWidth
        height: layoutRoot.viewportHeight

        orientation: Qt.Horizontal
        spacing: 0
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        clip: false

        model: WidgetsModel

        move: Transition {
            enabled: !layoutRoot.dragging
            NumberAnimation {
                properties: "x,y"
                duration: 240
                easing.type: Easing.OutCubic
            }
        }
        addDisplaced: Transition { enabled: false }
        removeDisplaced: Transition { enabled: false }
        displaced: Transition {
            id: displacedTransition

            SequentialAnimation {
                PauseAnimation {
                    duration: layoutRoot.dragging ? 0 : 30
                }

                NumberAnimation {
                    properties: "x,y"
                    duration: layoutRoot.dragging ? 180 : 260
                    easing.type: Easing.OutCubic
                }
            }
        }

        delegate: WidgetsLayoutDelegate {
            host: layoutRoot
            overlayMemberDialog: overlayMemberDialogInstance
            settingsDialog: settingsDialogInstance
            onWidgetTapped: layoutRoot.widgetTapped()
        }

        onContentWidthChanged: {
            layoutRoot.notifyGeometry()
            layoutRoot.refreshContentHeight()
        }
        onCountChanged: layoutRoot.refreshContentHeight()
    }

    WidgetSettingsDialog {
        id: settingsDialogInstance
    }

    Loader {
        id: overlayMemberDialogInstance
        source: "dialogs/AddOverlayMemberDialog.qml"
        active: false
    }

    Component.onCompleted: refreshContentHeight()
}
