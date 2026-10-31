import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Components

Item {
    id: overview

    property var page

    readonly property var sceneItem: timelineScene
    readonly property var rowRepeater: timelineRepeater
    readonly property var dateHeader: dateSectionHeader
    readonly property var weekHeader: weekSectionHeader
    readonly property var pageIndicatorControl: timelinePageIndicator

    Column {
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 8

        TimelineTopBar {
            id: topActions
            width: parent.width
            compactTopBar: overview.page.compactTopBar
            viewMode: overview.page.viewMode
            pendingViewMode: overview.page.pendingViewMode

            onViewModeRequested: function(index) {
                if (overview.page.sceneExpanded || overview.page.transitionTargetExpanded) {
                    overview.page.pendingViewMode = index
                    overview.page.collapseTimeline()
                } else {
                    overview.page.viewMode = index
                }
            }
            onSettingsRequested: overview.page.openTimelineSettings()
            onNewTimelineRequested: function(ruleMode) {
                overview.page.createTimeline(ruleMode)
            }
        }

        Item {
            id: sceneHost
            width: parent.width
            height: Math.max(0, parent.height - topActions.height - 8)

            Item {
                id: timelineScene
                anchors.fill: parent
                clip: true
                z: 1

                DragHandler {
                    id: verticalGesture
                    target: null
                    enabled: !overview.page.activeDetailOpen
                    xAxis.enabled: false
                    yAxis.enabled: true
                    grabPermissions: PointerHandler.CanTakeOverFromAnything
                    property real startingOverviewOffset: 0
                    property bool changedPage: false
                    onActiveChanged: {
                        if (!active)
                            return
                        overview.page.stopOverviewWheelAnimation()
                        startingOverviewOffset = overview.page.overviewScrollOffset
                        changedPage = false
                    }
                    onTranslationChanged: {
                        if (!active)
                            return
                        if (overview.page.sceneExpanded || overview.page.transitionTargetExpanded) {
                            if (changedPage || Math.abs(translation.y) < 48)
                                return
                            changedPage = true
                            overview.page.navigateTimeline(translation.y < 0 ? 1 : -1)
                            return
                        }
                        overview.page.setOverviewOffset(startingOverviewOffset - translation.y)
                    }
                }

                WheelHandler {
                    id: sceneWheel
                    enabled: !overview.page.activeDetailOpen
                    onWheel: function(event) {
                        const horizontal = event.pixelDelta.x || event.angleDelta.x
                        const vertical = event.pixelDelta.y || event.angleDelta.y
                        if (Math.abs(horizontal) > Math.abs(vertical))
                            return
                        if (!vertical)
                            return

                        if (overview.page.sceneExpanded || overview.page.transitionTargetExpanded) {
                            if (overview.page.activeAxisHovered)
                                return
                            event.accepted = true
                            if (overview.page.wheelPagePending)
                                return
                            overview.page.wheelPagePending = true
                            wheelGestureTimer.restart()
                            overview.page.navigateTimeline(vertical < 0 ? 1 : -1)
                            return
                        }

                        event.accepted = true
                        const delta = event.pixelDelta.y
                            || Math.sign(event.angleDelta.y) * 44
                        overview.page.scrollOverviewByWheel(delta)
                    }
                }

                TimelineSectionHeader {
                    id: dateSectionHeader
                    x: 0
                    y: overview.page.sectionHeaderY(true)
                    opacity: overview.page.sectionHeaderOpacity()
                    width: timelineScene.width
                    visible: overview.page.hasDateSection && opacity > 0
                    title: qsTranslate("Timeline", "By Date")
                    expanded: overview.page.dateSectionExpanded
                    expansionProgress: overview.page.dateSectionProgress
                    filterModel1: overview.page.monthFilterModel
                    filterModel2: overview.page.yearFilterModel
                    filterIndex1: overview.page.monthFilterIndex
                    filterIndex2: Math.max(0,
                        overview.page.yearFilterModel.indexOf(overview.page.yearFilter))

                    onExpandedToggled: function(expanded) {
                        overview.page.dateSectionExpanded = expanded
                        if (!expanded && overview.page.expandedIndex >= 0
                                && overview.page.timelineDataAt(overview.page.expandedIndex).date)
                            overview.page.collapseTimeline()
                    }
                    onFilterActivated1: function(index) {
                        overview.page.monthFilterIndex = index
                        overview.page.collapseTimeline()
                    }
                    onFilterActivated2: function(index, text) {
                        overview.page.yearFilter = index === 0 ? "" : text
                        overview.page.collapseTimeline()
                    }
                }

                TimelineSectionHeader {
                    id: weekSectionHeader
                    x: 0
                    y: overview.page.sectionHeaderY(false)
                    opacity: overview.page.sectionHeaderOpacity()
                    width: timelineScene.width
                    visible: overview.page.hasWeekSection && opacity > 0
                    title: qsTranslate("Timeline", "By Week")
                    expanded: overview.page.weekSectionExpanded
                    expansionProgress: overview.page.weekSectionProgress
                    filterModel1: overview.page.weekdayFilterModel
                    filterIndex1: overview.page.weekFilterIndex

                    onExpandedToggled: function(expanded) {
                        overview.page.weekSectionExpanded = expanded
                        if (!expanded && overview.page.expandedIndex >= 0
                                && !overview.page.timelineDataAt(overview.page.expandedIndex).date)
                            overview.page.collapseTimeline()
                    }
                    onFilterActivated1: function(index) {
                        overview.page.weekFilterIndex = index
                        overview.page.collapseTimeline()
                    }
                }

                Repeater {
                    id: timelineRepeater
                    objectName: "timelineRepeater"
                    model: overview.page.filteredTimelines.length
                    delegate: TimelineRow {
                        id: timelineRow
                        property var sceneGeometry: overview.page.rowGeometry(index)
                        x: sceneGeometry.x
                        y: sceneGeometry.y
                        width: sceneGeometry.width
                        layoutHeight: sceneGeometry.height
                        animatedScale: sceneGeometry.scale
                        visualProgress: sceneGeometry.visualProgress
                        sceneContentX: sceneGeometry.contentX
                        layoutControlled: overview.page.transitionActive
                        detailsVisible: overview.page.toolbarVisible && expanded
                        visible: overview.page.rowIsVisible(index)
                        opacity: overview.page.rowOpacity(index)
                        timeline: overview.page.filteredTimelines[index].day
                        subjects: overview.page.subjects
                        readOnlyTimeline: overview.page.readOnlyTimeline
                        maxWeekCycle: overview.page.maxWeekCycle
                        entriesOverride: overview.page.entriesByDayId[
                            String(overview.page.filteredTimelines[index].day.id)
                        ]
                        timelineIndex: index
                        expanded: overview.page.transitionActive
                            ? overview.page.transitionTargetExpanded
                                && index === overview.page.transitionTargetIndex
                            : overview.page.sceneExpanded && index === overview.page.sceneFocusIndex
                        interactionEnabled: overview.page.sceneExpanded
                            && !overview.page.transitionActive && index === overview.page.sceneFocusIndex
                        zoom: overview.page.animatedZoom
                        toolbarVisible: overview.page.toolbarVisible && expanded
                        selectedEntryId: expanded ? overview.page.selectedEntryId : ""
                        undoAvailable: expanded && overview.page.undoAvailable
                        redoAvailable: expanded && overview.page.redoAvailable
                        z: expanded ? 3 : 1

                        onRequestExpand: function(rowIndex) {
                            overview.page.setExpanded(rowIndex)
                        }
                        onRequestCollapse: overview.page.collapseTimeline()
                        onEditRulesRequested: function(day) {
                            overview.page.editTimelineRules(day)
                        }
                        onDeleteRequested: function(day) {
                            overview.page.requestTimelineDelete(day)
                        }
                        onDuplicateRequested: overview.page.duplicateTimeline(dayId)
                        onEntrySelected: function(entryId, entryIndex) {
                            if (overview.page.sceneFocusIndex === index
                                    || overview.page.transitionTargetIndex === index)
                                overview.page.selectedEntryId = entryId
                        }
                        onSelectionCleared: {
                            if (!overview.page.transitionActive
                                    && overview.page.sceneFocusIndex === index)
                                overview.page.selectedEntryId = ""
                        }
                        onUndoRequested: overview.page.undo()
                        onRedoRequested: overview.page.redo()
                        onAddRequested: function(type) {
                            overview.page.addEntry(type)
                        }
                        onZoomRequested: function(value) {
                            overview.page.setZoom(value)
                        }
                        onPinchZoomRequested: function(
                                value, anchorMinute, anchorPixel) {
                            overview.page.applyPinchZoom(
                                value, anchorMinute, anchorPixel
                            )
                        }
                        onPinchZoomFinished: overview.page.finishPinchZoom()
                    }
                }

                ScrollBar {
                    id: overviewScrollBar
                    objectName: "overviewScrollBar"
                    orientation: Qt.Vertical
                    // RinUI's ScrollBar anchors its center by default; clear
                    // that before constraining it to this fixed scene.
                    anchors.verticalCenter: undefined
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    visible: overview.page.showOverviewScrollBar
                    z: 5
                    policy: visible ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    size: overview.page.overviewContentHeight > 0
                        ? Math.min(1, timelineScene.height
                            / overview.page.overviewContentHeight) : 1
                    position: overview.page.overviewContentHeight > 0
                        ? overview.page.overviewScrollOffset
                            / overview.page.overviewContentHeight : 0
                    onPositionChanged: {
                        if (pressed)
                            overview.page.setOverviewOffset(
                                position * overview.page.overviewContentHeight
                            )
                    }
                }
            }

            Item {
                id: pageIndicator
                visible: overview.page.pageIndicatorOpacity > 0.001
                opacity: overview.page.pageIndicatorOpacity
                z: 4
                width: 24
                height: Math.min(sceneHost.height,
                    Math.max(48, overview.page.filteredTimelines.length * 12 + 48))
                anchors.right: parent.right
                anchors.rightMargin: 0
                anchors.verticalCenter: sceneHost.verticalCenter

                PageIndicator {
                    id: timelinePageIndicator
                    anchors.centerIn: parent
                    width: parent.height
                    height: parent.width
                    rotation: 90
                    caret: true
                    count: overview.page.filteredTimelines.length
                    currentIndex: 0
                    interactive: overview.page.filteredTimelines.length > 1
                    onCurrentIndexChanged: {
                        if (!overview.page.syncingPageIndicator
                                && pageIndicator.visible && currentIndex >= 0
                                && currentIndex < overview.page.filteredTimelines.length
                                && currentIndex !== overview.page.expandedIndex)
                            overview.page.setExpanded(currentIndex)
                    }
                }
            }
        }
    }

    Timer {
        id: wheelGestureTimer
        interval: 380
        onTriggered: overview.page.wheelPagePending = false
    }
}
