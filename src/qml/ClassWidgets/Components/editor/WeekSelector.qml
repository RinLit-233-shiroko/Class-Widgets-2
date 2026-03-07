import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

ColumnLayout {

    id: weekCycleEditor

    property int maxWeekCycle: AppCentral.scheduleEditor.meta.maxWeekCycle
    property string selectedType: "all"    // "all" | "round" | "custom"
    property int roundWeek: 1
    property int customWeek: 1

    // 核心：对外暴露统一的 currentWeek
    property var currentWeek: -1
    onSelectedTypeChanged: updateCurrentWeek()
    onRoundWeekChanged: updateCurrentWeek()
    onCustomWeekChanged: updateCurrentWeek()

    function updateCurrentWeek() {
        if (selectedType === "all") {
            currentWeek = -1 // -1 表示全周
        } else if (selectedType === "round") {
            currentWeek = roundWeek
        } else if (selectedType === "custom") {
            currentWeek = [customWeek]
        }
    }
    spacing: 12

    // Text {
    //     text: qsTr("Cycle Mode")
    //     font.bold: true
    // }

    ButtonGroup { id: weekCycleType; buttons: typeRow.children }

    ColumnLayout {
        id: typeRow
        RadioButton {
            text: qsTr("Every Week")
            checked: true
            onCheckedChanged: if (checked) weekCycleEditor.selectedType = "all"
        }
        RadioButton {
            text: qsTr("Round")
            onCheckedChanged: if (checked) weekCycleEditor.selectedType = "round"
        }
        RadioButton {
            text: qsTr("Custom")
            onCheckedChanged: if (checked) weekCycleEditor.selectedType = "custom"
        }
    }

    RowLayout {
        visible: weekCycleEditor.selectedType === "round"
        spacing: 8
        Text { text: qsTr("Week of Cycle:"); width: 120 }
        SpinBox {
            id: roundBox
            from: 1
            to: weekCycleEditor.maxWeekCycle
            value: weekCycleEditor.roundWeek
            onValueChanged: weekCycleEditor.roundWeek = value
        }
    }

    RowLayout {
        visible: weekCycleEditor.selectedType === "custom"
        spacing: 8
        Text { text: qsTr("Week Index:"); width: 120 }
        SpinBox {
            id: customBox
            from: 1
            to: 9999
            value: weekCycleEditor.customWeek
            onValueChanged: weekCycleEditor.customWeek = value
        }
    }
}
