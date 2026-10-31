import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Components
import "../ZoomMath.js" as ZoomMath

Item {
    id: root

    property var entries: []
    property var subjects: []
    property bool expanded: false
    property bool interactionEnabled: false
    property bool readOnlyTimeline: false
    property real visualProgress: 0
    property real pxPerMinute: 0.5
    property real overviewScale: 0.25
    readonly property real overviewMinimumZoom: Math.max(0.25,
        Math.min(2.1, overviewScale))
    readonly property real minimumZoom: Math.max(1.5, overviewMinimumZoom)
    readonly property real maximumZoom: 4.4 - overviewMinimumZoom
    property real sceneContentX: 0
    property bool layoutControlled: false
    property bool detailsVisible: false
    property string selectedEntryId: ""
    property bool axisHovered: false
    property bool compactLayout: false
    property bool draggingEntry: false
    property bool pinching: false
    property bool dropPreviewActive: false
    property string dropPreviewEntryId: ""
    property real dropPreviewStart: -1
    property real dropPreviewEnd: -1
    property bool dropPreviewValid: true
    property real dragPointerSceneX: -1
    readonly property bool detailOpen: {
        for (let i = 0; i < entryRepeater.count; ++i) {
            const card = entryRepeater.itemAt(i)
            if (card && card.detailOpen)
                return true
        }
        return false
    }
    readonly property real autoScrollEdge: 54
    readonly property real autoScrollPixelsPerTick: 14
    readonly property bool autoScrollActive: {
        if (!draggingEntry || dragPointerSceneX < 0)
            return false
        const x = localDragPointerX()
        return x >= 0 && (x < autoScrollEdge
            || x > horizontalFlick.width - autoScrollEdge)
    }
    property real scaleAnchorMinute: -1
    property real scaleAnchorPixel: 0
    property bool scaleAnchorLocked: false
    // The axis is a rounded viewport, not just a rounded background. Keep the
    // long 24-hour content from painting through the row's corners.
    readonly property real cornerRadius: 4

    readonly property real axisWidth: horizontalFlick.width
    readonly property real axisContentX: horizontalFlick.contentX

    clip: true
    layer.enabled: visible && width > 0 && height > 0
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: root.width
            height: root.height
            radius: root.cornerRadius
            color: "white"
            antialiasing: true
        }
    }

    signal entrySelected(string entryId, int index)
    signal selectionCleared()
    signal pinchZoomRequested(real value, real anchorMinute, real anchorPixel)
    signal pinchZoomFinished()

    function showDropPreview(entryId, startMinute, endMinute, valid) {
        dropPreviewEntryId = String(entryId)
        dropPreviewStart = startMinute
        dropPreviewEnd = endMinute
        dropPreviewValid = valid
        dropPreviewActive = endMinute > startMinute
    }

    function clearDropPreview(entryId) {
        if (String(entryId) !== dropPreviewEntryId)
            return
        dropPreviewActive = false
        dropPreviewEntryId = ""
        dropPreviewStart = -1
        dropPreviewEnd = -1
        dropPreviewValid = true
    }

    function updateDragPointer(entryId, sceneX) {
        dropPreviewEntryId = String(entryId)
        dragPointerSceneX = sceneX
    }

    function localDragPointerX() {
        if (dragPointerSceneX < 0)
            return -1
        return horizontalFlick.mapFromItem(null, dragPointerSceneX, 0).x
    }

    function applyAutoScrollDelta(delta) {
        const maximum = Math.max(0,
            horizontalFlick.contentWidth - horizontalFlick.width)
        if (maximum <= 0)
            return 0
        const before = horizontalFlick.contentX
        horizontalFlick.contentX = Math.max(0,
            Math.min(maximum, before + delta))
        return horizontalFlick.contentX - before
    }

    function notifyAutoScroll(delta) {
        if (delta === 0)
            return
        for (let i = 0; i < entryRepeater.count; ++i) {
            const card = entryRepeater.itemAt(i)
            if (card && card.manipulationMode
                    && String(card.entry.id) === dropPreviewEntryId)
                card.applyAutoScrollDelta(delta)
        }
    }

    function cancelCardTouchGestures() {
        for (let i = 0; i < entryRepeater.count; ++i) {
            const card = entryRepeater.itemAt(i)
            if (card && card.cancelTouchGesture)
                card.cancelTouchGesture()
        }
    }

    function clearDragState() {
        draggingEntry = false
        dragPointerSceneX = -1
        dropPreviewActive = false
        dropPreviewEntryId = ""
        dropPreviewStart = -1
        dropPreviewEnd = -1
        dropPreviewValid = true
    }

    function hasActiveEntryManipulation() {
        for (let i = 0; i < entryRepeater.count; ++i) {
            const card = entryRepeater.itemAt(i)
            if (card && (card.directManipulation || card.manipulationMode))
                return true
        }
        return false
    }

    function setScaleAnchor(minute, pixel) {
        wheelAnimation.stop()
        focusAnimation.stop()
        horizontalFlick.cancelFlick()
        scaleAnchorMinute = minute
        scaleAnchorPixel = pixel
        scaleAnchorLocked = true
        updateAnchoredContentX()
    }

    function releaseScaleAnchor() {
        scaleAnchorLocked = false
        scaleAnchorMinute = -1
    }

    function updateAnchoredContentX() {
        if (!scaleAnchorLocked || scaleAnchorMinute < 0 || axisWidth <= 0)
            return
        const maximum = Math.max(0, 1440 * pxPerMinute - axisWidth)
        const target = scaleAnchorMinute * pxPerMinute - scaleAnchorPixel
        horizontalFlick.contentX = Math.max(0, Math.min(maximum, target))
    }

    function updateSceneContentX() {
        if (!layoutControlled)
            return
        const maximum = Math.max(0, 1440 * pxPerMinute - axisWidth)
        horizontalFlick.contentX = Math.max(0, Math.min(maximum, sceneContentX))
    }

    onSceneContentXChanged: updateSceneContentX()
    onLayoutControlledChanged: {
        if (layoutControlled) {
            wheelAnimation.stop()
            focusAnimation.stop()
            horizontalFlick.cancelFlick()
            updateSceneContentX()
        }
    }
    onExpandedChanged: {
        if (!expanded)
            clearDragState()
    }
    onInteractionEnabledChanged: {
        if (!interactionEnabled)
            clearDragState()
    }
    function setContentX(value, animated) {
        const maximum = Math.max(0, horizontalFlick.contentWidth - horizontalFlick.width)
        const target = Math.max(0, Math.min(maximum, value))
        wheelAnimation.stop()
        focusAnimation.stop()
        if (animated) {
            focusAnimation.to = target
            focusAnimation.restart()
        } else {
            horizontalFlick.contentX = target
        }
    }

    function scrollByWheel(delta) {
        if (!delta)
            return
        const maximum = Math.max(0,
            horizontalFlick.contentWidth - horizontalFlick.width)
        if (maximum <= 0)
            return
        // Accumulate fast wheel/touchpad events from the animation target so
        // continuous scrolling does not fight the previous easing frame.
        const start = horizontalFlick.contentX
        const base = wheelAnimation.running ? wheelAnimation.to : start
        const target = Math.max(0, Math.min(maximum, base - delta))
        focusAnimation.stop()
        wheelAnimation.stop()
        wheelAnimation.from = start
        wheelAnimation.to = target
        wheelAnimation.restart()
    }

    onPxPerMinuteChanged: {
        updateAnchoredContentX()
        updateSceneContentX()
    }
    onWidthChanged: {
        updateAnchoredContentX()
        updateSceneContentX()
    }

    Flickable {
        id: horizontalFlick
        anchors.fill: parent
        clip: true
        contentWidth: Math.max(width, 1440 * root.pxPerMinute)
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        interactive: root.interactionEnabled && !root.layoutControlled
            && !root.draggingEntry && !root.detailOpen
        onMovementStarted: {
            wheelAnimation.stop()
            focusAnimation.stop()
        }

        ScrollBar.horizontal: ScrollBar {
            visible: root.expanded && root.interactionEnabled
                && horizontalFlick.contentWidth > horizontalFlick.width + 0.5
            policy: visible ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        }

        WheelHandler {
            enabled: root.interactionEnabled && !root.draggingEntry
                && !root.detailOpen
            onWheel: function(event) {
                let delta = event.pixelDelta.x || event.angleDelta.x
                if (!delta)
                    delta = event.pixelDelta.y || event.angleDelta.y
                if (!delta)
                    return

                event.accepted = true
                if (event.modifiers & Qt.ControlModifier) {
                    const anchorPixel = point.position.x
                    const anchorMinute = (horizontalFlick.contentX + anchorPixel)
                        / Math.max(0.001, root.pxPerMinute)
                    root.pinchZoomRequested(
                        ZoomMath.wheelZoom(
                            root.pxPerMinute,
                            event.angleDelta.x || event.angleDelta.y,
                            event.pixelDelta.x || event.pixelDelta.y,
                            root.minimumZoom,
                            root.maximumZoom
                        ),
                        anchorMinute,
                        anchorPixel
                    )
                    root.pinchZoomFinished()
                    return
                }
                root.scrollByWheel(delta)
            }
        }

        PinchHandler {
            id: pinchHandler
            target: null
            enabled: root.interactionEnabled && !root.layoutControlled
                && !root.draggingEntry && !root.detailOpen
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            property real startZoom: 1
            minimumScale: startZoom > 0
                ? root.minimumZoom / startZoom : 0.1
            maximumScale: startZoom > 0
                ? root.maximumZoom / startZoom : 10

            onActiveChanged: {
                root.pinching = active
                if (!active) {
                    root.pinchZoomFinished()
                    return
                }
                root.cancelCardTouchGestures()
                wheelAnimation.stop()
                focusAnimation.stop()
                horizontalFlick.cancelFlick()
                startZoom = root.pxPerMinute
                minimumScale = root.minimumZoom / startZoom
                maximumScale = root.maximumZoom / startZoom
            }
            onScaleChanged: {
                if (!active || startZoom <= 0)
                    return
                const center = root.mapFromItem(
                    null, centroid.scenePosition.x, centroid.scenePosition.y
                )
                const anchorMinute = (horizontalFlick.contentX + center.x)
                    / Math.max(0.001, root.pxPerMinute)
                root.pinchZoomRequested(
                    ZoomMath.pinchZoom(
                        startZoom, scale,
                        root.minimumZoom, root.maximumZoom
                    ),
                    anchorMinute,
                    center.x
                )
            }
        }

        NumberAnimation {
            id: wheelAnimation
            target: horizontalFlick
            property: "contentX"
            duration: 180
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: focusAnimation
            target: horizontalFlick
            property: "contentX"
            duration: 420
            easing.type: Easing.InOutCubic
        }

        Rectangle {
            width: horizontalFlick.contentWidth
            height: parent.height
            color: Colors.proxy.cardSecondaryColor
            radius: 4

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: root.selectionCleared()
            }
        }

        Repeater {
            model: root.expanded ? 49 : 13
            delegate: Item {
                property real minute: index * (root.expanded ? 30 : 120)
                property bool hourMark: minute % 60 === 0
                property int hour: Math.floor(minute / 60)
                x: minute * root.pxPerMinute
                width: 1
                height: horizontalFlick.height
                Rectangle {
                    anchors.fill: parent
                    color: Colors.proxy.dividerBorderColor
                    opacity: !root.expanded && index === 0
                        || !root.expanded && index === 12
                        ? 0 : root.expanded
                            ? (parent.hourMark ? 0.7 : 0.38) : 0.7
                }
                Text {
                    visible: root.expanded && parent.hourMark && parent.hour < 24
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 4
                    text: (parent.hour % 12 || 12)
                        + (parent.hour < 12 ? qsTr("AM") : qsTr("PM"))
                    color: Colors.proxy.textSecondaryColor
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            id: dropPreview
            objectName: "timelineDropPreview"
            visible: root.dropPreviewActive && !root.dropPreviewValid
            x: Math.max(0, root.dropPreviewStart * root.pxPerMinute)
            y: 25 * root.visualProgress
            width: Math.max(2,
                (root.dropPreviewEnd - root.dropPreviewStart)
                    * root.pxPerMinute)
            height: Math.max(2,
                horizontalFlick.height - 28 * root.visualProgress)
            radius: 4
            color: Qt.alpha(Colors.proxy.textSecondaryColor, 0.14)
        }

        Repeater {
            id: entryRepeater
            model: root.entries
            delegate: TimelineActivityCard {
                entry: modelData
                subjects: root.subjects
                editable: root.interactionEnabled && !root.readOnlyTimeline
                    && !root.pinching
                compact: root.visualProgress < 0.999
                compactLayout: root.compactLayout
                expandedProgress: root.visualProgress
                detailsVisible: root.detailsVisible
                selected: String(modelData.id) === root.selectedEntryId
                pxPerMinute: root.pxPerMinute
                acrylicSourceItem: root
                onActivated: function(item, card) {
                    root.entrySelected(String(item.id), index)
                }
                onDragStateChanged: function(active) {
                    root.draggingEntry = active
                    if (!active) {
                        root.dragPointerSceneX = -1
                    }
                }
                onDragPointerMoved: function(sceneX) {
                    root.updateDragPointer(modelData.id, sceneX)
                }
                onDragPreviewChanged: function(startMinute, endMinute, valid) {
                    root.showDropPreview(
                        modelData.id, startMinute, endMinute, valid
                    )
                }
                onDragPreviewCleared: root.clearDropPreview(modelData.id)
            }
        }
    }

    HoverHandler {
        onHoveredChanged: root.axisHovered = hovered
    }

    Timer {
        id: autoScrollTimer
        objectName: "timelineAutoScrollTimer"
        interval: 16
        repeat: true
        running: root.autoScrollActive
        onTriggered: {
            if (!root.autoScrollActive)
                return
            const x = root.localDragPointerX()
            let delta = 0
            if (x < root.autoScrollEdge)
                delta = -root.autoScrollPixelsPerTick
            else if (x > horizontalFlick.width - root.autoScrollEdge)
                delta = root.autoScrollPixelsPerTick
            if (delta === 0)
                return
            wheelAnimation.stop()
            focusAnimation.stop()
            const moved = root.applyAutoScrollDelta(delta)
            root.notifyAutoScroll(moved)
        }
    }

    // A native touch/context-menu gesture can cancel the pointer sequence
    // without delivering the card's normal release signal. Recover the
    // axis-local lock when no card is actually manipulating anymore.
    Timer {
        interval: 100
        repeat: true
        running: root.draggingEntry
        onTriggered: {
            if (!root.hasActiveEntryManipulation())
                root.clearDragState()
        }
    }
}
