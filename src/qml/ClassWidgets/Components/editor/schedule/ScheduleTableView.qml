import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Components
import "../WeekRule.js" as WeekRule

/*
 * Calendar-style schedule table.
 *
 * Logical rows stay exactly the same as before: row is the ordinal index of a
 * Class entry in its day. The compressed axis below is display-only and is
 * never used to read or write schedule data.
 */
Item {
    id: root
    clip: true

    readonly property int timeGutterWidth: 60
    readonly property int headerHeight: 60
    property real zoomFactor: 1.0
    readonly property real pxPerMin: 1.45 * zoomFactor
    // One grid division is always half an hour, matching the timeline ruler.
    readonly property int gridIntervalMinutes: 30
    // Only gaps longer than this collapse into a divider band. Shorter gaps
    // keep their real duration, otherwise one division would shrink or stretch
    // depending on where the courses happen to sit.
    readonly property int dividerBandMinutes: 30
    readonly property int separatorBandHeight: 28
    readonly property int compactGapHeight: 4
    readonly property int cardTopInset: 4
    readonly property int cardHorizontalInset: 4
    // Mirrors ScheduleCourseCard's content geometry for time-line visibility.
    readonly property int cardTimeLineHeight: 14
    readonly property int mergedContentTopInset: 12
    readonly property int bottomPadding: 28
    property int itemWidth: Math.max((width - timeGutterWidth) / 7, 120)

    // Current absolute week (calculated from the semester start date).
    property int currentWeek: 1

    // First date of the current week (Monday).
    readonly property var weekStart: weekStartFor(currentWeek)

    // Existing public selection state.
    property var selectedCell: ({ row: -1, column: -1 })
    property var currentEntry: null
    readonly property int maxRows: {
        let result = 0
        const columns = effectiveEntries || []
        for (let column = 0; column < columns.length; ++column)
            result = Math.max(result, (columns[column] || []).length)
        return result
    }

    property int entriesRevision: AppCentral.scheduleEditor.entriesRevision
    property int overridesRevision: AppCentral.scheduleEditor.overridesRevision
    property var effectiveEntries: {
        // Explicit dependency reads keep the one batch query in sync with edits.
        const entriesRevisionValue = entriesRevision
        const overridesRevisionValue = overridesRevision
        return AppCentral.scheduleEditor.getEffectiveEntries(currentWeek)
    }

    property var subjects: AppCentral.scheduleEditor.subjects || []

    // The axis contains only occupied course time. The time scale stays
    // proportional so that one division is always half an hour; only gaps
    // longer than the divider band threshold are cut out of the axis.
    readonly property var timeAxis: buildTimeAxis()
    readonly property var timeGridLines: buildTimeGridLines()
    readonly property var timeLabels: {
        const grid = timeGridLines || []
        const result = []
        for (let i = 0; i < grid.length; ++i) {
            if (grid[i].major)
                result.push({ y: grid[i].y, text: axisLabel(grid[i].minutes) })
        }
        return result
    }
    readonly property var separators: buildSeparators()

    signal cellClicked(int row, int column, var entry, Item delegate)
    // Emitted when the selection is dropped by clicking the background.
    signal selectionCleared()

    // ── Date / weekday helpers ─────────────────────────

    function parseDate(str) {
        const parts = String(str).split("-")
        return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
    }

    // Start date (Monday) of the given absolute week, falling back to this week.
    // The backend numbers weeks from meta.startDate (get_week_number) and
    // numbers days ISO-style, so the displayed week is the Monday-based week
    // holding the backend's week. A Monday startDate makes the two the same day.
    function weekStartFor(week) {
        let start = parseDate(AppCentral.scheduleEditor.meta.startDate)
        if (!isFinite(start.getTime()))
            start = new Date()
        const block = new Date(start.getTime() + (week - 1) * 7 * 86400000)
        const isoDay = block.getDay() === 0 ? 7 : block.getDay()
        block.setDate(block.getDate() - (isoDay - 1))
        return block
    }

    // Absolute week whose Monday (weekStart) holds the given date. The backend
    // numbers weeks from meta.startDate, which only matches Monday-based weeks
    // when startDate is itself a Monday. This reverses weekStartFor() so a
    // non-Monday startDate still resolves "today" to the Monday-based week the
    // table actually displays. isoweekday(startDate) is invariant under +7d
    // steps, so the Monday offset is constant and we can solve for W directly.
    function weekForDate(date) {
        let start = parseDate(AppCentral.scheduleEditor.meta.startDate)
        if (!isFinite(start.getTime()))
            start = new Date()
        const isoStart = start.getDay() === 0 ? 7 : start.getDay()

        const monday = new Date(date.getTime())
        const isoDay = monday.getDay() === 0 ? 7 : monday.getDay()
        monday.setDate(monday.getDate() - (isoDay - 1))

        const delta = (monday.getTime() - start.getTime()) / 86400000 + isoStart - 1
        return Math.max(1, Math.floor(delta / 7) + 1)
    }

    // 1=Monday ... 7=Sunday, matching the backend. Columns run Monday ... Sunday,
    // the same order getEffectiveEntries() returns.
    function dayOfWeekForColumn(columnIndex) {
        return columnIndex + 1
    }

    // Absolute week -> cycle week.
    function cycleWeekFor(week) {
        return WeekRule.cycleWeek(week, AppCentral.scheduleEditor.meta.maxWeekCycle)
    }

    function isWeekActive(weeks) {
        // `weeks` comes from ScheduleEditor.entriesData, where a Python list is
        // an array-like sequence rather than a JS Array.
        return WeekRule.matches(weeks, currentWeek, AppCentral.scheduleEditor.meta.maxWeekCycle)
    }

    function getDayByColumn(columnIndex) {
        const weekday = dayOfWeekForColumn(columnIndex)
        const days = AppCentral.scheduleEditor.entriesData

        for (let i = 0; i < days.length; i++) {
            const day = days[i]
            if (day.date)
                continue

            const validDay = WeekRule.dayMatches(day.dayOfWeek, weekday)
            const validWeek = isWeekActive(day.weeks)
            if (validDay && validWeek)
                return day
        }
        return null
    }

    // Returns the resolved entry for the original logical row/column pair.
    function getEntryByDayAndRow(day, row, columnIndex) {
        const columns = effectiveEntries
        if (!columns || columnIndex < 0 || columnIndex >= columns.length)
            return null
        const entries = columns[columnIndex]
        return entries && row >= 0 && row < entries.length ? entries[row] : null
    }

    function toMinutes(value) {
        if (value === null || value === undefined)
            return NaN
        const parts = String(value).split(":")
        if (parts.length < 2)
            return NaN
        const hours = Number(parts[0])
        const minutes = Number(parts[1])
        if (!isFinite(hours) || !isFinite(minutes))
            return NaN
        return hours * 60 + minutes
    }

    function axisLabel(minutes) {
        let hours = Math.floor(minutes / 60)
        const mins = minutes % 60
        const suffix = hours >= 12 ? " PM" : " AM"
        hours = hours % 12
        if (hours === 0)
            hours = 12
        if (mins === 0)
            return hours + suffix
        return hours + ":" + (mins < 10 ? "0" : "") + mins + suffix
    }

    // ── Card data ──────────────────────────────────────

    function subjectById(subjectId) {
        if (!subjectId)
            return null
        for (let i = 0; i < subjects.length; ++i) {
            if (subjects[i].id === subjectId)
                return subjects[i]
        }
        return null
    }

    function entryTitle(entry) {
        if (entry && entry.title)
            return String(entry.title)

        const subjectId = entry ? entry.subjectId : ""
        if (!subjectId)
            return qsTr("Class")

        return AppCentral.scheduleEditor.subjectNameById(subjectId)
            || (subjectById(subjectId) || {}).name || qsTr("Class")
    }

    function entryTimeRange(entry) {
        if (!entry)
            return ""
        return entry.startTime + " - " + entry.endTime
    }

    // Only a real subject can opt into the connected visual style. A title is
    // just display text, so subject-less courses such as evening self-study
    // stay separate.
    function entryVisualKey(entry) {
        return entry && entry.subjectId ? "subject:" + entry.subjectId : ""
    }

    // ── Time axis ──────────────────────────────────────

    // Build the shared vertical axis once per revision. Overlapping courses
    // are merged, while disjoint courses keep their own proportional height.
    // Gaps that are not worth cutting out keep their real duration too, so the
    // half-hour divisions stay exactly one division tall. A gap longer than
    // `dividerBandMinutes` becomes a divider band instead, which is the only
    // place where the ruler is interrupted, and it is drawn as such.
    function buildTimeAxis() {
        const occupied = []
        const columns = effectiveEntries || []
        for (let column = 0; column < columns.length; ++column) {
            const entries = columns[column] || []
            for (let row = 0; row < entries.length; ++row) {
                const entry = entries[row]
                if (!entry)
                    continue
                const start = toMinutes(entry.startTime)
                const end = toMinutes(entry.endTime)
                if (isFinite(start) && isFinite(end) && end > start)
                    occupied.push({ start: start, end: end })
            }
        }

        occupied.sort(function(left, right) {
            return left.start - right.start || left.end - right.end
        })

        const clusters = []
        for (let i = 0; i < occupied.length; ++i) {
            const interval = occupied[i]
            const previous = clusters.length ? clusters[clusters.length - 1] : null
            if (previous && interval.start <= previous.end) {
                previous.end = Math.max(previous.end, interval.end)
            } else {
                clusters.push({ start: interval.start, end: interval.end })
            }
        }

        // Every proportional span of the axis, in axis order. `visualSpan`
        // walks this list; divider bands are deliberately absent from it.
        const segments = []
        const items = []
        let cursor = 0
        for (let i = 0; i < clusters.length; ++i) {
            const cluster = clusters[i]
            const previousEnd = i > 0 ? clusters[i - 1].end : cluster.start
            const realGap = i > 0 ? cluster.start - previousEnd : 0
            const separatorBefore = i > 0 && realGap > dividerBandMinutes
            if (separatorBefore) {
                cursor += separatorBandHeight
            } else if (i > 0) {
                segments.push({
                    start: previousEnd,
                    end: cluster.start,
                    visualStart: cursor
                })
                cursor += realGap * pxPerMin
            }

            const duration = cluster.end - cluster.start
            const visualStart = cursor
            segments.push({
                start: cluster.start,
                end: cluster.end,
                visualStart: visualStart
            })
            items.push({
                start: cluster.start,
                end: cluster.end,
                visualStart: visualStart,
                visualEnd: visualStart + duration * pxPerMin,
                separatorBefore: separatorBefore
            })
            cursor += duration * pxPerMin
        }

        return {
            items: items,
            segments: segments,
            height: cursor,
            empty: items.length === 0
        }
    }

    // Map a start/end pair through the same proportional segment. Returning
    // both values together prevents startY and height from drifting apart, and
    // the piecewise-linear mapping keeps the pair inside one segment whenever
    // the course fits into one. Minutes inside a cut-out divider band have no
    // place on the axis and clamp to the following segment.
    function visualSpan(axis, startMinutes, endMinutes) {
        const mapTime = function(minutes) {
            const segments = axis.segments || []
            for (let i = 0; i < segments.length; ++i) {
                const segment = segments[i]
                if (minutes <= segment.start)
                    return segment.visualStart
                if (minutes <= segment.end) {
                    return segment.visualStart
                        + (minutes - segment.start) * pxPerMin
                }
            }
            return axis.height
        }

        const items = axis.items || []
        for (let i = 0; i < items.length; ++i) {
            const item = items[i]
            if (startMinutes >= item.start && endMinutes <= item.end) {
                return {
                    y: item.visualStart + (startMinutes - item.start) * pxPerMin,
                    height: (endMinutes - startMinutes) * pxPerMin
                }
            }
        }

        const y = mapTime(startMinutes)
        return { y: y, height: Math.max(2, mapTime(endMinutes) - y) }
    }

    // One tick per half-hour division, matching EntryListView. Ticks are placed
    // through the same proportional segments the courses use, so every division
    // is exactly `pxPerMin * gridIntervalMinutes` tall. A tick that falls inside
    // a cut-out divider band has no place on the axis and is skipped: the band
    // itself marks where the ruler was interrupted.
    function buildTimeGridLines() {
        const result = []
        const segments = timeAxis.segments || []

        for (let minute = 0; minute <= 24 * 60; minute += gridIntervalMinutes) {
            for (let i = 0; i < segments.length; ++i) {
                const segment = segments[i]
                if (minute < segment.start || minute > segment.end)
                    continue
                result.push({
                    minutes: minute,
                    y: segment.visualStart
                        + (minute - segment.start) * pxPerMin,
                    major: minute % 60 === 0
                })
                break
            }
        }

        result.sort(function(left, right) { return left.y - right.y })
        return result
    }

    function buildSeparators() {
        const result = []
        const items = timeAxis.items || []
        for (let i = 0; i < items.length; ++i) {
            const item = items[i]
            if (item.separatorBefore) {
                result.push({
                    y: item.visualStart - separatorBandHeight / 2,
                    height: 7
                })
            }
        }
        return result
    }

    // ── Day layout ─────────────────────────────────────

    // Every logical entry is rendered by its own delegate. joinTop/joinBottom
    // only shape the background so adjacent entries of the same subject appear
    // continuous; they never create a shared hit area or selection.
    //
    // The card properties are resolved here as well, so the delegate stays a
    // flat binding list instead of repeating an "is there an entry" test on
    // every single property.
    function visualEntriesForDay(columnIndex) {
        const source = (effectiveEntries && effectiveEntries[columnIndex]) || []
        const result = []

        for (let row = 0; row < source.length; ++row) {
            const entry = source[row]
            if (!entry)
                continue
            const start = toMinutes(entry.startTime)
            const end = toMinutes(entry.endTime)
            if (!isFinite(start) || !isFinite(end) || end <= start)
                continue
            result.push({
                row: row,
                entry: entry,
                start: start,
                end: end,
                span: visualSpan(timeAxis, start, end),
                key: entryVisualKey(entry),
                // A course without a subject has nothing to connect to.
                mergeable: !!entry.subjectId,
                tightAbove: false,
                tightBelow: false,
                tightTopInset: cardTopInset,
                tightBottomInset: cardTopInset,
                joinTop: false,
                joinBottom: false,
                showContent: true,
                groupContentHeight: 0,
                groupTailBottomInset: 0,
                groupLeadIndex: 0,
                timeTextIndex: -1,
                canShowOwnTime: false,
                timeTexts: [root.entryTimeRange(entry)]
            })
        }

        result.sort(function(left, right) {
            return left.start - right.start || left.row - right.row
        })

        for (let i = 0; i < result.length; ++i)
            result[i].groupLeadIndex = i

        for (let i = 1; i < result.length; ++i) {
            const previous = result[i - 1]
            const current = result[i]
            const gap = current.start - previous.end
            if (gap < 0 || gap > dividerBandMinutes)
                continue

            const axisGap = current.span.y
                - (previous.span.y + previous.span.height)
            const joined = previous.mergeable && current.mergeable
                && previous.key === current.key

            // Normalize the visual gap per day: short breaks keep the axis
            // height they really take, but the cards only leave a fixed slit
            // between them. Same-subject cards meet exactly but remain separate
            // delegates.
            const desiredGap = joined ? 0 : compactGapHeight
            const edgeOffset = (axisGap - desiredGap) / 2
            previous.tightBelow = true
            current.tightAbove = true
            previous.tightBottomInset = -edgeOffset
            current.tightTopInset = -edgeOffset

            if (!joined)
                continue

            // Content and the translucent base of a run are rendered only by
            // its first card; overlapping translucent delegates would create
            // a darker seam at every join.
            const groupLead = result[previous.groupLeadIndex]
            current.timeTextIndex = groupLead.timeTexts.length
            groupLead.timeTexts.push(current.timeTexts[0])
            current.joinTop = true
            current.groupLeadIndex = previous.groupLeadIndex
            current.showContent = false
            previous.joinBottom = true
        }

        // The lead owns the group's painted background, so give it the same
        // bottom edge as the final segment. That segment's inset is only final
        // after every adjacent pair has been normalized above.
        //
        // `joinBottom` alone would also match a middle segment of a run of
        // three or more entries (every interior card is joined both above and
        // below). Only the head of the run points to itself, so require
        // `groupLeadIndex === i` to grant it the shared group geometry.
        for (let i = 0; i < result.length; ++i) {
            const lead = result[i]
            if (lead.joinBottom !== true || lead.groupLeadIndex !== i)
                continue
            let tail = lead
            for (let j = i + 1; j < result.length; ++j) {
                if (result[j].groupLeadIndex !== i)
                    break
                tail = result[j]
            }
            lead.groupContentHeight = tail.span.y
                + tail.span.height - lead.span.y
            lead.groupTailBottomInset = tail.tightBelow
                ? tail.tightBottomInset
                : cardTopInset
        }

        // Mirror ScheduleCourseCard's geometry so a selected continuation only
        // suppresses the matching lead time line when it can actually show it.
        for (let i = 0; i < result.length; ++i) {
            const item = result[i]
            const effectiveTopInset = item.joinTop
                ? (item.tightAbove ? item.tightTopInset : 0)
                : (item.tightAbove ? item.tightTopInset : cardTopInset)
            const effectiveBottomInset = item.joinBottom
                ? (item.tightBelow ? item.tightBottomInset : 0)
                : (item.tightBelow ? item.tightBottomInset : cardTopInset)
            const visualHeight = Math.max(
                2,
                item.span.height - effectiveTopInset - effectiveBottomInset
            )
            item.canShowOwnTime = visualHeight
                >= root.mergedContentTopInset + root.cardTimeLineHeight
        }

        // Resolve selection-independent card properties here. Selection is
        // intentionally handled inside the delegate: making this model depend
        // on selectedCell would rebuild the Repeater during a click and can
        // invalidate the clicked entry.
        for (let i = 0; i < result.length; ++i) {
            const visual = result[i]
            visual.card = {
                entry: visual.entry,
                row: visual.row,
                startY: visual.span.y,
                cardHeight: visual.span.height,
                title: entryTitle(visual.entry),
                timeTexts: visual.timeTexts
            }
        }

        return result
    }

    // Return the lead time index represented by the selected continuation.
    // A short continuation cannot render its own time, so its lead duplicate
    // must remain visible in that case.
    function selectedContinuationTimeIndex(entries, columnIndex, leadIndex) {
        const selected = selectedCell || ({ row: -1, column: -1 })
        if (selected.column !== columnIndex)
            return -1

        const items = entries || []
        for (let i = 0; i < items.length; ++i) {
            const item = items[i]
            if (item.groupLeadIndex !== leadIndex
                    || item.showContent !== false
                    || item.row !== selected.row)
                continue
            return item.canShowOwnTime ? item.timeTextIndex : -1
        }
        return -1
    }
    // Animate only when the selected card is outside the calendar viewport.
    // The viewport is the actual Flickable, not the whole schedule page.
    function ensureCellVisible(row, column) {
        if (!calendarFlick || row < 0 || column < 0)
            return

        const entries = visualEntriesForDay(column) || []
        let target = null
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].row === row) {
                target = entries[i]
                break
            }
        }
        if (!target || !target.card)
            return

        const viewportWidth = calendarFlick.width
        const viewportHeight = calendarFlick.height
        const maxX = Math.max(0, calendarFlick.contentWidth - viewportWidth)
        const maxY = Math.max(0, calendarFlick.contentHeight - viewportHeight)
        const cardX = column * root.itemWidth
        const cardY = Number(target.card.startY) || 0
        const cardWidth = root.itemWidth
        const cardHeight = Math.max(1, Number(target.card.cardHeight) || 0)
        const viewportRight = calendarFlick.contentX + viewportWidth
        const viewportBottom = calendarFlick.contentY + viewportHeight
        const needsHorizontal = cardX < calendarFlick.contentX
            || cardX + cardWidth > viewportRight
        const needsVertical = cardY < calendarFlick.contentY
            || cardY + cardHeight > viewportBottom

        if (!needsHorizontal && !needsVertical)
            return

        horizontalScrollAnimation.stop()
        verticalScrollAnimation.stop()

        if (needsHorizontal) {
            const contentX = cardX - (viewportWidth - cardWidth) / 2
            horizontalScrollAnimation.to = Math.max(0, Math.min(maxX, contentX))
            horizontalScrollAnimation.start()
        }

        if (needsVertical) {
            const contentY = cardHeight >= viewportHeight
                ? cardY - 16
                : cardY - (viewportHeight - cardHeight) / 2
            verticalScrollAnimation.to = Math.max(0, Math.min(maxY, contentY))
            verticalScrollAnimation.start()
        }
    }

    NumberAnimation {
        id: horizontalScrollAnimation
        target: calendarFlick
        property: "contentX"
        duration: 240
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: verticalScrollAnimation
        target: calendarFlick
        property: "contentY"
        duration: 240
        easing.type: Easing.OutCubic
    }

    function scrollToSelectedCell() {
        const selected = selectedCell || ({ row: -1, column: -1 })
        if (selected.row < 0 || selected.column < 0)
            return
        ensureCellVisible(selected.row, selected.column)
    }

    // Column index of the backend's current day, or -1 when it reports none.
    readonly property int todayColumn: {
        const weekday = AppCentral.scheduleRuntime.currentDayOfWeek
        return weekday >= 1 && weekday <= 7 ? weekday - 1 : -1
    }

    // Select today's column so the table scrolls it into view.
    function selectToday() {
        if (todayColumn < 0)
            return
        const row = selectedCell && selectedCell.row >= 0 ? selectedCell.row : 0
        selectedCell = { row: row, column: todayColumn }
    }

    onSelectedCellChanged: Qt.callLater(scrollToSelectedCell)

    // Clicking empty grid space drops the selection and closes its flyout.
    function clearSelection() {
        const hasSelection = (selectedCell && (selectedCell.row >= 0
            || selectedCell.column >= 0)) || currentEntry
        if (!hasSelection)
            return
        selectedCell = { row: -1, column: -1 }
        currentEntry = null
        selectionCleared()
    }

    // ── Date header ───────────────────────────────────

    Item {
        id: headerRoot
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.headerHeight
        clip: true

        Item {
            anchors.left: parent.left
            anchors.leftMargin: root.timeGutterWidth
            anchors.right: parent.right
            height: parent.height
            clip: true

            ScheduleHeader {
                id: header
                x: -calendarFlick.contentX
                width: root.itemWidth * 7
                height: parent.height
                weekStart: root.weekStart
                itemWidth: root.itemWidth
                contentX: calendarFlick.contentX
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Colors.proxy.dividerBorderColor
        }
    }

    Item {
        id: body
        anchors.top: headerRoot.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true

        // Table background behind the time rail. The grid itself is covered by
        // the Flickable, so this only catches clicks on the rail column.
        MouseArea {
            id: railBackgroundHitArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.clearSelection()
        }

        // Fixed time rail. Its content uses the same scroll transform as the
        // grid lines, so every label stays centered on its matching tick.
        Item {
            id: timeRail
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: root.timeGutterWidth
            clip: true

            Item {
                id: timeRailContent
                y: -calendarFlick.contentY
                width: timeRail.width
                height: calendarFlick.contentHeight

                Repeater {
                    model: root.timeLabels

                    delegate: Item {
                        property var mark: modelData
                        x: 0
                        y: mark.y
                        width: timeRailContent.width - 10
                        height: 1

                        Text {
                            width: parent.width
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.mark.text
                            color: Colors.proxy.textSecondaryColor
                            typography: Typography.Caption
                            horizontalAlignment: Text.AlignRight
                            wrapMode: Text.NoWrap
                            clip: true
                        }
                    }
                }
            }
        }

        Flickable {
            id: calendarFlick
            anchors.top: parent.top
            anchors.left: timeRail.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: root.itemWidth * 7
            contentHeight: Math.max(height, root.timeAxis.height + root.bottomPadding)
            flickableDirection: Flickable.HorizontalAndVerticalFlick

            // User scrolling takes priority over an in-flight auto-scroll.
            onMovementStarted: {
                horizontalScrollAnimation.stop()
                verticalScrollAnimation.stop()
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
            ScrollBar.horizontal: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            // Empty grid space. Declared first so it stays behind the columns;
            // a click here drops the selection. Flickable still steals the
            // press once the pointer is dragged, so scrolling keeps working.
            MouseArea {
                id: backgroundHitArea
                x: 0
                y: 0
                width: Math.max(calendarFlick.contentWidth, calendarFlick.width)
                height: Math.max(calendarFlick.contentHeight, calendarFlick.height)
                acceptedButtons: Qt.LeftButton
                onClicked: root.clearSelection()
            }

            // One vertical line per day column.
            Repeater {
                model: 7

                delegate: Rectangle {
                    x: index * root.itemWidth
                    y: 0
                    width: 1
                    height: calendarFlick.contentHeight
                    color: Colors.proxy.dividerBorderColor
                    opacity: index === 0 ? 0.65 : 0.75
                }
            }

            // Horizontal time lines. Empty time before the first course and
            // after the last course is intentionally not drawn.
            Repeater {
                model: root.timeGridLines

                delegate: Rectangle {
                    property var mark: modelData
                    x: 0
                    y: mark.y
                    width: calendarFlick.contentWidth
                    height: 1
                    color: Colors.proxy.dividerBorderColor
                    opacity: mark.major ? 0.72 : 0.34
                }
            }

            // Long empty periods are represented only on the background.
            Repeater {
                model: root.separators

                delegate: Rectangle {
                    property var separator: modelData
                    x: 0
                    y: separator.y
                    width: calendarFlick.contentWidth
                    height: separator.height
                    radius: height / 2
                    color: Colors.proxy.dividerBorderColor
                    opacity: 0.9
                    z: 3
                }
            }

            // One delegate per logical entry. Adjacent non-blank entries of
            // the same subject only remove the touching corners; they remain
            // separate items with separate hit areas and selected borders.
            Repeater {
                model: 7

                delegate: Item {
                    id: dayLayer
                    property int columnIndex: index
                    property var entries: root.visualEntriesForDay(columnIndex)
                    x: columnIndex * root.itemWidth
                    y: 0
                    width: root.itemWidth
                    height: calendarFlick.contentHeight

                    Repeater {
                        model: dayLayer.entries || []

                        delegate: ScheduleCourseCard {
                            readonly property var cardData: modelData.card
                            readonly property bool visualSelected: root.selectedCell
                                && root.selectedCell.column === dayLayer.columnIndex
                                && root.selectedCell.row === modelData.row

                            entry: cardData.entry
                            cardTitle: cardData.title
                            timeTexts: cardData.timeTexts
                            startY: cardData.startY
                            cardHeight: cardData.cardHeight
                            tightAbove: modelData.tightAbove
                            tightBelow: modelData.tightBelow
                            tightTopInset: modelData.tightTopInset
                            tightBottomInset: modelData.tightBottomInset
                            hasJoinAbove: modelData.joinTop
                            hasJoinBelow: modelData.joinBottom
                            showContent: modelData.showContent
                            groupContentHeight: modelData.groupContentHeight
                            groupTailBottomInset: modelData.groupTailBottomInset
                            hiddenGroupTimeIndex: modelData.showContent !== false
                                ? root.selectedContinuationTimeIndex(
                                    dayLayer.entries,
                                    dayLayer.columnIndex,
                                    modelData.groupLeadIndex
                                )
                                : -1
                            showOnlyFirstTime: modelData.showContent !== false
                                && modelData.groupContentHeight > 0
                                && visualSelected
                            horizontalInset: root.cardHorizontalInset
                            topInset: root.cardTopInset
                            selected: visualSelected

                            onClicked: (entry, card) => {
                                const row = modelData.row
                                const column = dayLayer.columnIndex
                                const clickedEntry = entry !== undefined
                                    ? entry : cardData.entry
                                root.selectedCell = { row: row, column: column }
                                root.currentEntry = clickedEntry || null
                                root.cellClicked(
                                    row,
                                    column,
                                    clickedEntry || null,
                                    card
                                )
                            }
                        }
                    }
                }
            }

            // Empty state for schedules without class entries.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(72, calendarFlick.height / 2)
                text: qsTr("No classes this week")
                color: Colors.proxy.textSecondaryColor
                font.pixelSize: 13
                visible: root.timeAxis.empty
            }
        }
    }
}
