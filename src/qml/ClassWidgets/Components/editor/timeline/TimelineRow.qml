import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Components
import "../WeekRule.js" as WeekRule

Item {
    id: root

    property var timeline: ({})
    property int timelineIndex: -1
    property bool expanded: false
    property real expandedHeight: 450
    property real layoutHeight: expanded ? expandedHeight : 104
    property real visualProgress: expanded ? 1 : 0
    property bool interactionEnabled: expanded
    property real zoom: 1.5
    property string selectedEntryId: ""
    property var subjects: AppCentral.scheduleEditor.subjects || []
    property bool readOnlyTimeline: AppCentral.scheduleManager.isReadonly()
    property int maxWeekCycle: AppCentral.scheduleEditor.meta.maxWeekCycle || 1
    property var entriesOverride: undefined
    property bool toolbarVisible: false
    property real animatedScale: previewScale
    property real sceneContentX: 0
    property bool layoutControlled: false
    property bool detailsVisible: false
    property bool undoAvailable: false
    property bool redoAvailable: false

    readonly property bool compactLayout: width < 760
    readonly property real previewScale: Math.max(0.25, (width - 16) / 1440)
    readonly property real pxPerMinute: animatedScale
    readonly property real axisWidth: axisView.axisWidth
    readonly property real axisContentX: axisView.axisContentX
    readonly property bool axisHovered: axisView.axisHovered
    readonly property var entries: {
        if (entriesOverride !== undefined && entriesOverride !== null)
            return entriesOverride
        const revision = AppCentral.scheduleEditor.entriesRevision
        const currentDays = AppCentral.scheduleEditor.entriesData || []
        for (let i = 0; i < currentDays.length; ++i) {
            if (String(currentDays[i].id) === String(timeline && timeline.id))
                return currentDays[i].entries || []
        }
        return timeline && timeline.entries ? timeline.entries : []
    }

    signal requestExpand(int index)
    signal requestCollapse()
    signal requestPage(int index)
    signal entrySelected(string entryId, int index)
    signal selectionCleared()
    signal editRulesRequested(var timeline)
    signal deleteRequested(var timeline)
    signal undoRequested()
    signal redoRequested()
    signal addRequested(string type)
    signal zoomRequested(real value)
    signal pinchZoomRequested(real value, real anchorMinute, real anchorPixel)
    signal pinchZoomFinished()

    function titleForTimeline() {
        if (timeline.date) {
            const date = new Date(timeline.date)
            return Qt.locale().monthName(date.getMonth() + 1, Locale.LongFormat)
                + " " + date.getDate()
        }
        const days = WeekRule.dayList(timeline.dayOfWeek)
        if (!days || !days.length)
            return qsTr("Timeline")
        if (days.length === 5 && days.every(value => value >= 1 && value <= 5))
            return qsTr("Weekdays")
        if (days.length === 2 && days[0] === 6 && days[1] === 7)
            return qsTr("Weekends")
        return days.map(value =>
            Qt.locale().dayName(Number(value), Locale.ShortFormat)).join(qsTr(", "))
    }

    function ruleText() {
        if (timeline.date)
            return qsTr("%1 year").arg(new Date(timeline.date).getFullYear())
        const rule = WeekRule.decode(timeline.weeks)
        const kind = WeekRule.kind(rule)
        if (kind === "odd")
            return qsTr("Odd Week")
        if (kind === "even")
            return qsTr("Even Week")
        if (kind === "specific")
            return qsTr("Weeks %1").arg(WeekRule.specificWeeks(rule).join(", "))
        if (kind === "cycle")
            return qsTr("Every %1 weeks").arg(maxWeekCycle)
        return qsTr("Every week")
    }

    function setScaleAnchor(minute, pixel) {
        axisView.setScaleAnchor(minute, pixel)
    }

    function releaseScaleAnchor() {
        axisView.releaseScaleAnchor()
    }

    function focusEntry(entryId, animated) {
        const target = entries.find(entry => String(entry.id) === String(entryId))
        if (!target)
            return
        const parts = String(target.startTime).split(":")
        const firstMinute = Number(parts[0]) * 60 + Number(parts[1])
        axisView.setContentX(
            firstMinute * pxPerMinute - axisView.axisWidth * 0.4,
            animated === true
        )
    }

    function setEntries(value) {
        entriesOverride = value
    }

    height: layoutHeight

    Clip {
        anchors.fill: parent
        z: -1
        color: Colors.proxy.cardColor
        radius: Theme.currentTheme.appearance.smallRadius
        border.width: Theme.currentTheme.appearance.borderWidth
        border.color: Colors.proxy.cardBorderColor
    }

    MouseArea {
        anchors.fill: parent
        z: 1
        enabled: !root.expanded
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestExpand(root.timelineIndex)
    }

    TimelineRowHeader {
        id: rowHeader
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: expanded ? 8 : 16
            rightMargin: 8
            topMargin: 6
        }
        z: 10
        timeline: root.timeline
        title: root.titleForTimeline()
        rule: root.ruleText()
        expanded: root.expanded
        compactLayout: root.compactLayout
        onCollapseRequested: root.requestCollapse()
        onEditRulesRequested: function(day) { root.editRulesRequested(day) }
        onDeleteRequested: function(day) { root.deleteRequested(day) }
    }

    TimelineAxis {
        id: axisView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: rowHeader.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 8
        z: root.expanded ? 5 : 0
        entries: root.entries
        subjects: root.subjects
        expanded: root.expanded
        interactionEnabled: root.interactionEnabled
        readOnlyTimeline: root.readOnlyTimeline
        compactLayout: root.compactLayout
        visualProgress: root.visualProgress
        pxPerMinute: root.pxPerMinute
        overviewScale: root.previewScale
        sceneContentX: root.sceneContentX
        layoutControlled: root.layoutControlled
        detailsVisible: root.detailsVisible
        selectedEntryId: root.selectedEntryId
        onEntrySelected: function(entryId, index) {
            root.entrySelected(entryId, index)
        }
        onSelectionCleared: root.selectionCleared()
        onPinchZoomRequested: function(value, anchorMinute, anchorPixel) {
            root.pinchZoomRequested(value, anchorMinute, anchorPixel)
        }
        onPinchZoomFinished: root.pinchZoomFinished()
    }

    Loader {
        id: toolbarLoader
        objectName: "timelineToolbarLoader"
        anchors.fill: parent
        z: 20
        active: false
        sourceComponent: Component {
            // Loader resizes its root item to its own bounds. Keep the toolbar
            // inside an unscaled container so it can retain its intrinsic size.
            Item {
                TimelineToolbar {
                    toolbarVisible: root.expanded && root.toolbarVisible
                    compactLayout: root.compactLayout
                    zoomValue: root.zoom
                    overviewScale: root.previewScale
                    // Sample the axis and activity cards behind the floating
                    // toolbar so the acrylic backdrop does not include itself.
                    sourceItem: axisView
                    undoAvailable: root.undoAvailable
                    redoAvailable: root.redoAvailable
                    onUndoRequested: root.undoRequested()
                    onRedoRequested: root.redoRequested()
                    onAddRequested: function(type) { root.addRequested(type) }
                    onZoomRequested: function(value) { root.zoomRequested(value) }
                }
            }
        }
    }

    Timer {
        id: toolbarUnloadTimer
        // Keep the toolbar alive through the row's collapse transition.
        interval: 480
        onTriggered: toolbarLoader.active = false
    }

    onExpandedChanged: {
        if (expanded) {
            toolbarUnloadTimer.stop()
            toolbarLoader.active = true
        } else if (toolbarLoader.active) {
            toolbarUnloadTimer.restart()
        }
    }
    Component.onCompleted: {
        if (expanded)
            toolbarLoader.active = true
    }
}
