import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import "../editor/CoursePalette.js" as Palette
/*
 * Single-column course timeline, the one-column sibling of the editor's
 * ScheduleTableView.
 *
 * The vertical axis is proportional to the clock and long breaks collapse into
 * a separator band. Every logical entry keeps its own ScheduleCourseCard, so
 * selection, hit area and the adaptive content behave exactly like in the
 * editor; adjacent entries of the same subject only *look* joined.
 *
 * `header` is an optional item rendered above the timeline, which keeps the
 * weekday/week-cycle picker and the mode pills out of this component.
 */
Item {
    id: timeline
    clip: true
    // Entry maps as returned by ClassSwapManager.getDayEntries().
    property var entries: []
    // Ids that may not be selected. The caller resolves the whole set, so this
    // component never needs to know why something is unavailable.
    property var disabledIds: []
    property string selectedId: ""
    // Optional Component shown above the timeline; the timeline fills the rest.
    property Component header: null
    readonly property int gutterWidth: 46
    readonly property real pxPerMin: 0.9
    // One grid division is always half an hour; only whole hours are labelled.
    readonly property int gridIntervalMinutes: 30
    // Only breaks longer than this collapse into a separator band.
    readonly property int dividerBandMinutes: 30
    readonly property int separatorBandHeight: 7
    // Short breaks keep their real height, the cards only leave a small slit.
    readonly property int compactGapHeight: 3
    readonly property int cardHorizontalInset: 3
    readonly property int cardTopInset: 3
    readonly property int bottomPadding: 24
    // Mirrors ScheduleCourseCard's content geometry for time-line visibility.
    readonly property int mergedContentTopInset: 12
    readonly property int cardTimeLineHeight: 14
    signal entryClicked(var entry, int index)
    readonly property var axis: buildAxis()
    readonly property var renderEntries: buildVisualEntries(axis.segments)
    readonly property var gridLines: buildGridLines(axis.segments)
    readonly property bool isEmpty: renderEntries.length === 0
    // -- Helpers ---------------------------------------------------------
    function toMinutes(value) {
        if (value === null || value === undefined)
            return NaN
        const parts = String(value).split(":")
        if (parts.length < 2)
            return NaN
        const hours = Number(parts[0])
        const minutes = Number(parts[1])
        return isFinite(hours) && isFinite(minutes) ? hours * 60 + minutes : NaN
    }
    function timeRange(entry) {
        if (!entry)
            return ""
        return (entry.startTime || "--:--") + " - " + (entry.endTime || "--:--")
    }
    function entryTitle(entry) {
        if (!entry)
            return qsTr("Class")
        return String(entry.title || entry.subjectName || qsTr("Class"))
    }
    function isDisabled(entry) {
        if (!entry || !entry.id)
            return true
        const ids = disabledIds || []
        for (let i = 0; i < ids.length; ++i) {
            if (String(ids[i]) === String(entry.id))
                return true
        }
        return false
    }
    // -- Time axis -------------------------------------------------------
    // Occupied intervals are merged into clusters. A break longer than
    // `dividerBandMinutes` becomes a separator band instead of taking its real
    // height, so short breaks stay proportional while an empty afternoon does
    // not eat the whole viewport.
    function buildAxis() {
        const source = entries || []
        const occupied = []
        for (let i = 0; i < source.length; ++i) {
            const entry = source[i]
            if (!entry)
                continue
            const start = toMinutes(entry.startTime)
            const end = toMinutes(entry.endTime)
            if (isFinite(start) && isFinite(end) && end > start)
                occupied.push({ start: start, end: end })
        }
        occupied.sort(function(left, right) { return left.start - right.start })
        const clusters = []
        for (let i = 0; i < occupied.length; ++i) {
            const interval = occupied[i]
            const previous = clusters.length ? clusters[clusters.length - 1] : null
            if (previous && interval.start <= previous.end)
                previous.end = Math.max(previous.end, interval.end)
            else
                clusters.push({ start: interval.start, end: interval.end })
        }
        const segments = []
        const separators = []
        let cursor = 0
        for (let i = 0; i < clusters.length; ++i) {
            const cluster = clusters[i]
            if (i > 0) {
                const gap = cluster.start - clusters[i - 1].end
                if (gap > dividerBandMinutes) {
                    separators.push({ y: cursor, height: separatorBandHeight })
                    cursor += separatorBandHeight
                } else {
                    segments.push({
                        start: clusters[i - 1].end,
                        end: cluster.start,
                        visualStart: cursor
                    })
                    cursor += gap * pxPerMin
                }
            }
            segments.push({
                start: cluster.start,
                end: cluster.end,
                visualStart: cursor
            })
            cursor += (cluster.end - cluster.start) * pxPerMin
        }
        return { segments: segments, separators: separators, height: cursor }
    }
    function visualSpan(segments, startMinutes, endMinutes) {
        const spans = segments || []
        const mapTime = function(minutes) {
            for (let i = 0; i < spans.length; ++i) {
                const segment = spans[i]
                if (minutes <= segment.start)
                    return segment.visualStart
                if (minutes <= segment.end)
                    return segment.visualStart + (minutes - segment.start) * pxPerMin
            }
            return 0
        }
        for (let i = 0; i < spans.length; ++i) {
            const segment = spans[i]
            if (startMinutes >= segment.start && endMinutes <= segment.end) {
                return {
                    y: segment.visualStart + (startMinutes - segment.start) * pxPerMin,
                    height: (endMinutes - startMinutes) * pxPerMin
                }
            }
        }
        const y = mapTime(startMinutes)
        return { y: y, height: Math.max(2, mapTime(endMinutes) - y) }
    }
    // One visual item per logical entry, exactly like ScheduleTableView. The
    // joins are display-only and never merge hit areas; the head of a run owns
    // the painted surface and the full title/time list.
    function buildVisualEntries(segments) {
        const source = entries || []
        const result = []
        for (let i = 0; i < source.length; ++i) {
            const entry = source[i]
            if (!entry)
                continue
            const start = toMinutes(entry.startTime)
            const end = toMinutes(entry.endTime)
            if (!isFinite(start) || !isFinite(end) || end <= start)
                continue
            result.push({
                entry: entry,
                start: start,
                end: end,
                span: visualSpan(segments, start, end),
                key: entry.subjectId ? "subject:" + entry.subjectId : "",
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
                timeTexts: [timeRange(entry)]
            })
        }
        result.sort(function(left, right) { return left.start - right.start })
        for (let i = 0; i < result.length; ++i)
            result[i].groupLeadIndex = i
        for (let i = 1; i < result.length; ++i) {
            const previous = result[i - 1]
            const current = result[i]
            const gap = current.start - previous.end
            if (gap < 0 || gap > dividerBandMinutes)
                continue
            const axisGap = current.span.y - (previous.span.y + previous.span.height)
            const joined = previous.mergeable && current.mergeable
                && previous.key === current.key
            const edgeOffset = (axisGap - (joined ? 0 : compactGapHeight)) / 2
            previous.tightBelow = true
            current.tightAbove = true
            previous.tightBottomInset = -edgeOffset
            current.tightTopInset = -edgeOffset
            if (!joined)
                continue
            const groupLead = result[previous.groupLeadIndex]
            current.timeTextIndex = groupLead.timeTexts.length
            groupLead.timeTexts.push(current.timeTexts[0])
            current.joinTop = true
            current.groupLeadIndex = previous.groupLeadIndex
            current.showContent = false
            previous.joinBottom = true
        }
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
            lead.groupContentHeight = tail.span.y + tail.span.height - lead.span.y
            lead.groupTailBottomInset = tail.tightBelow
                ? tail.tightBottomInset : cardTopInset
        }
        // Mirror ScheduleCourseCard's geometry so a continuation only hides the
        // lead's matching time line when it can actually show its own.
        for (let i = 0; i < result.length; ++i) {
            const item = result[i]
            const topInset = item.joinTop
                ? (item.tightAbove ? item.tightTopInset : 0)
                : (item.tightAbove ? item.tightTopInset : cardTopInset)
            const bottomInset = item.joinBottom
                ? (item.tightBelow ? item.tightBottomInset : 0)
                : (item.tightBelow ? item.tightBottomInset : cardTopInset)
            item.canShowOwnTime = Math.max(2, item.span.height - topInset - bottomInset)
                >= timeline.mergedContentTopInset + timeline.cardTimeLineHeight
        }
        return result
    }
    // Lead time index owned by the selected continuation, so the duplicated
    // time line in the head can be hidden while that segment is selected.
    function selectedContinuationTimeIndex(items, leadIndex) {
        const list = items || []
        for (let i = 0; i < list.length; ++i) {
            const item = list[i]
            if (item.groupLeadIndex === leadIndex && item.showContent === false
                    && item.entry.id === selectedId)
                return item.canShowOwnTime ? item.timeTextIndex : -1
        }
        return -1
    }
    // One tick per half-hour division, placed through the same segments the
    // cards use so every division keeps its real proportion.
    function buildGridLines(segments) {
        const spans = segments || []
        const result = []
        for (let minute = 0; minute <= 24 * 60; minute += gridIntervalMinutes) {
            for (let i = 0; i < spans.length; ++i) {
                const segment = spans[i]
                if (minute < segment.start || minute > segment.end)
                    continue
                let hour = Math.floor(minute / 60) % 12
                if (hour === 0)
                    hour = 12
                result.push({
                    y: segment.visualStart + (minute - segment.start) * pxPerMin,
                    major: minute % 60 === 0,
                    text: String(hour),
                    suffix: Math.floor(minute / 60) >= 12 ? "PM" : "AM"
                })
                break
            }
        }
        result.sort(function(left, right) { return left.y - right.y })
        return result
    }
    // -- Layout ----------------------------------------------------------
    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        Loader {
            id: headerLoader
            Layout.fillWidth: true
            Layout.preferredHeight: item ? item.implicitHeight : 0
            active: timeline.header !== null
            visible: active
            sourceComponent: timeline.header
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: Math.max(height, timeline.axis.height + timeline.bottomPadding)
                flickableDirection: Flickable.VerticalFlick
                ScrollBar.vertical: ScrollBar {}
                // Grid lines plus the time rail; the label sits before the line.
                Repeater {
                    model: timeline.gridLines
                    delegate: Item {
                        id: markItem
                        readonly property var mark: modelData
                        x: 0
                        y: mark.y
                        width: flick.width
                        height: 1
                        RowLayout {
                            visible: markItem.mark.major
                            spacing: 1
                            anchors.right: line.left
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: markItem.mark.text
                                font.pixelSize: 12
                                color: Colors.proxy.textSecondaryColor
                            }
                            Text {
                                text: markItem.mark.suffix
                                font.pixelSize: 8
                                color: Colors.proxy.textSecondaryColor
                            }
                        }
                        Rectangle {
                            id: line
                            anchors.left: parent.left
                            anchors.leftMargin: timeline.gutterWidth
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 1
                            color: Colors.proxy.dividerBorderColor
                            opacity: markItem.mark.major ? 0.72 : 0.34
                        }
                    }
                }
                // Collapsed long breaks, drawn as a rounded band.
                Repeater {
                    model: timeline.axis.separators
                    delegate: Rectangle {
                        readonly property var separator: modelData
                        x: 0
                        y: separator.y
                        width: flick.width
                        height: separator.height
                        radius: height / 2
                        color: Colors.proxy.dividerBorderColor
                        opacity: 0.9
                        z: 3
                    }
                }
                // One card per logical entry, starting after the time rail.
                Item {
                    x: timeline.gutterWidth
                    y: 0
                    width: Math.max(1, flick.width - timeline.gutterWidth)
                    height: flick.contentHeight
                    Repeater {
                        model: timeline.renderEntries
                        delegate: ScheduleCourseCard {
                            readonly property var visual: modelData
                            readonly property bool visualDisabled: timeline.isDisabled(visual.entry)
                            entry: visual.entry
                            cardTitle: timeline.entryTitle(visual.entry)
                            timeTexts: visual.timeTexts
                            startY: visual.span.y
                            cardHeight: visual.span.height
                            tightAbove: visual.tightAbove
                            tightBelow: visual.tightBelow
                            tightTopInset: visual.tightTopInset
                            tightBottomInset: visual.tightBottomInset
                            hasJoinAbove: visual.joinTop
                            hasJoinBelow: visual.joinBottom
                            showContent: visual.showContent
                            groupContentHeight: visual.groupContentHeight
                            groupTailBottomInset: visual.groupTailBottomInset
                            hiddenGroupTimeIndex: visual.showContent !== false
                                ? timeline.selectedContinuationTimeIndex(
                                    timeline.renderEntries, visual.groupLeadIndex)
                                : -1
                            showOnlyFirstTime: visual.showContent !== false
                                && visual.groupContentHeight > 0
                                && timeline.selectedId === visual.entry.id
                            horizontalInset: timeline.cardHorizontalInset
                            topInset: timeline.cardTopInset
                            selected: timeline.selectedId === visual.entry.id
                            // An unavailable course is marked by draining its
                            // colour, not by fading the card: opacity would also
                            // wash out the neighbours of a joined run.
                            cardColor: visualDisabled
                                ? Palette.muted(visual.entry.subjectColor, 0.25)
                                : (visual.entry.subjectColor || Colors.proxy.systemNeutralColor)
                            opacity: visualDisabled ? 0.55 : 1.0
                            enabled: !visualDisabled
                            onClicked: {
                                if (visualDisabled)
                                    return
                                timeline.entryClicked(visual.entry, visual.groupLeadIndex)
                            }
                        }
                    }
                }
            }
            // Empty state: the selected day has no class/activity entry.
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 320)
                visible: timeline.isEmpty
                spacing: 4
                opacity: 0.5
                Icon {
                    Layout.alignment: Qt.AlignCenter
                    name: "ic_fluent_square_hint_sparkles_20_regular"
                    size: 42
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    typography: Typography.BodyLarge
                    text: qsTr("Nothing scheduled for this day")
                }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    typography: Typography.Caption
                    wrapMode: Text.WordWrap
                    text: qsTr("Pick another weekday or week cycle above.")
                }
            }
        }
    }
}
