import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

RowLayout {

    id: weekCycleEditor

    property int maxWeekCycle: AppCentral.scheduleEditor.meta.maxWeekCycle
    property string selectedType: "all"    // "all" | "round" | "custom"
    property int roundWeek: 1
    property int customWeek: 1
    property var roundWeekOptions: []

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
        roundWeekOptions = options
    }

    function normalizeRoundWeek() {
        var cycleLength = Math.max(1, maxWeekCycle)
        if (roundWeek < 1) {
            roundWeek = 1
        } else if (roundWeek > cycleLength) {
            roundWeek = cycleLength
        }
    }

    onMaxWeekCycleChanged: {
        normalizeRoundWeek()
        updateRoundWeekOptions()
    }
    Component.onCompleted: {
        normalizeRoundWeek()
        updateRoundWeekOptions()
    }
    spacing: 12

    // 页面格式翻译
    property string weekCycleFormat: qsTr("Week {value} of every %1 weeks").arg(maxWeekCycle)
    property string weekCyclePrefix: weekCycleFormat.split("{value}")[0]
    property string weekCycleSuffix: weekCycleFormat.split("{value}")[1]
    property string weekFormat: qsTr("Week {value}")
    property string weekPrefix: weekFormat.split("{value}")[0]
    property string weekSuffix: weekFormat.split("{value}")[1]

    // ButtonGroup { id: weekCycleType; buttons: typeRow.children }

    Segmented {
        id: typeRow
        SegmentedItem {
            text: qsTr("Every Week")
            checked: true
            onCheckedChanged: if (checked) weekCycleEditor.selectedType = "all"
        }
        SegmentedItem {
            text: qsTr("Repeat on a Cycle")
            onCheckedChanged: if (checked) weekCycleEditor.selectedType = "round"
        }
        SegmentedItem {
            text: qsTr("One Specific Week")
            onCheckedChanged: if (checked) weekCycleEditor.selectedType = "custom"
        }
    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        visible: weekCycleEditor.selectedType === "round"
        spacing: 2
        Text { text: weekCyclePrefix }
        ComboBox {
            id: roundBox
            model: weekCycleEditor.roundWeekOptions
            Layout.preferredWidth: 72
            textRole: "text"
            valueRole: "value"
            currentIndex: Math.max(0, weekCycleEditor.roundWeek - 1)
            onActivated: weekCycleEditor.roundWeek = currentIndex + 1
        }
        Text { text: weekCycleSuffix }
    }

    RowLayout {
        visible: weekCycleEditor.selectedType === "custom"
        spacing: 2
        Text { text: weekPrefix }
        SpinBox {
            id: customBox
            from: 1
            to: 9999
            value: weekCycleEditor.customWeek
            onValueChanged: weekCycleEditor.customWeek = value
        }
        Text { text: weekSuffix }
    }
}
