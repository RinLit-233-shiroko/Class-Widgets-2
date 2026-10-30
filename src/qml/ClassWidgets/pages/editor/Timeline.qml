import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Components
import "../../Components/editor/WeekRule.js" as WeekRule

Item {
    id: root

    property var timelines: AppCentral.scheduleEditor.days || []
    property int viewMode: 0 // 0: all, 1: weekly rules, 2: date rules
    property int pendingViewMode: -1
    property string activeTimelineId: ""
    property int expandedIndex: -1
    property string selectedEntryId: ""
    property bool undoAvailable: false
    property bool redoAvailable: false
    property real zoom: 2.2
    property real animatedZoom: 2.2
    property int monthFilterIndex: 0
    property string yearFilter: ""
    property int weekFilterIndex: 0
    property bool dateSectionExpanded: true
    property bool weekSectionExpanded: true
    property real dateSectionProgress: 1
    property real weekSectionProgress: 1
    property bool wheelPagePending: false
    property bool sceneExpanded: false
    property int sceneFocusIndex: -1
    property bool transitionTargetExpanded: false
    property int transitionTargetIndex: -1
    property bool transitionActive: false
    property bool replacingTransition: false
    property real motionProgress: 1
    property var motionFromGeometry: []
    property real sectionHeadersOpacity: 1
    property real motionFromDateHeaderY: 0
    property real motionFromWeekHeaderY: 0
    property real overviewScrollOffset: 0
    property real transitionTargetScrollOffset: 0
    property bool syncingPageIndicator: false
    property real pageIndicatorOpacity: 0
    readonly property bool compactTopBar: width < 920
    readonly property var availableMonths: {
        const found = ({})
        for (let i = 0; i < timelines.length; ++i) {
            if (!timelines[i].date)
                continue
            const month = new Date(timelines[i].date).getMonth() + 1
            if (month >= 1 && month <= 12)
                found[month] = true
        }
        return Object.keys(found).map(Number).sort((a, b) => a - b)
    }
    readonly property var availableYears: {
        const found = ({})
        for (let i = 0; i < timelines.length; ++i) {
            if (timelines[i].date)
                found[String(new Date(timelines[i].date).getFullYear())] = true
        }
        return Object.keys(found).sort()
    }
    readonly property var availableWeekdays: {
        const found = ({})
        for (let i = 0; i < timelines.length; ++i) {
            if (timelines[i].date)
                continue
            const days = WeekRule.dayList(timelines[i].dayOfWeek)
            for (let j = 0; j < days.length; ++j)
                found[days[j]] = true
        }
        return Object.keys(found).map(Number).sort((a, b) => a - b)
    }
    readonly property var monthFilterModel: {
        const values = [qsTr("All months")]
        for (let i = 0; i < availableMonths.length; ++i)
            values.push(Qt.locale().monthName(
                availableMonths[i], Locale.LongFormat
            ))
        return values
    }
    readonly property var yearFilterModel:
        [qsTr("All years")].concat(availableYears)
    readonly property var weekdayFilterModel: {
        const values = [qsTr("All weekdays")]
        for (let i = 0; i < availableWeekdays.length; ++i)
            values.push(Qt.locale().dayName(
                availableWeekdays[i], Locale.ShortFormat
            ))
        return values
    }
    readonly property int selectedMonth:
        monthFilterIndex > 0 && monthFilterIndex <= availableMonths.length
            ? availableMonths[monthFilterIndex - 1] : 0
    readonly property int selectedWeekday:
        weekFilterIndex > 0 && weekFilterIndex <= availableWeekdays.length
            ? availableWeekdays[weekFilterIndex - 1] : 0

    onAvailableMonthsChanged: {
        if (monthFilterIndex < 0 || monthFilterIndex > availableMonths.length)
            monthFilterIndex = 0
    }
    onAvailableYearsChanged: {
        if (yearFilter !== "" && availableYears.indexOf(yearFilter) < 0)
            yearFilter = ""
    }
    onAvailableWeekdaysChanged: {
        if (weekFilterIndex < 0 || weekFilterIndex > availableWeekdays.length)
            weekFilterIndex = 0
    }
    onDateSectionExpandedChanged: {
        dateSectionAnimation.stop()
        dateSectionAnimation.to = dateSectionExpanded ? 1 : 0
        dateSectionAnimation.restart()
    }
    onWeekSectionExpandedChanged: {
        weekSectionAnimation.stop()
        weekSectionAnimation.to = weekSectionExpanded ? 1 : 0
        weekSectionAnimation.restart()
    }

    readonly property var matchingTimelines: {
        const revision = AppCentral.scheduleEditor.entriesRevision
        const dates = []
        const weeks = []
        for (let i = 0; i < timelines.length; ++i) {
            const day = timelines[i]
            if (day.date) {
                const date = new Date(day.date)
                if (selectedMonth > 0 && date.getMonth() + 1 !== selectedMonth)
                    continue
                if (yearFilter !== ""
                        && String(date.getFullYear()) !== yearFilter)
                    continue
                dates.push({ day: day, sourceIndex: i })
                continue
            }
            const selectedDays = WeekRule.dayList(day.dayOfWeek)
            if (selectedWeekday > 0
                    && selectedDays.indexOf(selectedWeekday) < 0)
                continue
            weeks.push({ day: day, sourceIndex: i })
        }
        if (viewMode === 1)
            return weeks
        if (viewMode === 2)
            return dates
        return dates.concat(weeks)
    }
    readonly property var filteredTimelines: matchingTimelines
    readonly property var filteredDates: matchingTimelines.filter(item => !!item.day.date)
    readonly property var filteredWeeks: matchingTimelines.filter(item => !item.day.date)
    readonly property real expandedTimelineHeight: {
        return Math.max(180, timelineScene.height - 2 * 116 - 24)
    }
    readonly property bool hasDateSection: viewMode !== 1 && filteredDates.length > 0
    readonly property bool hasWeekSection: viewMode !== 2 && filteredWeeks.length > 0
    readonly property real dateRowsHeight:
        (filteredDates.length * 104
            + Math.max(0, filteredDates.length - 1) * 8)
        * dateSectionProgress
    readonly property real weekRowsHeight:
        (filteredWeeks.length * 104
            + Math.max(0, filteredWeeks.length - 1) * 8)
        * weekSectionProgress
    readonly property real weekSectionY: hasDateSection ? 38 + dateRowsHeight + 8 : 0
    readonly property real overviewContentHeight: {
        let height = 0
        if (hasDateSection)
            height += 38 + dateRowsHeight
        if (hasWeekSection)
            height += (hasDateSection ? 8 : 0) + 38 + weekRowsHeight
        return height
    }
    readonly property real overviewMaximumOffset: Math.max(
        0, overviewContentHeight - timelineScene.height
    )
    readonly property bool showOverviewScrollBar:
        !transitionActive && !sceneExpanded
        && overviewContentHeight > timelineScene.height + 0.5
    readonly property bool activeAxisHovered: {
        if (expandedIndex < 0)
            return false
        const row = timelineRepeater.itemAt(expandedIndex)
        return row ? row.axisHovered : false
    }

    function sectionHeaderY(isDate) {
        const overviewY = isDate ? 0 : weekSectionY
        if (!transitionActive)
            return overviewY - overviewScrollOffset
        const fromY = isDate ? motionFromDateHeaderY : motionFromWeekHeaderY
        const toY = overviewY - transitionTargetScrollOffset
        return fromY + (toY - fromY) * motionProgress
    }

    function sectionHeaderOpacity() {
        if (!transitionActive)
            return sceneExpanded ? 0 : 1
        if (transitionTargetExpanded)
            return sectionHeadersOpacity
        return Math.max(0, Math.min(1, (motionProgress - 0.75) / 0.25))
    }

    function syncPageIndicator() {
        if (!timelinePageIndicator)
            return
        const index = Math.max(0, expandedIndex)
        if (timelinePageIndicator.currentIndex === index)
            return
        syncingPageIndicator = true
        timelinePageIndicator.currentIndex = index
        syncingPageIndicator = false
    }

    onExpandedIndexChanged: syncPageIndicator()
    Component.onCompleted: syncPageIndicator()

    function timelineDataAt(index) {
        return index >= 0 && index < filteredTimelines.length
            ? filteredTimelines[index].day : ({})
    }

    function rowOverviewY(index) {
        if (index < 0 || index >= filteredTimelines.length)
            return 0
        const day = filteredTimelines[index].day
        if (day.date) {
            const localIndex = filteredDates.findIndex(item =>
                String(item.day.id) === String(day.id))
            return (38 + localIndex * 112) * dateSectionProgress
        }
        const localIndex = filteredWeeks.findIndex(item =>
            String(item.day.id) === String(day.id))
        return weekSectionY
            + (38 + localIndex * 112) * weekSectionProgress
    }

    function rowTargetGeometry(index, focusIndex, isExpanded) {
        const targetWidth = Math.max(0, timelineScene.width - (isExpanded ? 32 : 0))
        const previewScale = Math.max(0.25, (targetWidth - 16) / 1440)
        const activeScale = isExpanded && index === focusIndex
            ? animatedZoom : previewScale
        let contentX = 0
        if (isExpanded && index === focusIndex) {
            const row = timelineRepeater.itemAt(index)
            const entries = row ? row.entries : timelineDataAt(index).entries || []
            if (entries.length) {
                const parts = String(entries[0].startTime).split(":")
                const firstMinute = Number(parts[0]) * 60 + Number(parts[1])
                const target = Math.max(0, firstMinute - 40) * activeScale
                const axisWidth = Math.max(0, targetWidth - 16)
                contentX = Math.min(target, Math.max(0, 1440 * activeScale - axisWidth))
            }
        }
        if (!isExpanded) {
            const scrollOffset = transitionActive
                ? transitionTargetScrollOffset : overviewScrollOffset
            return {
                x: 0,
                y: rowOverviewY(index) - scrollOffset,
                width: timelineScene.width,
                height: 104,
                scale: Math.max(0.25, (timelineScene.width - 16) / 1440),
                contentX: 0,
                visualProgress: 0
            }
        }

        const expandedTop = (timelineScene.height - expandedTimelineHeight) / 2
        let y = expandedTop
        let height = expandedTimelineHeight
        let visualProgress = 1
        if (index < focusIndex) {
            y = expandedTop + (index - focusIndex) * 116
            height = 104
            visualProgress = 0
        } else if (index > focusIndex) {
            y = expandedTop + expandedTimelineHeight + 12
                + (index - focusIndex - 1) * 116
            height = 104
            visualProgress = 0
        }
        return {
            x: 0,
            y: y,
            width: targetWidth,
            height: height,
            scale: activeScale,
            contentX: contentX,
            visualProgress: visualProgress
        }
    }

    function rowGeometry(index) {
        const from = motionFromGeometry[index]
        if (!transitionActive || !from)
            return rowTargetGeometry(index, sceneFocusIndex, sceneExpanded)
        const to = rowTargetGeometry(
            index, transitionTargetIndex, transitionTargetExpanded
        )
        const t = motionProgress
        return {
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t,
            width: from.width + (to.width - from.width) * t,
            height: from.height + (to.height - from.height) * t,
            scale: from.scale + (to.scale - from.scale) * t,
            contentX: from.contentX + (to.contentX - from.contentX) * t,
            visualProgress: from.visualProgress
                + (to.visualProgress - from.visualProgress) * t
        }
    }

    function rowIsVisible(index) {
        const isExpanded = transitionActive
            ? (sceneExpanded || transitionTargetExpanded)
            : sceneExpanded
        if (isExpanded)
            return true
        const day = timelineDataAt(index)
        return day.date
            ? dateSectionProgress > 0.001
            : weekSectionProgress > 0.001
    }

    function rowOpacity(index) {
        if (sceneExpanded || transitionTargetExpanded)
            return 1
        const day = timelineDataAt(index)
        return day.date ? dateSectionProgress : weekSectionProgress
    }

    function clampOverviewOffset(value) {
        return Math.max(0, Math.min(overviewMaximumOffset, value))
    }

    onOverviewMaximumOffsetChanged: setOverviewOffset(overviewScrollOffset)

    function setOverviewOffset(value) {
        overviewWheelAnimation.stop()
        overviewScrollOffset = clampOverviewOffset(value)
    }

    function scrollOverviewByWheel(delta) {
        if (!delta)
            return
        const start = overviewScrollOffset
        const base = overviewWheelAnimation.running
            ? overviewWheelAnimation.to : start
        const target = clampOverviewOffset(base - delta)
        overviewWheelAnimation.stop()
        overviewWheelAnimation.from = start
        overviewWheelAnimation.to = target
        overviewWheelAnimation.restart()
    }

    function captureRowGeometry() {
        const result = []
        for (let i = 0; i < filteredTimelines.length; ++i) {
            const row = timelineRepeater.itemAt(i)
            if (!row) {
                result.push({
                    x: 0, y: rowOverviewY(i) - overviewScrollOffset,
                    width: timelineScene.width, height: 104,
                    scale: Math.max(0.25, (timelineScene.width - 16) / 1440),
                    contentX: 0,
                    visualProgress: 0
                })
                continue
            }
            result.push({
                x: row.x,
                y: row.y,
                width: row.width,
                height: row.height,
                scale: row.animatedScale,
                contentX: row.axisContentX,
                visualProgress: row.visualProgress
            })
        }
        return result
    }

    function startSceneTransition(index, isExpanded) {
        if (isExpanded && (index < 0 || index >= filteredTimelines.length))
            return
        if (!isExpanded && !sceneExpanded && !transitionTargetExpanded)
            return
        if (isExpanded && !transitionActive && sceneExpanded
                && index === sceneFocusIndex)
            return

        replacingTransition = true
        sceneAnimation.stop()
        replacingTransition = false
        overviewWheelAnimation.stop()

        const fromHeaderOpacity = sectionHeaderOpacity()
        const fromDateHeaderY = dateSectionHeader.y
        const fromWeekHeaderY = weekSectionHeader.y
        const from = captureRowGeometry()
        for (let i = 0; i < filteredTimelines.length; ++i) {
            const row = timelineRepeater.itemAt(i)
            if (row)
                row.releaseScaleAnchor()
        }
        const focusIndex = isExpanded ? index
            : (transitionActive && transitionTargetExpanded
                ? transitionTargetIndex : sceneFocusIndex)
        transitionTargetScrollOffset = isExpanded
            ? overviewScrollOffset
            : clampOverviewOffset(
                rowOverviewY(focusIndex) - (timelineScene.height - 104) / 2
            )
        motionFromGeometry = from
        motionFromDateHeaderY = fromDateHeaderY
        motionFromWeekHeaderY = fromWeekHeaderY
        transitionTargetIndex = focusIndex
        transitionTargetExpanded = isExpanded
        transitionActive = true
        motionProgress = 0
        headerFadeAnimation.stop()
        sectionHeadersOpacity = fromHeaderOpacity
        if (isExpanded) {
            headerFadeAnimation.from = fromHeaderOpacity
            headerFadeAnimation.to = 0
            headerFadeAnimation.restart()
        } else {
            sectionHeadersOpacity = 0
        }

        toolbarVisible = false
        if (!isExpanded) {
            pageIndicatorFadeAnimation.stop()
            pageIndicatorFadeAnimation.from = pageIndicatorOpacity
            pageIndicatorFadeAnimation.to = 0
            pageIndicatorFadeAnimation.restart()
        } else if (!sceneExpanded) {
            pageIndicatorFadeAnimation.stop()
            pageIndicatorOpacity = 0
        }
        if (isExpanded) {
            expandedIndex = index
            activeTimelineId = filteredTimelines[index].day.id
            selectedEntryId = ""
            refreshHistoryAvailability()
        }

        sceneAnimation.restart()
    }

    function setExpanded(index) {
        if (index < 0 || index >= filteredTimelines.length)
            return
        startSceneTransition(index, true)
    }

    function expandTimeline(dayId) {
        for (let i = 0; i < filteredTimelines.length; ++i) {
            if (String(filteredTimelines[i].day.id) === String(dayId)) {
                setExpanded(i)
                return
            }
        }
    }

    function navigateTimeline(delta) {
        if ((!sceneExpanded && !transitionTargetExpanded)
                || !filteredTimelines.length)
            return
        const current = transitionActive ? transitionTargetIndex : sceneFocusIndex
        const next = Math.max(0, Math.min(filteredTimelines.length - 1, current + delta))
        if (next !== current)
            startSceneTransition(next, true)
    }

    function collapseTimeline() {
        if (transitionActive && !transitionTargetExpanded)
            return
        if (!sceneExpanded && !transitionTargetExpanded)
            return
        startSceneTransition(
            transitionActive ? transitionTargetIndex : sceneFocusIndex, false
        )
    }

    function finishSceneTransition() {
        if (replacingTransition)
            return
        sceneExpanded = transitionTargetExpanded
        sceneFocusIndex = transitionTargetIndex
        if (sceneExpanded) {
            expandedIndex = sceneFocusIndex
            activeTimelineId = timelineDataAt(sceneFocusIndex).id || ""
            toolbarVisible = true
            overviewScrollOffset = transitionTargetScrollOffset
            pageIndicatorFadeAnimation.from = pageIndicatorOpacity
            pageIndicatorFadeAnimation.to = 1
            pageIndicatorFadeAnimation.restart()
        } else {
            expandedIndex = -1
            activeTimelineId = ""
            selectedEntryId = ""
            undoAvailable = false
            redoAvailable = false
            toolbarVisible = false
            pageIndicatorFadeAnimation.stop()
            pageIndicatorOpacity = 0
            overviewScrollOffset = transitionTargetScrollOffset
        }
        transitionActive = false
        motionFromGeometry = []
        for (let i = 0; i < filteredTimelines.length; ++i) {
            const row = timelineRepeater.itemAt(i)
            if (row)
                row.releaseScaleAnchor()
        }
        if (!sceneExpanded && pendingViewMode >= 0) {
            viewMode = pendingViewMode
            pendingViewMode = -1
            setOverviewOffset(0)
        }
    }

    function setZoom(value) {
        const row = expandedIndex >= 0 ? timelineRepeater.itemAt(expandedIndex) : null
        if (!row || transitionActive)
            return

        replacingZoomAnimation = true
        zoomAnimation.stop()
        replacingZoomAnimation = false
        row.setScaleAnchor(
            (row.axisContentX + row.axisWidth / 2) / Math.max(0.001, row.animatedScale),
            row.axisWidth / 2
        )
        zoom = value
        zoomAnimation.from = animatedZoom
        zoomAnimation.to = value
        zoomAnimation.restart()
    }

    function addEntry(type) {
        let duration = Configs.data.schedule.default_duration.class_ || 40
        if (type === "break")
            duration = Configs.data.schedule.default_duration.break_ || 10
        else if (type === "activity")
            duration = Configs.data.schedule.default_duration.activity || 30
        const result = AppCentral.scheduleEditor.addEntryAfter(
            activeTimelineId, type, selectedEntryId, duration
        )
        if (!result.ok && result.reason === "conflict") {
            floatLayer.createInfoBar({
                title: qsTr("Conflict with existing schedule"),
                text: qsTr("This time overlaps with an existing schedule (%1 – %2)")
                    .arg(result.conflict.startTime)
                    .arg(result.conflict.endTime),
                severity: Severity.Warning
            })
            return
        }
        const newEntryId = result.ok ? result.id : ""
        if (newEntryId) {
            selectedEntryId = newEntryId
            Qt.callLater(function() {
                const row = expandedIndex >= 0
                    ? timelineRepeater.itemAt(expandedIndex) : null
                if (row)
                    row.focusEntry(newEntryId, true)
            })
        }
    }

    function entryExists(entryId) {
        if (!entryId)
            return false
        const day = AppCentral.scheduleEditor.getDay(activeTimelineId)
        const entries = day && day.entries ? day.entries : []
        return entries.some(entry => String(entry.id) === String(entryId))
    }

    function openTimelineSettings() {
        const parts = String(AppCentral.scheduleEditor.getStartDate()).split("-")
        const startDate = new Date(
            Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])
        )
        settingsDialog.openFor(
            startDate, AppCentral.scheduleEditor.getMaxWeekCycle()
        )
    }

    function refreshHistoryAvailability() {
        undoAvailable = activeTimelineId !== ""
            && AppCentral.scheduleEditor.canUndoEntryChanges(activeTimelineId)
        redoAvailable = activeTimelineId !== ""
            && AppCentral.scheduleEditor.canRedoEntryChanges(activeTimelineId)
    }

    function undo() {
        if (activeTimelineId
                && AppCentral.scheduleEditor.undoEntryChanges(activeTimelineId))
            refreshHistoryAvailability()
    }

    function redo() {
        if (activeTimelineId
                && AppCentral.scheduleEditor.redoEntryChanges(activeTimelineId))
            refreshHistoryAvailability()
    }

    property bool toolbarVisible: false
    property bool replacingZoomAnimation: false

    NumberAnimation {
        id: sceneAnimation
        target: root
        property: "motionProgress"
        to: 1
        duration: 460
        easing.type: Easing.InOutCubic
        onStopped: {
            if (!root.replacingTransition)
                root.finishSceneTransition()
        }
    }
    NumberAnimation {
        id: zoomAnimation
        target: root
        property: "animatedZoom"
        duration: 220
        easing.type: Easing.OutCubic
        onStopped: {
            if (!root.replacingZoomAnimation && root.expandedIndex >= 0) {
                const row = timelineRepeater.itemAt(root.expandedIndex)
                if (row)
                    row.releaseScaleAnchor()
            }
        }
    }
    NumberAnimation {
        id: headerFadeAnimation
        target: root
        property: "sectionHeadersOpacity"
        duration: 220
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: dateSectionAnimation
        target: root
        property: "dateSectionProgress"
        duration: 220
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: weekSectionAnimation
        target: root
        property: "weekSectionProgress"
        duration: 220
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: overviewWheelAnimation
        target: root
        property: "overviewScrollOffset"
        duration: 220
        easing.type: Easing.OutCubic
    }
    NumberAnimation {
        id: pageIndicatorFadeAnimation
        target: root
        property: "pageIndicatorOpacity"
        duration: 180
        easing.type: Easing.OutCubic
    }
    Timer {
        id: wheelGestureTimer
        interval: 380
        onTriggered: root.wheelPagePending = false
    }
    Connections {
        target: AppCentral.scheduleEditor
        function onEntriesChanged() {
            if (root.selectedEntryId
                    && !root.entryExists(root.selectedEntryId))
                root.selectedEntryId = ""
        }
        function onEntryHistoryChanged(dayId) {
            if (String(dayId) === String(root.activeTimelineId))
                root.refreshHistoryAvailability()
        }
        function onDaysChanged() {
            if (root.activeTimelineId
                    && !AppCentral.scheduleEditor.getDay(root.activeTimelineId))
                root.collapseTimeline()
        }
    }

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
            compactTopBar: root.compactTopBar
            viewMode: root.viewMode
            pendingViewMode: root.pendingViewMode

            onViewModeRequested: function(index) {
                if (root.sceneExpanded || root.transitionTargetExpanded) {
                    root.pendingViewMode = index
                    root.collapseTimeline()
                } else {
                    root.viewMode = index
                }
            }
            onSettingsRequested: root.openTimelineSettings()
            onNewTimelineRequested: dayEditor.openFor(null)
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
                    xAxis.enabled: false
                    yAxis.enabled: true
                    grabPermissions: PointerHandler.CanTakeOverFromAnything
                    property real startingOverviewOffset: 0
                    property bool changedPage: false
                    onActiveChanged: {
                        if (!active)
                            return
                        // The animation id is local to this component, not a root property.
                        overviewWheelAnimation.stop()
                        startingOverviewOffset = root.overviewScrollOffset
                        changedPage = false
                    }
                    onTranslationChanged: {
                        if (!active)
                            return
                        if (root.sceneExpanded || root.transitionTargetExpanded) {
                            if (changedPage || Math.abs(translation.y) < 48)
                                return
                            changedPage = true
                            root.navigateTimeline(translation.y < 0 ? 1 : -1)
                            return
                        }
                        root.setOverviewOffset(startingOverviewOffset - translation.y)
                    }
                }

                WheelHandler {
                    id: sceneWheel
                    onWheel: function(event) {
                        const horizontal = event.pixelDelta.x || event.angleDelta.x
                        const vertical = event.pixelDelta.y || event.angleDelta.y
                        if (Math.abs(horizontal) > Math.abs(vertical))
                            return
                        if (!vertical)
                            return

                        if (root.sceneExpanded || root.transitionTargetExpanded) {
                            if (root.activeAxisHovered)
                                return
                            event.accepted = true
                            if (root.wheelPagePending)
                                return
                            root.wheelPagePending = true
                            wheelGestureTimer.restart()
                            root.navigateTimeline(vertical < 0 ? 1 : -1)
                            return
                        }

                        event.accepted = true
                        const delta = event.pixelDelta.y
                            || Math.sign(event.angleDelta.y) * 44
                        root.scrollOverviewByWheel(delta)
                    }
                }

                TimelineSectionHeader {
                    id: dateSectionHeader
                    x: 0
                    y: root.sectionHeaderY(true)
                    opacity: root.sectionHeaderOpacity()
                    width: timelineScene.width
                    visible: root.hasDateSection && opacity > 0
                    title: qsTr("By Date")
                    expanded: root.dateSectionExpanded
                    filterModel1: root.monthFilterModel
                    filterModel2: root.yearFilterModel
                    filterIndex1: root.monthFilterIndex
                    filterIndex2: Math.max(0,
                        root.yearFilterModel.indexOf(root.yearFilter))

                    onExpandedToggled: function(expanded) {
                        root.dateSectionExpanded = expanded
                        if (!expanded && root.expandedIndex >= 0
                                && root.timelineDataAt(root.expandedIndex).date)
                            root.collapseTimeline()
                    }
                    onFilterActivated1: function(index) {
                        root.monthFilterIndex = index
                        root.collapseTimeline()
                    }
                    onFilterActivated2: function(index, text) {
                        root.yearFilter = index === 0 ? "" : text
                        root.collapseTimeline()
                    }
                }

                TimelineSectionHeader {
                    id: weekSectionHeader
                    x: 0
                    y: root.sectionHeaderY(false)
                    opacity: root.sectionHeaderOpacity()
                    width: timelineScene.width
                    visible: root.hasWeekSection && opacity > 0
                    title: qsTr("By Week")
                    expanded: root.weekSectionExpanded
                    filterModel1: root.weekdayFilterModel
                    filterIndex1: root.weekFilterIndex

                    onExpandedToggled: function(expanded) {
                        root.weekSectionExpanded = expanded
                        if (!expanded && root.expandedIndex >= 0
                                && !root.timelineDataAt(root.expandedIndex).date)
                            root.collapseTimeline()
                    }
                    onFilterActivated1: function(index) {
                        root.weekFilterIndex = index
                        root.collapseTimeline()
                    }
                }

                Repeater {
                    id: timelineRepeater
                    objectName: "timelineRepeater"
                    model: root.filteredTimelines.length
                    delegate: TimelineRow {
                        id: timelineRow
                        property var sceneGeometry: root.rowGeometry(index)
                        x: sceneGeometry.x
                        y: sceneGeometry.y
                        width: sceneGeometry.width
                        layoutHeight: sceneGeometry.height
                        animatedScale: sceneGeometry.scale
                        visualProgress: sceneGeometry.visualProgress
                        sceneContentX: sceneGeometry.contentX
                        layoutControlled: root.transitionActive
                        detailsVisible: root.toolbarVisible && expanded
                        visible: root.rowIsVisible(index)
                        opacity: root.rowOpacity(index)
                        timeline: root.filteredTimelines[index].day
                        timelineIndex: index
                        expanded: root.transitionActive
                            ? root.transitionTargetExpanded
                                && index === root.transitionTargetIndex
                            : root.sceneExpanded && index === root.sceneFocusIndex
                        interactionEnabled: root.sceneExpanded
                            && !root.transitionActive && index === root.sceneFocusIndex
                        zoom: root.animatedZoom
                        readOnlyTimeline: AppCentral.scheduleManager.isReadonly()
                        toolbarVisible: root.toolbarVisible && expanded
                        selectedEntryId: expanded ? root.selectedEntryId : ""
                        undoAvailable: expanded && root.undoAvailable
                        redoAvailable: expanded && root.redoAvailable
                        z: expanded ? 3 : 1

                        onRequestExpand: function(rowIndex) {
                            root.setExpanded(rowIndex)
                        }
                        onRequestCollapse: root.collapseTimeline()
                        onEditRulesRequested: function(day) { dayEditor.openFor(day) }
                        onEntrySelected: function(entryId, entryIndex) {
                            if (root.sceneFocusIndex === index || root.transitionTargetIndex === index)
                                root.selectedEntryId = entryId
                        }
                        onSelectionCleared: {
                            if (!root.transitionActive
                                    && root.sceneFocusIndex === index)
                                root.selectedEntryId = ""
                        }
                        onUndoRequested: root.undo()
                        onRedoRequested: root.redo()
                        onAddRequested: function(type) { root.addEntry(type) }
                        onZoomRequested: function(value) { root.setZoom(value) }
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
                    visible: root.showOverviewScrollBar
                    policy: visible ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    size: root.overviewContentHeight > 0
                        ? Math.min(1, timelineScene.height / root.overviewContentHeight) : 1
                    position: root.overviewContentHeight > 0
                        ? root.overviewScrollOffset / root.overviewContentHeight : 0
                    onPositionChanged: {
                        if (pressed)
                            root.setOverviewOffset(position * root.overviewContentHeight)
                    }
                }
            }

            Item {
                id: pageIndicator
                visible: root.pageIndicatorOpacity > 0.001
                opacity: root.pageIndicatorOpacity
                z: 4
                width: 24
                height: Math.min(sceneHost.height,
                    Math.max(48, root.filteredTimelines.length * 12 + 48))
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
                    count: root.filteredTimelines.length
                    currentIndex: 0
                    interactive: root.filteredTimelines.length > 1
                    onCurrentIndexChanged: {
                        if (!root.syncingPageIndicator
                                && pageIndicator.visible && currentIndex >= 0
                                && currentIndex < root.filteredTimelines.length
                                && currentIndex !== root.expandedIndex)
                            root.setExpanded(currentIndex)
                    }
                }
            }
        }

    }

    DayEditor { id: dayEditor }

    TimelineSettingsDialog {
        id: settingsDialog
        onSettingsAccepted: function(dateString, maxWeekCycle) {
            if (!AppCentral.scheduleEditor.setTimelineSettings(
                    dateString, maxWeekCycle)) {
                floatLayer.createInfoBar({
                    title: qsTr("Failed"),
                    text: qsTr("Failed to set start date or max week cycle."),
                    severity: Severity.Error,
                    duration: 5000
                })
            }
        }
    }
}
