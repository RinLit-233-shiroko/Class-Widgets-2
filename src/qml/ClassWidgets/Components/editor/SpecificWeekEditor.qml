import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "WeekRule.js" as WeekRule

ColumnLayout {
    id: root

    property var weeks: []
    property var blockedWeeks: []
    property int pendingWeek: 1

    signal weeksEdited(var weeks)

    readonly property int maxSpinBoxValue: 2147483647
    // `weeks` may arrive straight from a C++ property, where a Python list is
    // an array-like sequence rather than a JS Array (see WeekRule.js).
    readonly property var selectedWeeks: WeekRule.specificWeeks(weeks)
    readonly property var unavailableWeeks: {
        const result = selectedWeeks.slice()
        const blocked = WeekRule.specificWeeks(blockedWeeks)
        for (let i = 0; i < blocked.length; ++i) {
            if (result.indexOf(blocked[i]) === -1)
                result.push(blocked[i])
        }
        return result
    }
    readonly property bool canAddWeek: pendingWeek >= 1
        && unavailableWeeks.indexOf(pendingWeek) === -1
    readonly property string weekFormat: qsTr("Week {value}")
    readonly property string weekPrefix: weekFormat.split("{value}")[0]
    readonly property string weekSuffix: weekFormat.split("{value}")[1]

    spacing: 8

    onPendingWeekChanged: syncSpinBox()

    Component.onCompleted: normalizePendingWeek()

    function weekLabel(value) {
        return weekFormat.replace("{value}", String(value))
    }

    function normalizePendingWeek() {
        const current = Number(pendingWeek)
        pendingWeek = isFinite(current)
            ? Math.max(1, Math.min(maxSpinBoxValue, Math.floor(current)))
            : 1
    }

    function nextUnusedWeek(value) {
        let result = Math.max(1, Math.floor(Number(value) || 1))
        const blocked = Array.isArray(blockedWeeks) ? blockedWeeks : []
        while (result < maxSpinBoxValue
                && (selectedWeeks.indexOf(result) !== -1
                    || blocked.indexOf(result) !== -1))
            ++result
        return result
    }

    function addPendingWeek() {
        if (!canAddWeek)
            return

        const result = selectedWeeks.slice()
        result.push(pendingWeek)
        result.sort((left, right) => left - right)
        weeksEdited(result)
        pendingWeek = nextUnusedWeek(pendingWeek + 1)
    }

    function removeWeek(value) {
        const target = Number(value)
        const result = selectedWeeks.filter(week => week !== target)
        weeksEdited(result)
        normalizePendingWeek()
    }

    function syncSpinBox() {
        if (customWeekSpinBox && customWeekSpinBox.value !== pendingWeek)
            customWeekSpinBox.value = pendingWeek
    }

    Flow {
        Layout.fillWidth: true
        spacing: 10
        visible: root.selectedWeeks.length > 0

        Repeater {
            model: root.selectedWeeks

            PillButton {
                text: root.weekLabel(modelData)
                onClicked: root.removeWeek(modelData)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
            spacing: 2
            Text {
                text: root.weekPrefix
            }

            SpinBox {
                id: customWeekSpinBox
                Layout.preferredWidth: 124
                Layout.minimumWidth: 124
                Layout.preferredHeight: 32
                from: 1
                to: root.maxSpinBoxValue
                value: root.pendingWeek
                editable: false
                onValueChanged: {
                    if (value !== root.pendingWeek)
                        root.pendingWeek = value
                }
            }

            Text {
                text: root.weekSuffix
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Button {
            enabled: root.canAddWeek
            onClicked: root.addPendingWeek()
            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("Add")
        }
    }
}