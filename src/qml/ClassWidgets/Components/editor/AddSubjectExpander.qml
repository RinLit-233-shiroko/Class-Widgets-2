import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

// Quick-fill panel, toggled by the "Quick Fill" button in the bottom bar.
// It is not a Popup/Flyout, so clicking outside does not dismiss it; the
// header area stays freely draggable.
Item {
    id: root

    implicitWidth: 340
    readonly property int subjectViewportMaxHeight: 150
    // The root follows the layout's height; only the course list is capped.
    implicitHeight: contentColumn.implicitHeight + 28

    property real edgeMargin: 24

    /** Default dock and drag lower-bound Y (usually the top of the bottom bar). */
    property real bottomAnchorY: parent ? parent.height - edgeMargin : 0
    property real bottomGap: 0
    /** Page content sampled by AcrylicBrush. */
    property Item sourceItem: null

    property var subjects: AppCentral.scheduleRuntime.subjects || []
    readonly property real cornerRadius: 8

    // Keep the same feel parameters as FloatingWidgetContainer.
    readonly property real friction: 0.86
    readonly property real springStrength: 115
    readonly property real springDamping: 18
    readonly property real stopVelocity: 6
    readonly property int maxDragSamples: 20
    readonly property int sampleWindowMs: 100

    signal subjectClicked(var subjectId)
    signal nextRequested()

    // —— Drag state —— //
    property bool _positionInitialized: false
    property bool _userPositioned: false
    property real _velocityX: 0
    property real _velocityY: 0
    property var _dragSamples: []

    visible: false

    function _bounds() {
        if (!parent)
            return { minX: 0, minY: 0, maxX: 0, maxY: 0 }

        const minX = Math.max(0, edgeMargin)
        const minY = Math.max(0, edgeMargin)
        return {
            minX: minX,
            minY: minY,
            maxX: Math.max(minX, parent.width - width - edgeMargin),
            maxY: Math.max(minY, bottomAnchorY - bottomGap - height)
        }
    }

    function _clampToBounds(posX, posY) {
        const bounds = _bounds()
        return {
            x: Math.max(bounds.minX, Math.min(bounds.maxX, posX)),
            y: Math.max(bounds.minY, Math.min(bounds.maxY, posY))
        }
    }

    function _draggedPosition(pos, minimum, maximum) {
        if (pos < minimum)
            return minimum + (pos - minimum) * 0.22
        if (pos > maximum)
            return maximum + (pos - maximum) * 0.22
        return pos
    }

    function _placeDefaultPosition() {
        // Layout anchors can briefly report incomplete values. Keep defaulting
        // to the bottom-right corner until the user actually drags the panel.
        if (!parent || width <= 0 || height <= 0
                || parent.width <= 0 || parent.height <= 0 || bottomAnchorY <= 0)
            return

        const bounds = _bounds()
        x = bounds.maxX
        // If the anchor is temporarily too high to fit the panel, use the
        // page bottom instead of locking the panel to the top edge.
        y = bounds.maxY <= bounds.minY
            ? Math.max(bounds.minY, parent.height - edgeMargin - height)
            : bounds.maxY
        _positionInitialized = true
    }

    function _reconcilePosition() {
        if (!_positionInitialized || !parent)
            return

        const position = _clampToBounds(x, y)
        x = position.x
        y = position.y
    }

    function _syncPosition() {
        if (!_userPositioned) {
            _placeDefaultPosition()
            return
        }
        if (_positionInitialized)
            _reconcilePosition()
    }

    function _startInertia() {
        if (Math.abs(_velocityX) > stopVelocity || Math.abs(_velocityY) > stopVelocity)
            physicsAnimation.running = true
        else
            _reconcilePosition()
    }

    function showPanel() {
        visible = true
        _syncPosition()
        // Re-run after the popup/layout pass in case bottomAnchorY settles
        // on the next event-loop turn.
        Qt.callLater(_syncPosition)
    }

    function hidePanel() {
        physicsAnimation.running = false
        visible = false
    }

    function toggle() {
        visible ? hidePanel() : showPanel()
    }

    Component.onCompleted: _syncPosition()

    // Before the first drag, keep recalculating the default bottom-right
    // position while page geometry settles. Afterwards only clamp it.
    onWidthChanged: _syncPosition()
    onHeightChanged: _syncPosition()
    onBottomAnchorYChanged: _syncPosition()
    onVisibleChanged: {
        if (visible)
            _syncPosition()
    }

    // ── Background ───────────────────────────────────────────────────
    Item {
        id: panelBackground
        anchors.fill: parent
        clip: true

        layer.enabled: true
        layer.effect: Shadow {
            style: "flyout"
            source: panelBackground
        }

        AcrylicBrush {
            anchors.fill: parent
            sourceItem: root.sourceItem
            enabled: root.sourceItem !== null
            radius: root.cornerRadius
            z: 0
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: "transparent"
            border.color: Theme.currentTheme.colors.flyoutBorderColor
            border.width: 1
            z: 1
        }
    }

    // ── Content ──────────────────────────────────────────────────────
    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 4
            radius: height / 2
            color: Colors.proxy.dividerBorderColor
        }

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            typography: Typography.BodyStrong
            text: qsTr("Quick Add Subject")
            elide: Text.ElideRight
        }

        Flickable {
            id: subjectFlick
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(
                subjectsFlow.height,
                root.subjectViewportMaxHeight
            )
            Layout.maximumHeight: root.subjectViewportMaxHeight
            contentWidth: width
            contentHeight: subjectsFlow.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { }

            Flow {
                id: subjectsFlow
                width: subjectFlick.width
                spacing: 0

                Repeater {
                    model: root.subjects

                    Button {
                        enabled: !AppCentral.scheduleManager.isReadonly()
                        flat: true
                        icon.name: modelData.icon || ""
                        text: modelData.name
                        onClicked: root.subjectClicked(modelData.id)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            Item {
                Layout.fillWidth: true
            }

            Button {
                Layout.preferredWidth: 140
                Layout.preferredHeight: 32
                enabled: !AppCentral.scheduleManager.isReadonly()
                text: qsTr("Next Class")
                onClicked: root.nextRequested()
            }
        }
    }

    // ── Drag / inertia ───────────────────────────────────────────────
    Item {
        id: dragHandle
        width: root.width
        height: 48
        z: 1000

        HoverHandler {
            cursorShape: Qt.SizeAllCursor
        }

        DragHandler {
            id: dragHandler
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromAnything

            property real startX: 0
            property real startY: 0
            property bool dragged: false

            onActiveChanged: {
                if (active) {
                    root._userPositioned = true
                    physicsAnimation.running = false
                    root._velocityX = 0
                    root._velocityY = 0
                    startX = root.x
                    startY = root.y
                    root._dragSamples = []
                    dragged = false
                    return
                }

                if (!root._positionInitialized)
                    return

                if (!dragged) {
                    root._reconcilePosition()
                    return
                }

                const now = Date.now()
                const cutoff = now - root.sampleWindowMs
                const samples = root._dragSamples
                while (samples.length > 0 && samples[0].t < cutoff)
                    samples.shift()

                if (samples.length >= 2) {
                    const first = samples[0]
                    const last = samples[samples.length - 1]
                    const dt = Math.max(1, last.t - first.t)
                    root._velocityX = (last.x - first.x) * 1000 / dt
                    root._velocityY = (last.y - first.y) * 1000 / dt
                } else {
                    root._velocityX = 0
                    root._velocityY = 0
                }

                root._startInertia()
            }

            onTranslationChanged: {
                if (!active)
                    return

                const now = Date.now()
                const bounds = root._bounds()
                const rawX = startX + translation.x
                const rawY = startY + translation.y
                const positionX = root._draggedPosition(
                    rawX, bounds.minX, bounds.maxX
                )
                const positionY = root._draggedPosition(
                    rawY, bounds.minY, bounds.maxY
                )

                const samples = root._dragSamples
                samples.push({ t: now, x: positionX, y: positionY })
                if (samples.length > root.maxDragSamples)
                    samples.shift()

                root.x = positionX
                root.y = positionY
                dragged = dragged || Math.abs(translation.x) > 8
                    || Math.abs(translation.y) > 8
            }
        }
    }

    // Mirrors FloatingWidgetContainer's velocity + spring motion.
    FrameAnimation {
        id: physicsAnimation
        running: false

        onTriggered: {
            const dt = Math.min(frameTime, 0.05)
            const bounds = root._bounds()
            let forceX = 0
            let forceY = 0

            if (root.x < bounds.minX)
                forceX = (bounds.minX - root.x) * root.springStrength
                    - root._velocityX * root.springDamping
            else if (root.x > bounds.maxX)
                forceX = (bounds.maxX - root.x) * root.springStrength
                    - root._velocityX * root.springDamping

            if (root.y < bounds.minY)
                forceY = (bounds.minY - root.y) * root.springStrength
                    - root._velocityY * root.springDamping
            else if (root.y > bounds.maxY)
                forceY = (bounds.maxY - root.y) * root.springStrength
                    - root._velocityY * root.springDamping

            root._velocityX += forceX * dt
            root._velocityY += forceY * dt

            const damping = Math.pow(root.friction, dt * 60)
            root._velocityX *= damping
            root._velocityY *= damping
            root.x += root._velocityX * dt
            root.y += root._velocityY * dt

            const insideX = root.x >= bounds.minX && root.x <= bounds.maxX
            const insideY = root.y >= bounds.minY && root.y <= bounds.maxY
            const stoppedX = insideX && Math.abs(root._velocityX) < root.stopVelocity
            const stoppedY = insideY && Math.abs(root._velocityY) < root.stopVelocity

            if (stoppedX)
                root._velocityX = 0
            if (stoppedY)
                root._velocityY = 0
            if (stoppedX && stoppedY) {
                physicsAnimation.running = false
                root._reconcilePosition()
            }
        }
    }

    Connections {
        target: root.parent

        function onWidthChanged() {
            root._syncPosition()
        }

        function onHeightChanged() {
            root._syncPosition()
        }
    }
}
