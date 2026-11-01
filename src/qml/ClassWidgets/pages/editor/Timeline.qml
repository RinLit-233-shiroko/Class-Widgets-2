import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import RinUI
import ClassWidgets.Components
import ClassWidgets.Easing
import "../../Components/editor/WeekRule.js" as WeekRule
import "../../Components/editor/ZoomMath.js" as ZoomMath

Item {
    id: root

    property var timelines: AppCentral.scheduleEditor.days || []
    readonly property var subjects: AppCentral.scheduleEditor.subjects || []
    readonly property bool readOnlyTimeline:
        AppCentral.scheduleManager.isReadonly()
    readonly property int maxWeekCycle:
        AppCentral.scheduleEditor.meta.maxWeekCycle || 1
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
    property string pendingCreatedTimelineId: ""
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
        const values = [qsTr("All days of the week")]
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
    readonly property bool textInputFocused: {
        const item = Window.activeFocusItem
        return item !== null && item.cursorPosition !== undefined
    }

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
                dates.push({
                    day: day,
                    sourceIndex: i,
                    sectionIndex: dates.length
                })
                continue
            }
            const selectedDays = WeekRule.dayList(day.dayOfWeek)
            if (selectedWeekday > 0
                    && selectedDays.indexOf(selectedWeekday) < 0)
                continue
            weeks.push({
                day: day,
                sourceIndex: i,
                    sectionIndex: weeks.length
            })
        }
        function priority(item) {
            const day = item.day
            if (day.date)
                return [4, 0, 0]
            const days = WeekRule.dayList(day.dayOfWeek)
            const dayPriority = days.length ? 7 - days.length : 0
            const kind = WeekRule.kind(day.weeks)
            const weekPriority = kind === "specific" ? 3
                : (kind === "all" ? 1 : 2)
            return [0, dayPriority, weekPriority, days.length ? days[0] : 8]
        }
        function compare(left, right) {
            const a = priority(left)
            const b = priority(right)
            for (let i = 0; i < a.length - 1; ++i) {
                if (a[i] !== b[i])
                    return b[i] - a[i]
            }
            // Equal-specificity weekday rules use Monday-first ordering.
            if (a[a.length - 1] !== b[b.length - 1])
                return a[a.length - 1] - b[b.length - 1]
            // Keep the original order for equal-priority rules.
            return left.sourceIndex - right.sourceIndex
        }
        dates.sort(compare)
        weeks.sort(compare)
        for (let i = 0; i < dates.length; ++i)
            dates[i].sectionIndex = i
        for (let i = 0; i < weeks.length; ++i)
            weeks[i].sectionIndex = i
        if (viewMode === 1)
            return weeks
        if (viewMode === 2)
            return dates
        return dates.concat(weeks)
    }
    readonly property var filteredTimelines: matchingTimelines
    property var entriesByDayId: ({})

    function rebuildEntriesByDayId() {
        const days = AppCentral.scheduleEditor.entriesData || []
        const result = ({})
        for (let i = 0; i < days.length; ++i)
            result[String(days[i].id)] = days[i].entries || []
        entriesByDayId = result
    }

    function refreshEntriesForDay(dayId) {
        const days = AppCentral.scheduleEditor.entriesData || []
        const key = String(dayId)
        let found = false
        let entries = []
        for (let i = 0; i < days.length; ++i) {
            if (String(days[i].id) !== key)
                continue
            entries = days[i].entries || []
            found = true
            break
        }
        if (!found)
            return

        // Mutate the lookup in place. Replacing the whole object would
        // invalidate every row's entries binding even though only one day
        // changed.
        entriesByDayId[key] = entries
        for (let i = 0; i < filteredTimelines.length; ++i) {
            if (String(filteredTimelines[i].day.id) !== key)
                continue
            const row = overview.rowRepeater.itemAt(i)
            if (row)
                row.setEntries(entries)
            break
        }
    }
    readonly property var filteredDates: matchingTimelines.filter(item => !!item.day.date)
    readonly property var filteredWeeks: matchingTimelines.filter(item => !item.day.date)
    readonly property real expandedTimelineHeight: {
        return Math.max(180, overview.sceneItem.height - 2 * 116 - 24)
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
        0, overviewContentHeight - overview.sceneItem.height
    )
    readonly property bool showOverviewScrollBar:
        !transitionActive && !sceneExpanded
        && overviewContentHeight > overview.sceneItem.height + 0.5
    readonly property bool activeAxisHovered: {
        if (expandedIndex < 0)
            return false
        const row = overview.rowRepeater.itemAt(expandedIndex)
        return row ? row.axisHovered : false
    }
    readonly property bool activeDetailOpen: {
        if (expandedIndex < 0)
            return false
        const row = overview.rowRepeater.itemAt(expandedIndex)
        return row ? row.detailOpen : false
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
        const indicator = overview.pageIndicatorControl
        if (!indicator)
            return
        const index = Math.max(0, expandedIndex)
        if (indicator.currentIndex === index)
            return
        syncingPageIndicator = true
        indicator.currentIndex = index
        syncingPageIndicator = false
    }

    onExpandedIndexChanged: syncPageIndicator()
    Component.onCompleted: {
        syncPageIndicator()
        rebuildEntriesByDayId()
    }

    function timelineDataAt(index) {
        return index >= 0 && index < filteredTimelines.length
            ? filteredTimelines[index].day : ({})
    }

    function rowOverviewY(index) {
        if (index < 0 || index >= filteredTimelines.length)
            return 0
        const item = filteredTimelines[index]
        if (item.day.date)
            return 38 + item.sectionIndex * 112 * dateSectionProgress
        return weekSectionY
            + 38 + item.sectionIndex * 112 * weekSectionProgress
    }

    function rowOverviewHeight(index) {
        if (index < 0 || index >= filteredTimelines.length)
            return 0
        const progress = filteredTimelines[index].day.date
            ? dateSectionProgress : weekSectionProgress
        return 104 * progress
    }

    function rowSectionOpacity(index) {
        if (index < 0 || index >= filteredTimelines.length)
            return 0
        const progress = filteredTimelines[index].day.date
            ? dateSectionProgress : weekSectionProgress
        // Keep a little presence while the cards are compressing, then let
        // them leave with the last part of the section motion.
        return Math.pow(Math.max(0, Math.min(1, progress)), 0.7)
    }

    function rowTargetGeometry(index, focusIndex, isExpanded) {
        const targetWidth = Math.max(0,
            overview.sceneItem.width - (isExpanded ? 32 : 0))
        const previewScale = Math.max(0.25, (targetWidth - 16) / 1440)
        const activeScale = isExpanded && index === focusIndex
            ? animatedZoom : previewScale
        let contentX = 0
        if (isExpanded && index === focusIndex) {
            const row = overview.rowRepeater.itemAt(index)
            const entries = row ? row.entries : timelineDataAt(index).entries || []
            if (entries.length) {
                const parts = String(entries[0].startTime).split(":")
                const firstMinute = Number(parts[0]) * 60 + Number(parts[1])
                const axisWidth = Math.max(0, targetWidth - 22)
                const target = firstMinute * activeScale - axisWidth * 0.4
                contentX = Math.max(0, Math.min(
                    target, 1440 * activeScale - axisWidth
                ))
            }
        }
        if (!isExpanded) {
            const scrollOffset = transitionActive
                ? transitionTargetScrollOffset : overviewScrollOffset
            return {
                x: 0,
                y: rowOverviewY(index) - scrollOffset,
                width: overview.sceneItem.width,
                height: rowOverviewHeight(index),
                scale: Math.max(0.25,
                    (overview.sceneItem.width - 16) / 1440),
                contentX: 0,
                visualProgress: 0
            }
        }

        const expandedTop =
            (overview.sceneItem.height - expandedTimelineHeight) / 2
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
        return rowSectionOpacity(index)
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
            const row = overview.rowRepeater.itemAt(i)
            if (!row) {
                result.push({
                    x: 0, y: rowOverviewY(i) - overviewScrollOffset,
                    width: overview.sceneItem.width,
                    height: rowOverviewHeight(i),
                    scale: Math.max(0.25,
                        (overview.sceneItem.width - 16) / 1440),
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
        const fromDateHeaderY = overview.dateHeader.y
        const fromWeekHeaderY = overview.weekHeader.y
        const from = captureRowGeometry()
        for (let i = 0; i < filteredTimelines.length; ++i) {
            const row = overview.rowRepeater.itemAt(i)
            if (row)
                row.releaseScaleAnchor()
        }
        const focusIndex = isExpanded ? index
            : (transitionActive && transitionTargetExpanded
                ? transitionTargetIndex : sceneFocusIndex)
        transitionTargetScrollOffset = isExpanded
            ? overviewScrollOffset
            : clampOverviewOffset(
                rowOverviewY(focusIndex)
                    - (overview.sceneItem.height - 104) / 2
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
            const row = overview.rowRepeater.itemAt(i)
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
        const row = expandedIndex >= 0
            ? overview.rowRepeater.itemAt(expandedIndex) : null
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

    function applyPinchZoom(value, anchorMinute, anchorPixel) {
        const row = expandedIndex >= 0
            ? overview.rowRepeater.itemAt(expandedIndex) : null
        if (!row || transitionActive)
            return

        const overviewMinZoom = Math.max(0.25,
            Math.min(2.1, row.previewScale))
        const minZoom = Math.max(1.5, overviewMinZoom)
        const maxZoom = 4.4 - overviewMinZoom
        const next = ZoomMath.clamp(value, minZoom, maxZoom)

        replacingZoomAnimation = true
        zoomAnimation.stop()
        replacingZoomAnimation = false
        row.setScaleAnchor(anchorMinute, anchorPixel)
        zoom = next
        animatedZoom = next
    }

    function finishPinchZoom() {
        const row = expandedIndex >= 0
            ? overview.rowRepeater.itemAt(expandedIndex) : null
        if (row)
            row.releaseScaleAnchor()
        zoom = animatedZoom
    }

    function adjustZoomBy(delta) {
        if (expandedIndex < 0 || transitionActive)
            return
        const row = overview.rowRepeater.itemAt(expandedIndex)
        if (!row)
            return
        const overviewMinZoom = Math.max(0.25,
            Math.min(2.1, row.previewScale))
        const minZoom = Math.max(1.5, overviewMinZoom)
        const maxZoom = 4.4 - overviewMinZoom
        setZoom(ZoomMath.steppedZoom(
            animatedZoom, delta, minZoom, maxZoom
        ))
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
                    ? overview.rowRepeater.itemAt(expandedIndex) : null
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

    function createTimeline(ruleMode) {
        dayEditor.openFor(null, ruleMode)
    }

    function editTimelineRules(day) {
        dayEditor.openFor(day)
    }

    function stopOverviewWheelAnimation() {
        overviewWheelAnimation.stop()
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

    function requestTimelineDelete(timeline) {
        if (!timeline || !timeline.id)
            return
        pendingDeleteTimeline = timeline
        deleteTimelineDialog.open()
    }

    function duplicateTimeline(dayId) {
        pendingCreatedTimelineId = AppCentral.scheduleEditor.duplicateDay(dayId) || ""
    }

    function revealCreatedTimeline() {
        if (!pendingCreatedTimelineId)
            return
        for (let i = 0; i < filteredTimelines.length; ++i) {
            if (String(filteredTimelines[i].day.id)
                    !== String(pendingCreatedTimelineId))
                continue
            pendingCreatedTimelineId = ""
            Qt.callLater(function() { root.setExpanded(i) })
            return
        }
    }

    property bool toolbarVisible: false
    property bool replacingZoomAnimation: false
    property var pendingDeleteTimeline: null

    NumberAnimation {
        id: sceneAnimation
        target: root
        property: "motionProgress"
        to: 1
        duration: 420
        easing.type: Easing.Bezier
        easing.bezierCurve: BezierCurve.timelineScene
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
                const row = overview.rowRepeater.itemAt(root.expandedIndex)
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
        duration: 280
        easing.type: Easing.OutQuint
    }
    NumberAnimation {
        id: weekSectionAnimation
        target: root
        property: "weekSectionProgress"
        duration: 280
        easing.type: Easing.OutQuint
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
            root.rebuildEntriesByDayId()
            root.revealCreatedTimeline()
            if (root.activeTimelineId
                    && !AppCentral.scheduleEditor.getDay(root.activeTimelineId))
                root.collapseTimeline()
        }
        function onDayEntriesChanged(dayId) {
            if (dayId === "")
                root.rebuildEntriesByDayId()
            else
                root.refreshEntriesForDay(dayId)
        }
    }

    Shortcut {
        sequence: "Ctrl++"
        onActivated: root.adjustZoomBy(0.1)
    }
    Shortcut {
        sequence: "Ctrl+="
        onActivated: root.adjustZoomBy(0.1)
    }
    Shortcut {
        sequence: "Ctrl+-"
        onActivated: root.adjustZoomBy(-0.1)
    }
    Shortcut {
        sequence: "Ctrl+Z"
        enabled: root.activeTimelineId !== "" && !root.textInputFocused
        onActivated: root.undo()
    }
    Shortcut {
        sequence: "Ctrl+Y"
        enabled: root.activeTimelineId !== "" && !root.textInputFocused
        onActivated: root.redo()
    }
    Shortcut {
        sequence: "Ctrl+Shift+Z"
        enabled: root.activeTimelineId !== "" && !root.textInputFocused
        onActivated: root.redo()
    }

    TimelineOverview {
        id: overview
        anchors.fill: parent
        page: root
    }

    DayEditor {
        id: dayEditor
        onTimelineCreated: function(dayId) {
            root.pendingCreatedTimelineId = dayId
            close()
            root.revealCreatedTimeline()
        }
    }

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

    Dialog {
        id: deleteTimelineDialog
        modal: true
        title: qsTr("Delete timeline?")

        Text {
            Layout.fillWidth: true
            text: qsTr("This timeline and all its activities will be removed. This action cannot be undone.")
        }

        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            if (root.pendingDeleteTimeline)
                AppCentral.scheduleEditor.removeDay(root.pendingDeleteTimeline.id)
            root.pendingDeleteTimeline = null
        }
        onRejected: root.pendingDeleteTimeline = null
    }
}
