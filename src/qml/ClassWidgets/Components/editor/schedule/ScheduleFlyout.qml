import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../WeekRule.js" as WeekRule

Flyout {
    id: root

    property var entry: null
    property var selectedCell: null
    property var weekSelector: null
    property Item sourceItem: null
    property int overridesRevision: AppCentral.scheduleEditor.overridesRevision
    property bool syncing: false
    property var baseDayEntries: []
    property var effectiveDayEntries: []
    property bool _repositionAfterAnimation: false
    property bool _repositionCallPending: false

    readonly property real overlayWidth: Overlay.overlay ? Overlay.overlay.width : 0
    readonly property real overlayHeight: Overlay.overlay ? Overlay.overlay.height : 0
    readonly property real popupMaxHeight: overlayHeight > 0
        ? Math.max(240, overlayHeight - 32)
        : 720
    readonly property int maxListHeight: Math.max(120, Math.floor(popupMaxHeight - 220))

    readonly property real popupMinWidth: 320
    readonly property real popupPreferredWidth: contentColumn.implicitWidth + leftPadding + rightPadding

    implicitWidth: overlayWidth > 0
        ? Math.max(popupMinWidth, Math.min(popupPreferredWidth, overlayWidth - 32))
        : Math.max(popupMinWidth, popupPreferredWidth)
    implicitHeight: Math.min(contentColumn.implicitHeight + topPadding + bottomPadding, popupMaxHeight)
    width: implicitWidth
    height: implicitHeight
    padding: 16
    leftPadding: 16
    rightPadding: 16
    position: Position.Right

    background: Item {
        id: backgroundContainer
        clip: true

        layer.enabled: true
        layer.effect: Shadow {
            style: "flyout"
            source: backgroundContainer
        }

        AcrylicBrush {
            anchors.fill: parent
            sourceItem: root.sourceItem
            enabled: root.sourceItem !== null
            radius: 8
            z: 0
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "transparent"
            border.color: Theme.currentTheme.colors.flyoutBorderColor
            border.width: 1
            z: 1
        }
    }

    ListModel {
        id: overrideModel
    }

    onAboutToShow: reloadOverrides()
    onEntryChanged: reloadOverrides()
    onOverridesRevisionChanged: if (!syncing) reloadOverrides()

    function requestReposition() {
        if (!visible || position === Position.None)
            return

        // RinUI ignores reposition requests while Popup enter/exit animations run.
        // Remember them and apply after the animation settles.
        if (enter.running || exit.running) {
            _repositionAfterAnimation = true
            return
        }

        _repositionAfterAnimation = false
        if (_repositionCallPending)
            return

        _repositionCallPending = true
        Qt.callLater(function() {
            root._repositionCallPending = false
            if (!root.visible || root.position === Position.None)
                return
            if (root.enter.running || root.exit.running) {
                root._repositionAfterAnimation = true
                return
            }
            root.autoPosition()
        })
    }

    Connections {
        target: root
        function onVisibleChanged() {
            if (root.visible)
                root.requestReposition()
        }
        function onHeightChanged() {
            root.requestReposition()
        }
        function onImplicitHeightChanged() {
            root.requestReposition()
        }
    }

    Connections {
        target: root.enter
        function onRunningChanged() {
            if (!root.enter.running && root._repositionAfterAnimation)
                root.requestReposition()
        }
    }

    // ── Data normalization ─────────────────────────────────────────────
    // Rows keep ids and their encoded form; the readable form is derived on
    // demand. `weeks` is either "all", "odd"/"even", a cycle week or a list of
    // absolute semester weeks. All conversions go through WeekRule.js, because
    // Python lists reach QML as array-like sequences that `Array.isArray()`
    // rejects (see that file for the details).
    function sameValue(left, right) {
        return WeekRule.equals(left, right)
    }

    function encodeDays(value) {
        return WeekRule.encodeDays(value)
    }

    function decodeDays(value) {
        return WeekRule.dayList(value)
    }

    function encodeWeeks(value) {
        return WeekRule.encode(value)
    }

    function decodeWeeks(value) {
        return WeekRule.decode(value)
    }

    // Ids travel as a JSON string inside the model roles. `field` keeps the
    // three id lists of a row behind one accessor.
    function idList(item, field) {
        const value = item ? item[field] : null
        if (Array.isArray(value))
            return value.map(entry => String(entry))
        if (typeof value !== "string" || value.charAt(0) !== "[")
            return []
        try {
            const parsed = JSON.parse(value)
            return Array.isArray(parsed) ? parsed.map(entry => String(entry)) : []
        } catch (error) {
            return []
        }
    }

    // ── Schedule context ───────────────────────────────────────────────
    function cycleCount() {
        return Math.max(1, Number(weekSelector ? weekSelector.maxWeekCycle : 1) || 1)
    }

    function currentWeek() {
        return Math.max(1, Number(weekSelector ? weekSelector.currentWeek : 1) || 1)
    }

    // Column index -> ISO day of week (1=Monday ... 7=Sunday), matching the
    // backend and the Monday-first table columns.
    function selectedDayOfWeek() {
        const column = Number(selectedCell ? selectedCell.column : -1)
        if (!isFinite(column) || column < 0)
            return ""
        return column + 1
    }

    function baseEntriesForId(entryId) {
        const days = AppCentral.scheduleEditor.entriesData || []
        for (const day of days) {
            for (const item of (day.entries || [])) {
                if (item.id === entryId)
                    return (day.entries || []).filter(entry => entry.type === "class")
            }
        }
        return []
    }

    // The base day of the edited entry, not the clicked column: an override may
    // span several periods of it. Times and period numbers always come from it.
    function refreshContext() {
        const entryId = entry ? (entry.id || "") : ""
        baseDayEntries = entryId ? baseEntriesForId(entryId) : []

        const columns = AppCentral.scheduleEditor.getEffectiveEntries(currentWeek()) || []
        const column = Number(selectedCell ? selectedCell.column : -1)
        effectiveDayEntries = column >= 0 && column < columns.length
            ? (columns[column] || [])
            : []
    }

    // ── Overrides of one entry on one day ──────────────────────────────
    // Rows are grouped by this signature: one row covers the contiguous run of
    // periods that shares it.
    function overrideKey(item) {
        return encodeDays(item.dayOfWeek || []) + "|"
            + encodeWeeks(item.weeks) + "|"
            + String(item.subjectId || "") + "|"
            + String(item.title || "")
    }

    function overrideMatchesDay(item, dayOfWeek) {
        // `item` usually comes straight from ScheduleEditor.overrides, so its
        // dayOfWeek is an array-like sequence rather than a JS Array.
        return WeekRule.dayMatches(item ? item.dayOfWeek : null, dayOfWeek)
    }

    // Overrides covering the given entry ids on the given day. `predicate`
    // selects the subset the caller cares about, so one walk serves grouping,
    // option building and status checks.
    function overridesOnDay(entryIds, dayOfWeek, predicate) {
        const result = []
        if (!entryIds || entryIds.length === 0)
            return result
        const overrides = AppCentral.scheduleEditor.overrides || []
        for (const item of overrides) {
            if (entryIds.indexOf(item.entryId) === -1)
                continue
            if (!overrideMatchesDay(item, dayOfWeek))
                continue
            if (predicate && !predicate(item))
                continue
            result.push(item)
        }
        return result
    }

    // Number of override rows currently shown.
    function rowCount() {
        return overrideModel.count
    }

    // Rebuild the rows for the selected entry: one row per override signature,
    // spanning every period the run of that signature covers.
    function reloadOverrides() {
        overrideModel.clear()
        refreshContext()

        const selectedEntryId = entry ? (entry.id || "") : ""
        const selectedIndex = baseDayEntries.findIndex(item => item.id === selectedEntryId)
        if (selectedIndex < 0)
            return

        const dayOfWeek = selectedDayOfWeek()
        const recordsByIndex = baseDayEntries.map(
            item => overridesOnDay([item.id], dayOfWeek)
        )

        const keys = []
        for (const item of recordsByIndex[selectedIndex]) {
            const key = overrideKey(item)
            if (keys.indexOf(key) === -1)
                keys.push(key)
        }

        for (const key of keys) {
            const matches = records => records.filter(
                item => overrideKey(item) === key
            )
            let start = selectedIndex
            let end = selectedIndex
            while (start > 0 && matches(recordsByIndex[start - 1]).length > 0)
                --start
            while (end + 1 < recordsByIndex.length
                    && matches(recordsByIndex[end + 1]).length > 0)
                ++end

            const records = []
            for (let i = start; i <= end; ++i)
                records.push(matches(recordsByIndex[i])[0])
            appendRow({ start: start, end: end, records: records })
        }
    }

    function appendRow(group) {
        const firstEntry = baseDayEntries[group.start]
        const lastEntry = baseDayEntries[group.end]
        if (!firstEntry || !lastEntry || group.records.length === 0)
            return

        const entryIds = []
        const overrideIds = []
        for (let i = group.start; i <= group.end; ++i) {
            entryIds.push(baseDayEntries[i].id)
            const record = group.records[i - group.start]
            overrideIds.push(record ? (record.id || "") : "")
        }

        const first = group.records[0]
        const days = encodeDays(first.dayOfWeek || [])
        const weeks = encodeWeeks(first.weeks)
        overrideModel.append({
            entryId: firstEntry.id,
            entryIds: JSON.stringify(entryIds),
            originalEntryIds: JSON.stringify(entryIds),
            overrideIds: JSON.stringify(overrideIds),
            dayOfWeek: days,
            weeks: weeks,
            subjectId: first.subjectId || "",
            title: first.title || "",
            // Display-only range metadata, never persisted on its own.
            startTime: firstEntry.startTime || "",
            endTime: lastEntry.endTime || "",
            originalDayOfWeek: days,
            originalWeeks: weeks,
            startPeriod: group.start + 1,
            endPeriod: group.end + 1,
            isDraft: false,
            removed: false,
            expanded: false
        })
    }

    // The most specific week rule still free for a new override on that entry.
    function defaultWeeksForNewItem(entryId) {
        const dayOfWeek = selectedDayOfWeek()
        const scopes = overridesOnDay([entryId], dayOfWeek)
        let everyWeekFree = true
        const usedCycles = []
        const blocked = []
        for (const item of scopes) {
            const value = decodeWeeks(item.weeks)
            const type = WeekRule.kind(value)
            if (type === "all")
                everyWeekFree = false
            else if (type === "cycle")
                usedCycles.push(value)
            else if (type === "odd" || type === "even")
                // A parity rule already covers half of the semester, so an
                // "every week" rule would collide with it.
                everyWeekFree = false
            else if (type === "specific") {
                for (const week of value) {
                    if (blocked.indexOf(week) === -1)
                        blocked.push(week)
                }
            }
        }
        if (everyWeekFree)
            return "all"
        for (let value = 1; value <= cycleCount(); ++value) {
            if (usedCycles.indexOf(value) === -1)
                return value
        }
        let week = currentWeek()
        while (blocked.indexOf(week) !== -1)
            ++week
        return [week]
    }

    function addDraft() {
        if (!entry || !entry.id)
            return

        refreshContext()
        const period = baseDayEntries.findIndex(item => item.id === entry.id) + 1
        const weeks = encodeWeeks(defaultWeeksForNewItem(entry.id))
        const days = encodeDays([selectedDayOfWeek()])

        for (let i = 0; i < overrideModel.count; ++i)
            overrideModel.setProperty(i, "expanded", false)
        overrideModel.append({
            entryId: entry.id,
            entryIds: JSON.stringify([entry.id]),
            originalEntryIds: "[]",
            overrideIds: "[]",
            dayOfWeek: days,
            weeks: weeks,
            subjectId: entry.subjectId || "",
            title: entry.title || "",
            startTime: entry.startTime || "",
            endTime: entry.endTime || "",
            originalDayOfWeek: days,
            originalWeeks: weeks,
            startPeriod: period > 0 ? period : 1,
            endPeriod: period > 0 ? period : 1,
            isDraft: true,
            removed: false,
            expanded: true
        })

        Qt.callLater(function() {
            overrideFlick.contentY = Math.max(0, overrideFlick.contentHeight - overrideFlick.height)
        })
    }

    // Move a row to the period range the user picked. The times follow the base
    // entries of that range; persistence stores subject / title / day / week.
    function applyPeriodSelection(index, role, period) {
        const item = overrideModel.get(index)
        const selectedPeriod = Number(period)
        if (!item || !isFinite(selectedPeriod))
            return

        const startPeriod = role === "startTime"
            ? Math.min(selectedPeriod, item.endPeriod)
            : item.startPeriod
        const endPeriod = role === "startTime"
            ? item.endPeriod
            : Math.max(selectedPeriod, item.startPeriod)

        const owned = idList(item, "entryIds").concat(idList(item, "originalEntryIds"))
        const available = function(target) {
            return !target || owned.indexOf(target.id) !== -1
                || (!target.subjectId && !target.title)
        }
        if (endPeriod > effectiveDayEntries.length)
            return
        for (let index2 = startPeriod; index2 <= endPeriod; ++index2) {
            if (!available(effectiveDayEntries[index2 - 1]))
                return
        }

        const entryIds = []
        for (let index2 = startPeriod; index2 <= endPeriod; ++index2) {
            const target = effectiveDayEntries[index2 - 1]
            if (!target)
                return
            entryIds.push(target.id)
        }
        const firstEntry = effectiveDayEntries[startPeriod - 1]
        const lastEntry = effectiveDayEntries[endPeriod - 1]
        overrideModel.setProperty(index, "entryId", entryIds[0])
        overrideModel.setProperty(index, "entryIds", JSON.stringify(entryIds))
        overrideModel.setProperty(index, "startPeriod", startPeriod)
        overrideModel.setProperty(index, "endPeriod", endPeriod)
        overrideModel.setProperty(index, "startTime", firstEntry.startTime || "")
        overrideModel.setProperty(index, "endTime", lastEntry.endTime || "")
    }

    // Only one row is expanded at a time.
    function toggleOverride(index) {
        const item = overrideModel.get(index)
        if (!item)
            return
        const expand = !item.expanded
        for (let i = 0; i < overrideModel.count; ++i)
            overrideModel.setProperty(i, "expanded", false)
        overrideModel.setProperty(index, "expanded", expand)
    }

    // Drafts disappear, saved rows are only flagged: their overrides are
    // removed on save, so cancelling leaves them untouched.
    function clearItem(index) {
        if (index < 0 || index >= overrideModel.count)
            return
        if (overrideModel.get(index).isDraft) {
            // Removing a delegate from inside the loop that emitted the request
            // is not safe, so let the current pass finish first.
            Qt.callLater(function() {
                if (index < overrideModel.count)
                    overrideModel.remove(index)
            })
            return
        }
        overrideModel.setProperty(index, "removed", true)
        overrideModel.setProperty(index, "expanded", false)
    }

    // ── Persistence ───────────────────────────────────────────────────
    // Overrides are field-wise, so one row may cover several entries. When the
    // day or week rule changed the row's records no longer describe it and are
    // replaced; otherwise only the entries it no longer covers are dropped.
    function saveAll() {
        syncing = true

        for (let i = 0; i < overrideModel.count; ++i) {
            const item = overrideModel.get(i)
            if (!item)
                continue
            if (item.removed) {
                for (const overrideId of idList(item, "overrideIds")) {
                    if (overrideId)
                        AppCentral.scheduleEditor.removeOverride(overrideId)
                }
                continue
            }
            saveRow(item)
        }

        syncing = false
        reloadOverrides()
        close()
    }

    function saveRow(item) {
        const entryIds = idList(item, "entryIds")
        const originalEntryIds = idList(item, "originalEntryIds")
        const overrideIds = idList(item, "overrideIds")
        if (entryIds.length === 0)
            return

        const days = decodeDays(item.dayOfWeek)
        const weeks = decodeWeeks(item.weeks)
        const scheduleChanged = !sameValue(item.dayOfWeek, item.originalDayOfWeek)
            || !sameValue(item.weeks, item.originalWeeks)

        // Entry -> record id, as the row was loaded.
        const overrideByEntry = ({})
        for (let i = 0; i < originalEntryIds.length; ++i)
            overrideByEntry[originalEntryIds[i]] = overrideIds[i] || ""

        if (scheduleChanged) {
            for (const overrideId of overrideIds) {
                if (overrideId)
                    AppCentral.scheduleEditor.removeOverride(overrideId)
            }
        } else {
            for (const originalEntryId of originalEntryIds) {
                if (entryIds.indexOf(originalEntryId) !== -1)
                    continue
                if (overrideByEntry[originalEntryId])
                    AppCentral.scheduleEditor.removeOverride(overrideByEntry[originalEntryId])
            }
        }

        for (const entryId of entryIds) {
            let existingId = scheduleChanged ? "" : (overrideByEntry[entryId] || "")
            if (!existingId) {
                existingId = AppCentral.scheduleEditor.findOverride(
                    entryId, days, weeks
                ) || ""
            }

            if (existingId) {
                AppCentral.scheduleEditor.updateOverride(
                    existingId, item.subjectId, item.title
                )
            } else {
                AppCentral.scheduleEditor.addOverride(
                    entryId, days, weeks, item.subjectId, item.title
                )
            }
        }
    }

    // ── UI ─────────────────────────────────────────────────────────────
    ColumnLayout {
        id: contentColumn
        Layout.fillWidth: true
        spacing: 4

        Flickable {
            id: overrideFlick
            implicitWidth: Math.min(
                overrideColumn.implicitWidth,
                root.overlayWidth > 0
                    ? Math.max(0, root.overlayWidth - 32)
                    : overrideColumn.implicitWidth
            )
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, root.maxListHeight)
            implicitHeight: Math.min(contentHeight, root.maxListHeight)
            contentWidth: Math.max(width, overrideColumn.implicitWidth)
            contentHeight: overrideColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { }

            Column {
                id: overrideColumn
                width: Math.max(overrideFlick.width, overrideColumn.implicitWidth)
                spacing: 4

                Repeater {
                    model: overrideModel

                    delegate: ScheduleOverrideItem {
                        context: {
                            // Explicit dependency reads keep the row in sync
                            // with the week and the two day views.
                            baseDayEntries
                            effectiveDayEntries
                            return {
                                week: {
                                    current: root.currentWeek(),
                                    cycle: root.cycleCount(),
                                    dayOfWeek: root.selectedDayOfWeek()
                                },
                                baseEntries: root.baseDayEntries,
                                effectiveEntries: root.effectiveDayEntries,
                                overrides: AppCentral.scheduleEditor.overrides || []
                            }
                        }

                        onToggleRequested: root.toggleOverride(index)
                        onFieldEdited: (role, value) => overrideModel.setProperty(index, role, value)
                        onWeeksEdited: value => overrideModel.setProperty(
                            index, "weeks", root.encodeWeeks(value)
                        )
                        onPeriodSelected: (role, period) => root.applyPeriodSelection(
                            index, role, period
                        )
                        onClearRequested: root.clearItem(index)
                    }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            flat: true
            enabled: root.entry !== null && !!root.entry.id
            leftPadding: 11
            rightPadding: 11
            topPadding: 4
            bottomPadding: 6
            onClicked: addDraft()

            contentItem: RowLayout {
                spacing: 8
                Icon {
                    name: "ic_fluent_add_20_regular"
                    size: 16
                }
                Text {
                    text: qsTr("New Course")
                    typography: Typography.Body
                }
                Item { Layout.fillWidth: true }
            }
        }

        RowLayout {
            id: buttonRow
            Layout.fillWidth: true
            Layout.topMargin: 18
            spacing: 8

            // Both buttons share one preferred width, otherwise the layout
            // splits the free space by implicit width and they end up uneven.
            readonly property real buttonWidth: Math.max(
                okButton.implicitWidth, cancelButton.implicitWidth
            )

            Button {
                id: okButton
                Layout.fillWidth: true
                Layout.preferredWidth: buttonRow.buttonWidth
                highlighted: true
                text: qsTr("OK")
                onClicked: saveAll()
            }
            Button {
                id: cancelButton
                Layout.fillWidth: true
                Layout.preferredWidth: buttonRow.buttonWidth
                text: qsTr("Cancel")
                onClicked: {
                    reloadOverrides()
                    root.close()
                }
            }
        }
    }
}
