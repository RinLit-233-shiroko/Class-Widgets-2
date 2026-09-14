import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import "../WeekRule.js" as WeekRule

Dialog {
    id: dayEditor
    modal: true
    width: 500  
    title: currentId ? qsTr("Edit Timeline") : qsTr("New Timeline")

    property string currentId: ""         // 如果有 id = 编辑，否则 = 新建
    property var currentData: ({})        // 临时缓存的数据副本

    // 周循环文案格式
    property int maxWeekCycle: AppCentral.scheduleEditor.meta.maxWeekCycle
    // A cycle position (1 ... maxWeekCycle) or a parity rule ("odd" / "even").
    property var roundWeek: 1
    property var customWeeks: []
    property bool canAccept: false
    property bool initialized: false
    onRoundWeekChanged: checkValid()
    onCustomWeeksChanged: {
        checkValid()
        if (weekCycleCustom)
            weekCycleCustom.weeks = customWeeks
    }
    property var roundWeekOptions: []
    property string weekCycleFormat: qsTr("Week {value} of every %1 weeks").arg(maxWeekCycle)
    // A parity rule reads as a complete phrase, so the surrounding cycle
    // sentence is dropped while one is selected.
    readonly property bool paritySelected: typeof roundWeek === "string"
        && (roundWeek === "odd" || roundWeek === "even")
    property string weekCyclePrefix: paritySelected
        ? "" : weekCycleFormat.split("{value}")[0]
    property string weekCycleSuffix: paritySelected
        ? "" : weekCycleFormat.split("{value}")[1]
    property string weekFormat: qsTr("Week {value}")
    property string weekPrefix: weekFormat.split("{value}")[0]
    property string weekSuffix: weekFormat.split("{value}")[1]

    function cycleLabel(value) {
        if (value === "odd")
            return qsTr("Odd Week")
        if (value === "even")
            return qsTr("Even Week")
        return qsTr("%1").arg(value)
    }

    function updateRoundWeekOptions() {
        var options = []
        var cycleLength = Math.max(1, maxWeekCycle)
        for (var i = 1; i <= cycleLength; i++) {
            options.push({
                text: cycleLength === 2
                    ? i === 1 ? qsTr("1") : qsTr("2")
                    : qsTr("%1").arg(i),
                value: i
            })
        }
        // 单双周 is a rule of its own and must stay selectable next to the cycle
        // positions whenever the two are not the same thing.
        if (cycleLength !== 2) {
            options.push({ text: qsTr("Odd Week"), value: "odd" })
            options.push({ text: qsTr("Even Week"), value: "even" })
        }
        roundWeekOptions = options
    }

    function roundWeekIndex(value) {
        for (var i = 0; i < roundWeekOptions.length; i++) {
            if (roundWeekOptions[i].value === value)
                return i
        }
        return -1
    }

    function normalizeRoundWeek() {
        var cycleLength = Math.max(1, maxWeekCycle)
        var rule = WeekRule.decode(roundWeek)
        if (rule === "odd" || rule === "even") {
            // Inside a two-week cycle a parity rule is exactly cycle position
            // 1 / 2, so the numeric form is used there. A longer cycle keeps
            // the parity rule apart from the cycle positions.
            roundWeek = cycleLength === 2
                ? (rule === "odd" ? 1 : 2)
                : rule
            return
        }
        var number = Math.floor(Number(rule))
        if (!isFinite(number) || number < 1) {
            roundWeek = 1
        } else if (number > cycleLength) {
            roundWeek = cycleLength
        } else {
            roundWeek = number
        }
    }

    function validRoundWeek() {
        var type = WeekRule.kind(roundWeek)
        if (type === "odd" || type === "even")
            return true
        if (type !== "cycle")
            return false
        return Number(roundWeek) >= 1 && Number(roundWeek) <= Math.max(1, maxWeekCycle)
    }

    function normalizedCustomWeeks(values) {
        return WeekRule.specificWeeks(values)
    }

    function normalizeCustomWeeks() {
        customWeeks = WeekRule.specificWeeks(customWeeks)
    }

    function firstAvailableCustomWeek() {
        var value = 1
        while (customWeeks.indexOf(value) !== -1)
            value++
        return value
    }

    function setOkEnabled(enabled) {
        if (footer && footer.okButton)
            footer.okButton.enabled = enabled
    }
    onMaxWeekCycleChanged: {
        normalizeRoundWeek()
        normalizeCustomWeeks()
        updateRoundWeekOptions()
    }
    Component.onCompleted: {
        normalizeRoundWeek()
        normalizeCustomWeeks()
        updateRoundWeekOptions()
        initialized = true
        checkValid()
    }

    // 打开方式
    function openFor(data) {
        if (data) {
            currentId = data.id
            reload(data)
        } else {
            currentId = ""
            reload({})   // 新建时重置
        }
        open()
    }

    // 重载数据
    function reload(data) {
        currentData = data || {}
        daySegmented.currentIndex = currentData.date ? 1 : 0
        dayId.text = currentData.id || qsTr("(auto)")

        // 日期
        if (currentData.date) dayDate.selectedDate = currentData.date

        // 星期
        var selectedDays = []
        if (currentData.dayOfWeek !== undefined && currentData.dayOfWeek !== null) {
            if (currentData.dayOfWeek.length !== undefined) {
                for (var i = 0; i < currentData.dayOfWeek.length; i++) {
                    var n = Number(currentData.dayOfWeek[i])
                    if (!isNaN(n) && selectedDays.indexOf(n) === -1)
                        selectedDays.push(n)
                }
            } else {
                var singleDay = Number(currentData.dayOfWeek)
                if (!isNaN(singleDay))
                    selectedDays.push(singleDay)
            }
        }
        selectedDays.sort((left, right) => left - right)
        dayButtons.days = selectedDays

        // 周循环。weeks 可能是 "all"、"odd"/"even"、周期内周次或指定周列表，
        // 判定必须走 WeekRule，因为 Python 列表在 QML 里不是 JS Array。
        const weeksRule = WeekRule.decode(currentData.weeks)
        const weeksKind = WeekRule.kind(weeksRule)
        weekCycleTypeAll.checked = weeksKind === "all"
        weekCycleTypeRound.checked = weeksKind === "cycle"
            || weeksKind === "odd" || weeksKind === "even"
        weekCycleTypeCustom.checked = weeksKind === "specific"
        if (weekCycleTypeRound.checked)
            roundWeek = (maxWeekCycle === 2 && weeksKind === "odd") ? 1
                : (maxWeekCycle === 2 && weeksKind === "even") ? 2
                : weeksRule
        customWeeks = weekCycleTypeCustom.checked
            ? WeekRule.specificWeeks(weeksRule)
            : []

        checkValid()
    }

    // 检查是否可以启用 Ok
    function checkValid() {
        if (!initialized)
            return

        var valid = false

        if (daySegmented.currentIndex === 0) {
            // 星期模式
            var hasDaySelected = dayButtons.selectedDays.length > 0
            if (!hasDaySelected) valid = false
            else if (weekCycleTypeAll.checked) valid = true
            else if (weekCycleTypeCustom.checked && customWeeks.length > 0) valid = true
            else if (weekCycleTypeRound.checked && validRoundWeek()) valid = true
        } else {
            // 日期模式
            valid = !!dayDate.selectedDate
        }

        canAccept = valid
        setOkEnabled(valid)
    }

    ColumnLayout {
        spacing: 24
        Layout.fillWidth: true

        Segmented {
            id: daySegmented
            Layout.fillWidth: true
            onCurrentIndexChanged: checkValid()
            SegmentedItem { text: qsTr("By Week"); icon.name: "ic_fluent_calendar_week_numbers_20_regular" }
            SegmentedItem { text: qsTr("By Date"); icon.name: "ic_fluent_calendar_20_regular" }
        }

        RowLayout {
            Text { text: qsTr("ID"); width: 100 }
            TextField { id: dayId; Layout.fillWidth: true; readOnly: true;}
            visible: false
        }

        RowLayout {
            visible: daySegmented.currentIndex === 1
            Text { text: qsTr("Date"); width: 100 }

            Item { Layout.fillWidth: true }

            CalendarDatePicker {
                id: dayDate
                onSelectedDateChanged: checkValid()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: daySegmented.currentIndex === 0

            ColumnLayout {
                spacing: 6
                Text { text: qsTr("Days of Week") }

                WeekdaySelector {
                    id: dayButtons
                    Layout.fillWidth: true
                    onSelectionChanged: dayEditor.checkValid()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                Text { text: qsTr("Week")}

                RowLayout {
                    id: weekCycleTypeColumn
                    spacing: 12
                    RadioButton { id: weekCycleTypeAll; text: qsTr("Every Week"); onCheckedChanged: dayEditor.checkValid() }
                    RadioButton { id: weekCycleTypeRound; text: qsTr("Repeat on a Cycle"); onCheckedChanged: dayEditor.checkValid() }
                    RadioButton {
                        id: weekCycleTypeCustom
                        text: qsTr("Specific Weeks")
                        onCheckedChanged: dayEditor.checkValid()
                        onClicked: {
                            if (dayEditor.customWeeks.length > 0)
                                return
                            const week = dayEditor.firstAvailableCustomWeek()
                            if (week > 0)
                                dayEditor.customWeeks = [week]
                        }
                    }
                }

                RowLayout {
                    visible: weekCycleTypeRound.checked
                    spacing: 2
                    Text { text: weekCyclePrefix }
                    ComboBox {
                        id: weekCycleRound
                        model: dayEditor.roundWeekOptions
                        Layout.preferredWidth: 72
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: dayEditor.roundWeekIndex(dayEditor.roundWeek)
                        onActivated: {
                            const option = dayEditor.roundWeekOptions[currentIndex]
                            if (option)
                                dayEditor.roundWeek = option.value
                        }
                    }
                    Text { text: weekCycleSuffix }
                }

                SpecificWeekEditor {
                    id: weekCycleCustom
                    visible: weekCycleTypeCustom.checked
                    Layout.fillWidth: true
                    onWeeksEdited: value => dayEditor.customWeeks = value
                }
            }
        }
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        property Button okButton: standardButton(DialogButtonBox.Ok)

        onAccepted: {
            var dayOfWeekValue = []
            var date = ""
            var weeks = undefined

            if (daySegmented.currentIndex === 0) {
                // 星期模式
                dayOfWeekValue = dayButtons.selectedDays.slice()
                if (weekCycleTypeAll.checked) {
                    weeks = "all"
                } else if (weekCycleTypeRound.checked) {
                    weeks = roundWeek
                } else if (weekCycleTypeCustom.checked) {
                    weeks = customWeeks.slice()
                }
            } else {
                // 日期模式
                date = dayDate.selectedDate
                weeks = "all"
            }

            if (currentId) {
                AppCentral.scheduleEditor.updateDay(currentId, dayOfWeekValue, weeks, date)
            } else {
                AppCentral.scheduleEditor.addDay(dayOfWeekValue, weeks, date)
            }
        }
        onRejected: dayEditor.close()

        Component.onCompleted: {
            Qt.callLater(function() {
                dayEditor.setOkEnabled(dayEditor.canAccept)
            })
        }
    }
}
