import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Components
import "../ColorPalette.js" as ColorPalette

Item {
    id: root

    property var entry: ({})
    property var subjects: AppCentral.scheduleEditor.subjects || []
    property bool selected: false
    property bool editable: false
    property bool compact: false
    property bool compactLayout: false
    property real expandedProgress: compact ? 0 : 1
    property bool detailsVisible: false
    property real detailsOpacity: detailsVisible ? 1 : 0
    property bool suppressDetailView: false
    property bool detailRequested: false
    property real pxPerMinute: 0.58
    property real timelineHeight: 128
    property Item acrylicSourceItem: null
    property real movingStart: -1
    property real movingEnd: -1
    property bool directManipulation: false
    property string manipulationMode: ""
    property real manipulationOriginStart: 0
    property real manipulationOriginEnd: 0
    property real pendingSnapStart: -1
    property real pendingSnapEnd: -1
    property bool pendingDropValid: true
    property var pendingConflictEntry: null
    property real dragPointerOffsetY: 0
    property real dragPointerDeltaX: 0
    property real dragAutoScrollPixels: 0
    property real visualOverrideStart: -1
    property real visualOverrideEnd: -1
    property bool contextMenuSuppressed: false
    // Windows may cancel the left sequence before delivering its synthesized
    // right-click. Keep the context menu disabled for that short handoff.
    property bool syntheticContextMenuGuard: false
    property int lastConflictRevision: -1
    property real lastConflictStart: -1
    property real lastConflictEnd: -1
    property var lastConflictEntry: null
    readonly property bool detailOpen: detailViewLoader.active
        && detailViewLoader.item ? detailViewLoader.item.opened : false
    readonly property int snapStepMinutes: 5
    readonly property bool touchPlatform:
        Qt.platform.os === "android" || Qt.platform.os === "ios"
    readonly property bool longPressToDrag: compactLayout || touchPlatform
    readonly property bool cardDragActive: directManipulation
        && manipulationMode === "move"
    property real dragPreludeLift: cardDragActive ? -4 : 0

    function minutes(value) {
        const parts = String(value || "00:00").split(":")
        return Number(parts[0]) * 60 + Number(parts[1])
    }

    function timeText(value) {
        const rounded = Math.round(value)
        const hour = Math.floor(rounded / 60)
        const minute = rounded % 60
        return (hour < 10 ? "0" : "") + hour + ":" + (minute < 10 ? "0" : "") + minute
    }

    function subjectForEntry() {
        for (let i = 0; i < subjects.length; ++i) {
            if (String(subjects[i].id) === String(entry.subjectId))
                return subjects[i]
        }
        return null
    }

    readonly property real startMinute: movingStart >= 0 ? movingStart : minutes(entry.startTime)
    readonly property real endMinute: movingEnd >= 0 ? movingEnd : minutes(entry.endTime)
    readonly property real duration: endMinute - startMinute
    readonly property real visualStartMinute: {
        if (visualOverrideStart >= 0)
            return visualOverrideStart
        if (!directManipulation)
            return startMinute
        if (manipulationMode === "move") {
            const length = manipulationOriginEnd - manipulationOriginStart
            return Math.max(0, Math.min(1440 - length,
                manipulationOriginStart
                    + (dragPointerDeltaX + dragAutoScrollPixels)
                        / pxPerMinute))
        }
        if (manipulationMode === "start")
            return Math.max(0, Math.min(
                manipulationOriginEnd - snapStepMinutes,
                manipulationOriginStart
                    + (dragPointerDeltaX + dragAutoScrollPixels)
                        / pxPerMinute
            ))
        return manipulationOriginStart
    }
    readonly property real visualEndMinute: {
        if (visualOverrideEnd >= 0)
            return visualOverrideEnd
        if (!directManipulation)
            return endMinute
        if (manipulationMode === "move")
            return visualStartMinute
                + manipulationOriginEnd - manipulationOriginStart
        if (manipulationMode === "end")
            return Math.max(manipulationOriginStart + snapStepMinutes,
                Math.min(1440,
                    manipulationOriginEnd
                        + (dragPointerDeltaX + dragAutoScrollPixels)
                            / pxPerMinute))
        return manipulationOriginEnd
    }
    // Figma variants: Full 82px, Medium 64px, Thin 40px.
    readonly property int responsiveVariant: width >= 82 ? 2 : width >= 64 ? 1 : 0
    readonly property bool edgeResizeAvailable: root.editable && root.selected
        && !root.compact && root.width >= 36
    readonly property var subject: subjectForEntry()
    readonly property color baseColor: entry.type === "class"
        ? (subject && subject.color ? subject.color : "#B1EDF6")
        : entry.type === "break"
            ? "#D7EAC2"
            : "#E7E0F4"
    readonly property color surfaceColor: Qt.alpha(
        ColorPalette.atLuminance(baseColor, Theme.currentTheme.isDark ? 0.05 : 0.72),
        0.75
    )
    readonly property color highlightColor: ColorPalette.atLuminance(
        baseColor, Theme.currentTheme.isDark ? 0.11 : 0.40
    )
    readonly property color labelColor: ColorPalette.atLuminance(
        baseColor, Theme.currentTheme.isDark ? 0.60 : 0.05
    )
    readonly property string title: entry.title || (entry.subjectId
        ? AppCentral.scheduleEditor.subjectNameById(entry.subjectId)
        : entry.type === "class" ? qsTr("Class")
        : entry.type === "break" ? qsTr("Break") : qsTr("Activity"))
    readonly property string iconName: entry.type === "class"
        ? "ic_fluent_class_20_filled"
        : entry.type === "break"
            ? "ic_fluent_drink_coffee_20_filled"
            : "ic_fluent_alert_20_filled"

    signal activated(var entry, Item card)
    signal dragStateChanged(bool active)
    signal dragPreviewChanged(real startMinute, real endMinute, bool valid)
    signal dragPreviewCleared()
    signal dragPointerMoved(real sceneX)

    onEntryChanged: {
        if (snapAnimation.running || manipulationMode !== "")
            cancelManipulation()
    }
    onSelectedChanged: {
        if (!selected)
            detailRequested = false
    }
    onEditableChanged: {
        if (!editable)
            detailRequested = false
    }
    onCompactChanged: {
        if (compact)
            detailRequested = false
    }

    width: Math.max(2,
        (visualEndMinute - visualStartMinute) * pxPerMinute)
    height: Math.max(2, parent.height - 28 * expandedProgress)
    y: 25 * expandedProgress
    x: visualStartMinute * pxPerMinute
    z: cardDragActive ? 20 : selected ? 4 : 0
    scale: cardDragActive ? 1.025 : 1
    transformOrigin: Item.Center

    transform: Translate {
        y: root.dragPreludeLift + root.dragPointerOffsetY
    }

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    Behavior on dragPreludeLift {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }
    Behavior on dragPointerOffsetY {
        enabled: !root.cardDragActive
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: snapAnimation
        NumberAnimation {
            id: snapStartAnimation
            target: root
            property: "movingStart"
            duration: 140
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: snapEndAnimation
            target: root
            property: "movingEnd"
            duration: 140
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: snapVisualStartAnimation
            target: root
            property: "visualOverrideStart"
            duration: 140
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            id: snapVisualEndAnimation
            target: root
            property: "visualOverrideEnd"
            duration: 140
            easing.type: Easing.OutCubic
        }
        onFinished: root.applySnappedTimes()
    }

    Behavior on detailsOpacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.surfaceColor
        Behavior on color {
            ColorAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }

    // Match ScheduleCourseCard: selection is a solid, brighter tone of the
    // same entry color rather than a border or a change in opacity.
    Rectangle {
        anchors.fill: parent
        radius: 4
        visible: root.selected
        color: root.highlightColor
    }

    Menu {
        id: contextMenu
        position: Position.None
        MenuItem {
            icon.name: "ic_fluent_edit_20_regular"
            text: qsTr("Edit")
            onTriggered: root.openDetails()
        }
        MenuItem {
            icon.name: "ic_fluent_delete_20_regular"
            text: qsTr("Remove")
            onTriggered: AppCentral.scheduleEditor.removeEntry(root.entry.id)
        }
    }

    Timer {
        id: syntheticContextMenuGuardTimer
        interval: 700
        repeat: false
        onTriggered: root.syntheticContextMenuGuard = false
    }

    HoverHandler {
        cursorShape: root.editable && !root.compact
            ? Qt.SizeAllCursor : Qt.PointingHandCursor
    }

    Item {
        id: moveSurface
        anchors.fill: parent
        visible: root.editable && !root.compact
        enabled: visible && !root.detailOpen

        MouseArea {
            id: moveArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            enabled: parent.enabled
            preventStealing: dragReady
                || (pressed && root.selected && !root.longPressToDrag
                    && !touchPointer)

            property bool dragReady: false
            property bool dragMoved: false
            property bool holdCancelled: false
            property bool touchPointer: false
            property real pressSceneX: 0
            property real pressSceneY: 0

            Timer {
                id: longPressTimer
                interval: 400
                repeat: false
                running: moveArea.pressed && !moveArea.dragReady
                    && !moveArea.holdCancelled
                    && (!root.selected || root.longPressToDrag
                        || moveArea.touchPointer)
                onTriggered: {
                    if (!moveArea.pressed || moveArea.dragReady)
                        return
                    moveArea.dragReady = true
                    if (!root.selected) {
                        root.suppressDetailView = true
                        root.detailRequested = false
                        root.activated(root.entry, root)
                    }
                    moveArea.dragMoved = false
                    root.beginManipulation("move")
                }
            }

            function activateCard() {
                root.activateFromTap()
            }

            function showContextMenu() {
                if (root.touchPlatform || root.contextMenuSuppressed
                        || root.syntheticContextMenuGuard
                        || root.directManipulation)
                    return
                contextMenu.popup()
            }

            function updateMove() {
                if (!pressed || !dragReady)
                    return
                const scenePoint = moveArea.mapToItem(null, moveArea.mouseX,
                    moveArea.mouseY)
                const pixelDelta = scenePoint.x - pressSceneX
                const verticalDelta = scenePoint.y - pressSceneY
                if (Math.abs(pixelDelta) > 2
                        || Math.abs(verticalDelta) > 2)
                    dragMoved = true
                if (!dragMoved)
                    return
                root.dragPointerDeltaX = pixelDelta
                root.dragPointerOffsetY = verticalDelta
                root.updateManipulationFromDelta(
                    root.dragPointerDeltaX + root.dragAutoScrollPixels
                )
                root.dragPointerMoved(scenePoint.x)
            }

            onPressed: function(mouse) {
                if (mouse.button !== Qt.LeftButton)
                    return
                const scenePoint = moveArea.mapToItem(null, moveArea.mouseX,
                    moveArea.mouseY)
                pressSceneX = scenePoint.x
                pressSceneY = scenePoint.y
                // QQuickMouseEvent.source: 0 is a real mouse event, non-zero
                // is Qt/Windows-synthesized input (including touch).
                touchPointer = Number(mouse.source) !== 0
                root.contextMenuSuppressed = true
                root.syntheticContextMenuGuard = false
                syntheticContextMenuGuardTimer.stop()
                dragMoved = false
                dragReady = false
                holdCancelled = false
            }

            onPositionChanged: function(mouse) {
                if (!(mouse.buttons & Qt.LeftButton))
                    return
                const scenePoint = moveArea.mapToItem(null, moveArea.mouseX,
                    moveArea.mouseY)
                const dx = scenePoint.x - pressSceneX
                const dy = scenePoint.y - pressSceneY
                if (!dragReady && !holdCancelled) {
                    if (Math.max(Math.abs(dx), Math.abs(dy)) > 8) {
                        holdCancelled = true
                        longPressTimer.stop()
                    }
                }
                if (!dragReady && root.selected && !root.longPressToDrag
                        && !touchPointer
                        && Math.max(Math.abs(dx), Math.abs(dy)) > 4) {
                    dragReady = true
                    dragMoved = false
                    root.beginManipulation("move")
                }
                updateMove()
            }

            onReleased: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    showContextMenu()
                    return
                }
                const hadDrag = dragReady && dragMoved
                if (dragReady) {
                    if (dragMoved)
                        root.finishManipulation()
                    else
                        root.cancelManipulation()
                } else {
                    root.cancelManipulation()
                    if (root.editable)
                        activateCard()
                }
                dragReady = false
                dragMoved = false
                holdCancelled = false
                touchPointer = false
                root.contextMenuSuppressed = false
                if (hadDrag) {
                    root.syntheticContextMenuGuard = true
                    syntheticContextMenuGuardTimer.restart()
                }
            }

            onCanceled: {
                // Pointer cancellation is also how native touch context-menu
                // gestures end. Always clear the model, even if the local
                // MouseArea state was reset before this callback arrived.
                root.cancelManipulation()
                dragReady = false
                dragMoved = false
                holdCancelled = false
                touchPointer = false
                root.syntheticContextMenuGuard = true
                syntheticContextMenuGuardTimer.restart()
                root.contextMenuSuppressed = false
            }
        }
    }

    Loader {
        id: detailViewLoader
        active: root.detailRequested
            && root.selected && root.editable && !root.compact
            && !root.suppressDetailView
        sourceComponent: Component {
            EntryDetailView {
                sourceItem: root
                acrylicSourceItem: root.acrylicSourceItem
                onClosed: root.detailRequested = false
            }
        }
        onLoaded: Qt.callLater(function() {
            if (item)
                item.refresh(root.entry)
        })
    }

    Item {
        visible: root.edgeResizeAvailable
        enabled: visible && !root.detailOpen
        width: 14
        height: parent.height
        anchors.left: parent.left
        z: 3
        DragHandler {
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: {
                if (active)
                    root.beginManipulation("start")
                else
                    root.finishManipulation()
            }
            onTranslationChanged: {
                if (!active)
                    return
                root.dragPointerDeltaX = translation.x
                root.updateManipulationFromDelta(
                    root.dragPointerDeltaX + root.dragAutoScrollPixels
                )
                root.dragPointerMoved(centroid.scenePosition.x)
            }
        }
        HoverHandler { cursorShape: Qt.SizeHorCursor }
    }

    Item {
        visible: root.edgeResizeAvailable
        enabled: visible && !root.detailOpen
        width: 14
        height: parent.height
        anchors.right: parent.right
        z: 3
        DragHandler {
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onActiveChanged: {
                if (active)
                    root.beginManipulation("end")
                else
                    root.finishManipulation()
            }
            onTranslationChanged: {
                if (!active)
                    return
                root.dragPointerDeltaX = translation.x
                root.updateManipulationFromDelta(
                    root.dragPointerDeltaX + root.dragAutoScrollPixels
                )
                root.dragPointerMoved(centroid.scenePosition.x)
            }
        }
        HoverHandler { cursorShape: Qt.SizeHorCursor }
    }

    function snapDelta(value) {
        return Math.round(value / snapStepMinutes) * snapStepMinutes
    }

    function activateFromTap() {
        openDetails()
    }

    function openDetails() {
        if (!editable || compact)
            return
        suppressDetailView = false
        detailRequested = true
        root.activated(root.entry, root)
        // Reopening the already selected card must refresh its flyout
        // instead of relying on a selection-id change.
        Qt.callLater(function() {
            if (detailViewLoader.item)
                detailViewLoader.item.refresh(root.entry)
        })
    }

    function cancelTouchGesture() {
        cancelManipulation()
        if (typeof moveArea !== "undefined") {
            moveArea.dragReady = false
            moveArea.dragMoved = false
        }
        contextMenuSuppressed = false
    }

    function updateManipulationFromDelta(pixelDelta) {
        if (!manipulationMode)
            return
        const minuteDelta = pixelDelta / pxPerMinute

        if (manipulationMode === "move") {
            const duration = manipulationOriginEnd - manipulationOriginStart
            const rawStart = Math.max(0, Math.min(
                1440 - duration, manipulationOriginStart + minuteDelta
            ))
            const start = Math.max(0, Math.min(
                1440 - duration,
                manipulationOriginStart
                    + snapDelta(rawStart - manipulationOriginStart)
            ))
            movingStart = start
            movingEnd = start + duration
        } else if (manipulationMode === "start") {
            const rawStart = Math.max(0, Math.min(
                manipulationOriginEnd - snapStepMinutes,
                manipulationOriginStart + minuteDelta
            ))
            movingStart = Math.max(0, Math.min(
                manipulationOriginEnd - snapStepMinutes,
                manipulationOriginStart
                    + snapDelta(rawStart - manipulationOriginStart)
            ))
            movingEnd = manipulationOriginEnd
        } else if (manipulationMode === "end") {
            const rawEnd = Math.max(
                manipulationOriginStart + snapStepMinutes,
                Math.min(1440, manipulationOriginEnd + minuteDelta)
            )
            movingStart = manipulationOriginStart
            movingEnd = Math.max(
                manipulationOriginStart + snapStepMinutes,
                Math.min(1440,
                    manipulationOriginEnd
                        + snapDelta(rawEnd - manipulationOriginEnd))
            )
        }
        updateDragPreview()
    }

    function conflictFor(start, end) {
        const revision = AppCentral.scheduleEditor.entriesRevision
        if (lastConflictRevision === revision
                && lastConflictStart === start
                && lastConflictEnd === end)
            return lastConflictEntry
        const conflict = AppCentral.scheduleEditor.findEntryConflict(
            entry.id, timeText(start), timeText(end)
        )
        lastConflictRevision = revision
        lastConflictStart = start
        lastConflictEnd = end
        lastConflictEntry = conflict
        return conflict
    }

    function candidateFor(rawStart, rawEnd) {
        let start = manipulationOriginStart
        let end = manipulationOriginEnd

        if (manipulationMode === "move") {
            const duration = manipulationOriginEnd - manipulationOriginStart
            const delta = snapDelta(rawStart - manipulationOriginStart)
            start = Math.max(0, Math.min(
                1440 - duration, manipulationOriginStart + delta
            ))
            end = start + duration
        } else if (manipulationMode === "start") {
            const delta = snapDelta(rawStart - manipulationOriginStart)
            start = Math.max(0, Math.min(
                manipulationOriginEnd - snapStepMinutes,
                manipulationOriginStart + delta
            ))
            end = manipulationOriginEnd
        } else if (manipulationMode === "end") {
            const delta = snapDelta(rawEnd - manipulationOriginEnd)
            start = manipulationOriginStart
            end = Math.max(
                manipulationOriginStart + snapStepMinutes,
                Math.min(1440, manipulationOriginEnd + delta)
            )
        }

        start = Math.round(start)
        end = Math.round(end)
        const conflict = conflictFor(start, end)
        if (conflict) {
            return {
                start: manipulationOriginStart,
                end: manipulationOriginEnd,
                valid: false,
                conflict: conflict
            }
        }
        return { start: start, end: end, valid: true, conflict: null }
    }

    function updateDragPreview() {
        if (!manipulationMode)
            return
        const candidate = candidateFor(movingStart, movingEnd)
        dragPreviewChanged(candidate.start, candidate.end, candidate.valid)
    }

    function beginManipulation(mode) {
        snapAnimation.stop()
        manipulationMode = mode
        manipulationOriginStart = minutes(entry.startTime)
        manipulationOriginEnd = minutes(entry.endTime)
        movingStart = manipulationOriginStart
        movingEnd = manipulationOriginEnd
        dragPointerOffsetY = 0
        dragPointerDeltaX = 0
        dragAutoScrollPixels = 0
        visualOverrideStart = -1
        visualOverrideEnd = -1
        directManipulation = true
        dragStateChanged(true)
        updateDragPreview()
    }

    function finishManipulation() {
        if (!manipulationMode)
            return

        const rawStart = movingStart >= 0
            ? movingStart : manipulationOriginStart
        const rawEnd = movingEnd >= 0
            ? movingEnd : manipulationOriginEnd
        const candidate = candidateFor(rawStart, rawEnd)
        const snappedStart = candidate.start
        const snappedEnd = candidate.end
        const moved = Math.abs(rawStart - manipulationOriginStart) >= 0.01
            || Math.abs(rawEnd - manipulationOriginEnd) >= 0.01

        if (!moved) {
            cancelManipulation()
            return
        }

        if (candidate.valid
                && Math.abs(snappedStart - manipulationOriginStart) < 0.01
                && Math.abs(snappedEnd - manipulationOriginEnd) < 0.01) {
            cancelManipulation()
            return
        }

        pendingSnapStart = snappedStart
        pendingSnapEnd = snappedEnd
        pendingDropValid = candidate.valid
        pendingConflictEntry = candidate.conflict
        dragPreviewChanged(snappedStart, snappedEnd, candidate.valid)
        const rawVisualStart = visualStartMinute
        const rawVisualEnd = visualEndMinute
        visualOverrideStart = rawVisualStart
        visualOverrideEnd = rawVisualEnd
        snapStartAnimation.from = rawStart
        snapStartAnimation.to = snappedStart
        snapEndAnimation.from = rawEnd
        snapEndAnimation.to = snappedEnd
        snapVisualStartAnimation.from = rawVisualStart
        snapVisualStartAnimation.to = snappedStart
        snapVisualEndAnimation.from = rawVisualEnd
        snapVisualEndAnimation.to = snappedEnd
        snapAnimation.restart()
    }

    function applySnappedTimes() {
        const valid = pendingDropValid
        let conflict = pendingConflictEntry
        if (pendingSnapStart < 0
                || pendingSnapEnd <= pendingSnapStart) {
            cancelManipulation()
            return
        }

        const start = timeText(pendingSnapStart)
        const end = timeText(pendingSnapEnd)
        if (!valid) {
            cancelManipulation()
            floatLayer.createInfoBar({
                title: qsTr("Conflict with existing schedule"),
                text: qsTr("This time overlaps with an existing schedule (%1 – %2)")
                    .arg(conflict ? conflict.startTime : "")
                    .arg(conflict ? conflict.endTime : ""),
                severity: Severity.Warning
            })
            return
        }
        const entryId = entry.id
        const entryType = entry.type
        const subjectId = entry.subjectId || ""
        const entryTitle = entry.title || ""
        const originalStart = timeText(manipulationOriginStart)
        const originalEnd = timeText(manipulationOriginEnd)
        entry.startTime = start
        entry.endTime = end
        const result = AppCentral.scheduleEditor.updateEntryChecked(
            entryId, entryType, start, end, subjectId, entryTitle
        )
        if (!result.ok) {
            entry.startTime = originalStart
            entry.endTime = originalEnd
            conflict = result.conflict
            cancelManipulation()
            if (result.reason === "conflict") {
                floatLayer.createInfoBar({
                    title: qsTr("Conflict with existing schedule"),
                    text: qsTr("This time overlaps with an existing schedule (%1 – %2)")
                        .arg(conflict ? conflict.startTime : "")
                        .arg(conflict ? conflict.endTime : ""),
                    severity: Severity.Warning
                })
            }
            return
        }
        cancelManipulation()
    }

    function cancelManipulation() {
        snapAnimation.stop()
        const wasManipulating = directManipulation || manipulationMode !== ""
        directManipulation = false
        manipulationMode = ""
        movingStart = -1
        movingEnd = -1
        pendingSnapStart = -1
        pendingSnapEnd = -1
        pendingDropValid = true
        pendingConflictEntry = null
        dragPointerOffsetY = 0
        dragPointerDeltaX = 0
        dragAutoScrollPixels = 0
        visualOverrideStart = -1
        visualOverrideEnd = -1
        if (wasManipulating) {
            dragPreviewCleared()
            dragStateChanged(false)
        }
    }

    Component.onDestruction: cancelManipulation()

    function applyAutoScrollDelta(delta) {
        if (!manipulationMode || delta === 0)
            return
        dragAutoScrollPixels += delta
        updateManipulationFromDelta(
            dragPointerDeltaX + dragAutoScrollPixels
        )
    }

    // ActivityCard coordinates follow the Figma Full/Medium/Thin variants.
    // Full and Medium share x=8 for content; Thin centers the 16px icon at x=12.
    Icon {
        visible: root.detailsOpacity > 0 && root.width >= 28
        opacity: root.detailsOpacity
        x: root.width < 40
            ? (root.width - width) / 2
            : root.responsiveVariant === 0 ? 12 : 8
        y: 13
        width: 16
        height: 16
        name: root.iconName
        size: 16
        color: root.labelColor
    }

    Text {
        visible: root.detailsOpacity > 0 && root.responsiveVariant >= 1
        opacity: root.detailsOpacity
        x: 8
        y: 35
        width: Math.max(1, root.width - 16)
        height: 16
        text: root.title
        color: root.labelColor
        font.pixelSize: 14
        font.bold: true
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }

    Text {
        visible: root.detailsOpacity > 0 && root.responsiveVariant === 2
        opacity: root.detailsOpacity
        x: 8
        y: 55
        width: Math.max(1, root.width - 16)
        height: 12
        text: root.timeText(root.startMinute) + " - "
            + root.timeText(root.endMinute)
        color: root.labelColor
        font.pixelSize: 10
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }

    Text {
        visible: root.detailsOpacity > 0 && root.responsiveVariant === 1
        opacity: root.detailsOpacity
        x: 8
        y: 55
        width: Math.max(1, root.width - 16)
        height: 12
        text: root.timeText(root.startMinute) + " -"
        color: root.labelColor
        font.pixelSize: 10
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }

    Text {
        visible: root.detailsOpacity > 0 && root.responsiveVariant === 1
        opacity: root.detailsOpacity
        x: 8
        y: 67
        width: Math.max(1, root.width - 16)
        height: 12
        text: root.timeText(root.endMinute)
        color: root.labelColor
        font.pixelSize: 10
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }

    Text {
        visible: root.detailsOpacity > 0 && root.responsiveVariant === 2
        opacity: root.detailsOpacity
        x: 8
        y: 71
        width: Math.max(1, root.width - 16)
        height: 12
        text: qsTr("%1 min").arg(Math.round(root.duration))
        color: root.labelColor
        font.pixelSize: 10
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        maximumLineCount: 1
        wrapMode: Text.NoWrap
    }
}
