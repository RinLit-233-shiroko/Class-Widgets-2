import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Flow {
    id: root

    property var days: []
    property var selectedDays: []
    property var dayNames: [
        qsTr("Mon"), qsTr("Tue"), qsTr("Wed"),
        qsTr("Thu"), qsTr("Fri"), qsTr("Sat"), qsTr("Sun")
    ]

    signal selectionChanged(var days)

    Layout.fillWidth: true
    spacing: 4

    onDaysChanged: selectedDays = (days || []).map(Number)
    Component.onCompleted: selectedDays = (days || []).map(Number)

    function hasDay(day) {
        return selectedDays.indexOf(Number(day)) !== -1
    }

    function toggleDay(day) {
        const value = Number(day)
        const result = (selectedDays || []).map(Number)
        const index = result.indexOf(value)
        if (index === -1)
            result.push(value)
        else
            result.splice(index, 1)
        result.sort((left, right) => left - right)
        selectedDays = result
        selectionChanged(result)
    }

    Repeater {
        model: root.dayNames

        PillButton {
            text: modelData
            checked: root.hasDay(index + 1)
            onClicked: root.toggleDay(index + 1)
        }
    }
}