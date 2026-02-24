import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Dialog {
    id: dayEditor
    modal: true
    width: 420
    title: currentId ? qsTr("Edit Timeline") : qsTr("New Timeline")

    property string currentId: ""         // 如果有 id = 编辑，否则 = 新建
    property var currentData: ({})        // 临时缓存的数据副本

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
        if (currentData.date) dayDate.setDate(currentData.date)

        // 星期
        for (var i = 0; i < dayButtons.count; i++) {
            dayButtons.itemAt(i).checked = false
        }
        if (currentData.dayOfWeek) {
            var indices = []
            if (currentData.dayOfWeek.length !== undefined) {
                for (var i = 0; i < currentData.dayOfWeek.length; i++) {
                    var n = Number(currentData.dayOfWeek[i])
                    if (!isNaN(n)) indices.push(n - 1)
                }
            } else {
                var n = Number(currentData.dayOfWeek)
                if (!isNaN(n)) indices.push(n - 1)
            }
            for (var j = 0; j < indices.length; j++) {
                if (indices[j] >= 0 && indices[j] < dayButtons.count) {
                    dayButtons.itemAt(indices[j]).checked = true
                }
            }
        }

        // 周循环
        weekCycleTypeAll.checked = currentData.weeks === "all"
        weekCycleTypeRound.checked = typeof currentData.weeks === "number"
        if (weekCycleTypeRound.checked) weekCycleRound.value = currentData.weeks
        weekCycleTypeCustom.checked = Array.isArray(currentData.weeks)

        checkValid()
    }

    // 检查是否可以启用 Ok
    function checkValid() {
        var valid = false

        if (daySegmented.currentIndex === 0) {
            // 星期模式
            var hasDaySelected = false
            for (var i = 0; i < dayButtons.count; i++) {
                if (dayButtons.itemAt(i).checked) { hasDaySelected = true; break }
            }
            if (!hasDaySelected) valid = false
            else if (weekCycleTypeAll.checked || weekCycleTypeCustom.checked) valid = true
            else if (weekCycleTypeRound.checked && weekCycleRound.value >= 1) valid = true
        } else {
            // 日期模式
            valid = !!dayDate.date
        }

        footer.okButton.enabled = valid
    }

    ColumnLayout {
        spacing: 12
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
            TextField { id: dayId; Layout.fillWidth: true; readOnly: true }
        }

        RowLayout {
            visible: daySegmented.currentIndex === 1
            Text { text: qsTr("Date"); width: 100 }
            DatePicker {
                id: dayDate
                Layout.fillWidth: true
                onDateChanged: checkValid()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: daySegmented.currentIndex === 0

            RowLayout {
                spacing: 8
                Text { text: qsTr("Days of Week"); width: 100 }
                Flow {
                    Layout.fillWidth: true
                    spacing: 4
                    Repeater {
                        id: dayButtons
                        model: [
                            qsTr("Mon"), qsTr("Tue"), qsTr("Wed"),
                            qsTr("Thu"), qsTr("Fri"), qsTr("Sat"), qsTr("Sun")
                        ]
                        delegate: PillButton {
                            text: modelData
                            onCheckedChanged: dayEditor.checkValid()
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                ButtonGroup { id: weekCycleType; buttons: weekCycleTypeColumn.children }
                RowLayout {
                    id: weekCycleTypeColumn
                    RadioButton { id: weekCycleTypeAll; text: qsTr("Every Week"); onCheckedChanged: dayEditor.checkValid() }
                    RadioButton { id: weekCycleTypeRound; text: qsTr("Specific Round"); onCheckedChanged: dayEditor.checkValid() }
                    RadioButton { id: weekCycleTypeCustom; text: qsTr("Custom"); onCheckedChanged: dayEditor.checkValid(); enabled: false }
                }
            }

            RowLayout {
                visible: weekCycleTypeRound.checked
                Text { text: qsTr("Week of Cycle"); width: 100 }
                SpinBox { id: weekCycleRound; from: 1; to: AppCentral.scheduleEditor.meta.maxWeekCycle; onValueChanged: dayEditor.checkValid() }
            }
        }
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        property Button okButton: standardButton(DialogButtonBox.Ok)

        onAccepted: {
            var dayOfWeekValue = []
            var date = undefined
            var weeks = undefined

            if (daySegmented.currentIndex === 0) {
                // 星期模式
                for (let i = 0; i < dayButtons.count; i++) {
                    if (dayButtons.itemAt(i).checked) dayOfWeekValue.push(i + 1)
                }
                if (weekCycleTypeAll.checked) {
                    weeks = "all"
                } else if (weekCycleTypeRound.checked) {
                    weeks = weekCycleRound.value
                } else if (weekCycleTypeCustom.checked) {
                    weeks = []  // TODO: custom 逻辑
                }
            } else {
                // 日期模式
                date = dayDate.date
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
            okButton.enabled = false
        }
    }
}
