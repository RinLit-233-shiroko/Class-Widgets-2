import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import "../WeekRule.js" as WeekRule

/*
 * One editable override row of the course flyout.
 *
 * The row derives its own display text and its week / period choices from the
 * flyout `context` (current week, clicked day, base and effective entries), so
 * the flyout only has to fill the model and react to the signals below.
 */
Item {
    id: root

    required property int index
    required property string entryId
    required property string entryIds
    required property string originalEntryIds
    required property string overrideIds
    required property var weeks

    required property string subjectId
    required property string title
    required property string startTime
    required property string endTime
    required property bool removed
    required property bool expanded
    required property int startPeriod
    required property int endPeriod

    // See ScheduleFlyout.refreshContext().
    property var context: null

    signal toggleRequested()
    signal fieldEdited(string role, var value)
    signal weeksEdited(var value)
    signal periodSelected(string role, int period)
    signal clearRequested()

    readonly property var weeksValue: decodeWeeks(weeks)
    readonly property int cycleCount: context ? context.week.cycle : 1
    // "all" | "cycle" | "specific". Odd/even is a rule of its own and is edited
    // through the same combo box as a cycle position (see `cycleOptions`), so
    // it must not be folded into either of the other two modes.
    readonly property string repeatType: {
        const type = WeekRule.kind(weeksValue)
        if (type === "all")
            return "all"
        return type === "specific" ? "specific" : "cycle"
    }
    readonly property var customWeeks: WeekRule.specificWeeks(weeksValue)
    // The value the cycle combo box carries. Inside a two-week cycle a cycle
    // position and the semester parity are the same rule, so the numeric form
    // is used there; longer cycles keep the parity rule as its own value.
    readonly property var repeatValue: {
        const rule = WeekRule.decode(weeksValue)
        if (WeekRule.isList(rule))
            return rule.length > 0 ? rule[0] : 1
        if (rule === "odd")
            return cycleCount === 2 ? 1 : "odd"
        if (rule === "even")
            return cycleCount === 2 ? 2 : "even"
        if (rule === "all")
            return 1
        return rule
    }


    // Overrides that already claim a week rule for the same entry and day. The
    // row's own records are excluded, so they never block the row itself.
    readonly property var scopes: {
        const result = []
        const contextValue = context
        if (!contextValue)
            return result
        const entryIdsValue = decodeIdList(entryIds)
        const excludedIds = decodeIdList(overrideIds)
        const overrides = contextValue.overrides || []
        for (let i = 0; i < overrides.length; ++i) {
            const item = overrides[i]
            if (entryIdsValue.indexOf(item.entryId) === -1)
                continue
            if (excludedIds.indexOf(item.id) !== -1)
                continue
            const days = WeekRule.dayList(item.dayOfWeek)
            if (days.length > 0 && days.indexOf(contextValue.week.dayOfWeek) === -1)
                continue
            result.push(item)
        }
        return result
    }

    readonly property bool everyWeekEnabled: {
        for (let i = 0; i < scopes.length; ++i) {
            const type = WeekRule.kind(scopes[i].weeks)
            // Both an "every week" and a parity rule already cover weeks that a
            // new "every week" rule would collide with.
            if (type === "all" || type === "odd" || type === "even")
                return false
        }
        return true
    }

    readonly property var cycleValues: {
        const used = []
        for (let i = 0; i < scopes.length; ++i) {
            const value = decodeWeeks(scopes[i].weeks)
            if (typeof value === "number" && used.indexOf(value) === -1)
                used.push(value)
        }
        const result = []
        for (let value = 1; value <= cycleCount; ++value) {
            if (used.indexOf(value) === -1)
                result.push(value)
        }
        return result
    }

    // The week-cycle sentence is translated as one string with a {value}
    // placeholder, so translators may move the number (see DayEditor). The
    // combo box only carries the bare number, except for a stored parity rule,
    // which reads as a complete phrase of its own.
    readonly property string weekCycleFormat: qsTr("Week {value} of every %1 weeks").arg(cycleCount)
    readonly property bool paritySelected: typeof repeatValue === "string"
        && (repeatValue === "odd" || repeatValue === "even")
    readonly property string weekCyclePrefix: paritySelected
        ? "" : weekCycleFormat.split("{value}")[0]
    readonly property string weekCycleSuffix: paritySelected
        ? "" : weekCycleFormat.split("{value}")[1]
    readonly property string weekFormat: qsTr("Week {value}")
    readonly property string weekPrefix: weekFormat.split("{value}")[0]
    readonly property string weekSuffix: weekFormat.split("{value}")[1]

    function cycleLabel(value) {
        if (value === "odd")
            return qsTr("Odd Week")
        if (value === "even")
            return qsTr("Even Week")
        return qsTr("%1").arg(value)
    }

    // 单双周 and 第 x 周 are different rules and are offered side by side, so a
    // stored parity rule is never read back as a cycle position. The row's own
    // value is always present, even when another override claims it.
    readonly property var cycleOptions: {
        const result = []
        const append = function(value) {
            for (let i = 0; i < result.length; ++i) {
                if (result[i].value === value)
                    return
            }
            result.push({ text: cycleLabel(value), value: value })
        }
        for (let i = 0; i < cycleValues.length; ++i)
            append(cycleValues[i])
        if (paritySelected) {
            append("odd")
            append("even")
        }
        append(repeatValue)
        return result
    }

    function cycleIndex(value) {
        for (let i = 0; i < cycleOptions.length; ++i) {
            if (cycleOptions[i].value === value)
                return i
        }
        return -1
    }

    readonly property var blockedWeeks: {
        const result = []
        for (let i = 0; i < scopes.length; ++i) {
            const value = WeekRule.specificWeeks(scopes[i].weeks)
            for (let j = 0; j < value.length; ++j) {
                if (result.indexOf(value[j]) === -1)
                    result.push(value[j])
            }
        }
        return result
    }

    // Periods the row may span: its own periods stay selectable, and so does
    // every empty one, because an override only exists for filled periods.
    readonly property var periodOptions: {
        const options = { start: [], end: [] }
        const contextValue = context
        if (!contextValue)
            return options
        const effectiveEntries = contextValue.effectiveEntries || []
        const available = function(period) {
            const target = effectiveEntries[period - 1]
            if (!target)
                return false
            if (ownsPeriod(target.id))
                return true
            return !target.subjectId && !target.title
        }
        const rangeAvailable = function(from, to) {
            if (from < 1 || to < from || to > effectiveEntries.length)
                return false
            for (let period = from; period <= to; ++period) {
                if (!available(period))
                    return false
            }
            return true
        }
        for (let period = 1; period <= endPeriod; ++period) {
            if (rangeAvailable(period, endPeriod))
                options.start.push(period)
        }
        for (let period = startPeriod; period <= effectiveEntries.length; ++period) {
            if (rangeAvailable(startPeriod, period))
                options.end.push(period)
        }
        return options
    }

    readonly property string displayTitle: title
        || (subjectId && AppCentral.scheduleEditor.subjectNameById(subjectId))
        || (entryForId() && (entryForId().title
            || entryForId().subjectId
                && AppCentral.scheduleEditor.subjectNameById(entryForId().subjectId)))
        || qsTr("Class")

    readonly property string summaryText: weeksLabel + " | " + periodLabel
        + " (" + timeLabel + ")"

    readonly property string weeksLabel: {
        const type = WeekRule.kind(weeksValue)
        if (type === "all")
            return qsTr("Every Week")
        if (type === "specific") {
            const value = WeekRule.specificWeeks(weeksValue)
            return value.length
                ? qsTr("Week %1").arg(value.join(", "))
                : qsTr("Specific Weeks")
        }
        if (type === "odd")
            return qsTr("Odd Week")
        if (type === "even")
            return qsTr("Even Week")
        const value = WeekRule.decode(weeksValue)
        if (cycleCount === 2)
            return Number(value) === 1 ? qsTr("Odd Week") : qsTr("Even Week")
        return qsTr("Week %2 of every %1 weeks").arg(cycleCount).arg(value)
    }

    readonly property string periodLabel: startPeriod === endPeriod
        ? qsTr("Period %1").arg(startPeriod)
        : qsTr("Periods %1-%2").arg(startPeriod).arg(endPeriod)

    readonly property string periodRangeFormat: qsTr("Period {from} to {to}")
    readonly property string periodPrefix: periodRangeFormat.split("{from}")[0]
    readonly property string periodMiddle: periodRangeFormat.split("{from}")[1].split("{to}")[0]
    readonly property string periodSuffix: periodRangeFormat.split("{to}")[1]

    readonly property string timeLabel: {
        const source = entryForId()
        const start = startTime || (source && source.startTime) || "--:--"
        const end = endTime || (source && source.endTime) || "--:--"
        return start + " - " + end
    }

    // Outside the edited week the row is shown, but marked as inactive. Within
    // it, another override on the same entry and day may win: a more specific
    // week rule always wins, and among equally specific rules the later record
    // does.
    readonly property string statusSuffix: {
        const contextValue = context
        if (!contextValue)
            return ""
        const week = contextValue.week
        if (!appliesThisWeek(decodeWeeks(weeks), week))
            return " " + qsTr("(Not This Week)")

        const ids = decodeIdList(overrideIds).filter(value => value !== "")
        if (ids.length === 0)
            return ""

        const overrides = contextValue.overrides || []
        let overriddenCount = 0
        for (let i = 0; i < ids.length; ++i) {
            if (isOverridden(ids[i], week, overrides))
                ++overriddenCount
        }
        if (overriddenCount === ids.length)
            return " " + qsTr("(Overridden)")
        if (overriddenCount > 0)
            return " " + qsTr("(Partially Overridden)")
        return ""
    }

    implicitWidth: removed ? 0 : card.implicitWidth
    width: Math.max(parent ? parent.width : 0, implicitWidth)
    implicitHeight: removed ? 0 : card.implicitHeight
    height: implicitHeight
    visible: !removed

    // ── Helpers ────────────────────────────────────────────────────────
    function decodeWeeks(value) {
        return WeekRule.decode(value)
    }

    function decodeIdList(value) {
        if (WeekRule.isList(value))
            return value.map(item => String(item))
        if (typeof value !== "string" || value.charAt(0) !== "[")
            return []
        try {
            const parsed = JSON.parse(value)
            return Array.isArray(parsed) ? parsed.map(item => String(item)) : []
        } catch (error) {
            return []
        }
    }

    function entryForId() {
        const contextValue = context
        if (!contextValue || !entryId)
            return null
        const effective = contextValue.effectiveEntries || []
        for (let i = 0; i < effective.length; ++i) {
            if (effective[i].id === entryId)
                return effective[i]
        }
        const base = contextValue.baseEntries || []
        for (let i = 0; i < base.length; ++i) {
            if (base[i].id === entryId)
                return base[i]
        }
        return AppCentral.scheduleEditor.getEntry(entryId)
    }

    function ownsPeriod(id) {
        return decodeIdList(entryIds).indexOf(id) !== -1
            || decodeIdList(originalEntryIds).indexOf(id) !== -1
    }

    function appliesThisWeek(value, week) {
        return WeekRule.matches(value, week.current, week.cycle)
    }

    function priorityOf(value) {
        const type = WeekRule.kind(value)
        if (type === "specific")
            return 3
        if (type === "cycle" || type === "odd" || type === "even")
            return 2
        return 1
    }

    function isOverridden(overrideId, week, overrides) {
        const contextValue = context
        let targetIndex = -1
        for (let i = 0; i < overrides.length; ++i) {
            if (overrides[i].id === overrideId) {
                targetIndex = i
                break
            }
        }
        if (targetIndex < 0)
            return false

        const target = overrides[targetIndex]
        if (!appliesThisWeek(decodeWeeks(target.weeks), week))
            return false

        const targetPriority = priorityOf(decodeWeeks(target.weeks))
        for (let i = 0; i < overrides.length; ++i) {
            const candidate = overrides[i]
            if (candidate.entryId !== target.entryId)
                continue
            const days = WeekRule.dayList(candidate.dayOfWeek)
            if (days.length > 0 && days.indexOf(contextValue.week.dayOfWeek) === -1)
                continue
            if (!appliesThisWeek(decodeWeeks(candidate.weeks), week))
                continue
            const candidatePriority = priorityOf(decodeWeeks(candidate.weeks))
            if (candidatePriority > targetPriority)
                return true
            if (candidatePriority === targetPriority && i > targetIndex)
                return true
        }
        return false
    }

    function firstAvailableCustomWeek() {
        for (let value = 1; value <= cycleCount; ++value) {
            if (customWeeks.indexOf(value) === -1
                    && blockedWeeks.indexOf(value) === -1)
                return value
        }
        return 0
    }

    Frame {
        id: card
        width: root.width
        topPadding: root.expanded ? 12 : 4
        bottomPadding: root.expanded ? 10 : 8
        leftPadding: 12
        rightPadding: 12

        background: Rectangle {
            radius: 4
            color: summaryButton.pressed
                ? (root.expanded
                    ? Colors.proxy.controlAltQuaternaryColor
                    : Colors.proxy.controlAltTertiaryColor)
                : summaryButton.hovered
                    ? (root.expanded
                        ? Colors.proxy.controlAltTertiaryColor
                        : Colors.proxy.subtleSecondaryColor)
                    : (root.expanded ? Colors.proxy.subtleSecondaryColor : "transparent")
            border.width: root.expanded ? 1 : 0
            border.color: Colors.proxy.controlBorderColor
        }

        contentItem: ColumnLayout {
            id: cardColumn
            spacing: 8

            RowLayout {
                id: summaryRow
                Layout.fillWidth: true
                spacing: 10

                Button {
                    id: summaryButton
                    Layout.fillWidth: true
                    flat: true
                    hoverable: false
                    padding: 0
                    implicitHeight: summaryContent.implicitHeight
                    onClicked: root.toggleRequested()

                    contentItem: ColumnLayout {
                        id: summaryContent
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: root.displayTitle + root.statusSuffix
                            typography: Typography.BodyStrong
                            opacity: text === qsTr("Class") ? 0.7 : 1  // 当你懒得判断状态的时候be like， 但是确实非常方便硬核（）
                            wrapMode: Text.WordWrap  // 我看看谁能找到这）
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.summaryText
                            typography: Typography.Caption
                            color: Colors.proxy.textSecondaryColor
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Button {
                    visible: root.expanded
                    text: qsTr("Clear")
                    onClicked: root.clearRequested()
                }
            }

            ColumnLayout {
                id: settingsColumn
                visible: root.expanded
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    spacing: 8
                    Text { text: qsTr("Name") }
                    TextField {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 100
                        text: root.title
                        onTextEdited: root.fieldEdited("title", text)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: qsTr("Subject") }
                    SubjectPickerButton {
                        subjectId: root.subjectId
                        showSubjectIcon: true
                        onSubjectSelected: subjectId => root.fieldEdited("subjectId", subjectId)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    ButtonGroup { id: repeatGroup }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        RadioButton {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            text: qsTr("Every Week")
                            ButtonGroup.group: repeatGroup
                            checked: root.repeatType === "all"
                            enabled: root.everyWeekEnabled
                            onClicked: root.weeksEdited("all")
                        }
                        RadioButton {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            text: qsTr("Repeat on a Cycle")
                            ButtonGroup.group: repeatGroup
                            checked: root.repeatType === "cycle"
                            enabled: root.cycleOptions.length > 0
                            onClicked: {
                                // Keep the current value when the row already
                                // carries a valid rule; only a fresh row takes
                                // the most specific free value.
                                if (root.repeatType === "cycle")
                                    return
                                const option = root.cycleOptions[0]
                                if (option)
                                    root.weeksEdited(option.value)
                            }
                        }
                        RadioButton {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            text: qsTr("Specific Weeks")
                            ButtonGroup.group: repeatGroup
                            checked: root.repeatType === "specific"
                            onClicked: {
                                if (root.customWeeks.length > 0)
                                    return
                                const week = root.firstAvailableCustomWeek()
                                if (week > 0)
                                    root.weeksEdited([week])
                            }
                        }
                    }

                    RowLayout {
                        visible: root.repeatType === "cycle"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        spacing: 2
                        Text { text: root.weekCyclePrefix }
                        ComboBox {
                            model: root.cycleOptions
                            textRole: "text"
                            valueRole: "value"
                            currentIndex: root.cycleIndex(root.repeatValue)
                            onActivated: {
                                const option = root.cycleOptions[currentIndex]
                                if (option)
                                    root.weeksEdited(option.value)
                            }
                        }
                        Text { text: root.weekCycleSuffix }
                    }

                    SpecificWeekEditor {
                        visible: root.repeatType === "specific"
                        Layout.fillWidth: true
                        weeks: root.customWeeks
                        blockedWeeks: root.blockedWeeks
                        onWeeksEdited: value => root.weeksEdited(value)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: qsTr("Class Time")
                        typography: Typography.Body
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        spacing: 4
                        Text { text: root.periodPrefix }
                        ComboBox {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 42
                            model: root.periodOptions.start
                            currentIndex: root.periodOptions.start.indexOf(root.startPeriod)
                            onActivated: {
                                if (currentIndex >= 0)
                                    root.periodSelected(
                                        "startTime", Number(model[currentIndex])
                                    )
                            }
                        }
                        Text { text: root.periodMiddle }
                        ComboBox {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 42
                            model: root.periodOptions.end
                            currentIndex: root.periodOptions.end.indexOf(root.endPeriod)
                            onActivated: {
                                if (currentIndex >= 0)
                                    root.periodSelected(
                                        "endTime", Number(model[currentIndex])
                                    )
                            }
                        }
                        Text { text: root.periodSuffix }
                    }
                }

            }
        }
    }
}
