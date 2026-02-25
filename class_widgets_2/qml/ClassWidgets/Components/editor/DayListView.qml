import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

ColumnLayout {
    id: root
    property alias currentIndex: timelinesView.currentIndex
    property var days: AppCentral.scheduleEditor.days
    readonly property string selectedDayId: timelinesView.currentIndex >= 0 ? days[timelinesView.currentIndex].id : ""
    property string oldId: ""

    // Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 225
    Layout.maximumWidth: Math.max(parent.width * 0.25, 225)

    function getDayTitle(day) {
        // 日期
        if (day.date) {
            const dateObj = new Date(day.date)
            const dayName = getWeekDayName(dateObj.getDay())
            return qsTr("%1").arg(dayName)  // 这里只显示日期或星期名字
        }

        // 星期
        if (day.dayOfWeek) {
            const selected = normalizeDayOfWeek(day.dayOfWeek)
            let dayName = ""
            if (selected.length === 5 && selected.every(v => v >= 1 && v <= 5)) {
                dayName = qsTr("Weekdays")
            } else if (selected.length === 2 && selected[0] === 6 && selected[1] === 7) {
                dayName = qsTr("Weekends")
            } else {
                dayName = selected.map(v => getWeekDayName(v - 1)).join(", ")
            }
            return dayName
        }

        return qsTr("Unknown")
    }

        function getDaySubtitle(day) {
            const weeks = day.weeks

            if (day.date) {
                return qsTr("%1").arg(day.date)  // 日期直接显示
            }

            if (day.dayOfWeek) {
                if (weeks === "all") return qsTr("Every Week")
                if (typeof weeks === "number") return qsTr("week %1 of the cycle").arg(weeks)
                if (Array.isArray(weeks)) return qsTr("Weeks %1").arg(weeks.map(w => Number(w)).join(","))
            }

            return ""
        }

    function normalizeDayOfWeek(dayOfWeek) {
        let selected = []
        if (Array.isArray(dayOfWeek) || dayOfWeek.length !== undefined) {
            for (let i = 0; i < dayOfWeek.length; i++) {
                const n = Number(dayOfWeek[i])
                if (!isNaN(n) && n >= 1 && n <= 7) selected.push(n)
            }
        } else {
            const n = Number(dayOfWeek)
            if (!isNaN(n) && n >= 1 && n <= 7) selected.push(n)
        }
        return selected.sort((a, b) => a - b)
    }

    function getWeekDayName(index) {
        const weekDays = [
            qsTr("Mon"), qsTr("Tue"), qsTr("Wed"),
            qsTr("Thu"), qsTr("Fri"), qsTr("Sat"), qsTr("Sun")
        ]
        return weekDays[index]
    }

    SettingCard {
        Layout.fillWidth: true
        title: qsTr("Set start date and max weeks")
        description: qsTr("Set the first day of school to calculate week numbers accurately")
        icon.name: "ic_fluent_calendar_arrow_counterclockwise_20_regular"

        Button {
            text: qsTr("Set")
            onClicked: {
                const currentDate = AppCentral.scheduleEditor.getStartDate()
                datePicker.setDate(currentDate)
                const maxWeekCycle = AppCentral.scheduleEditor.getMaxWeekCycle()
                maxWeekCycleBox.value = maxWeekCycle
                datePickerDialog.open()
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        title: qsTr("Set default duration")
        description: qsTr("Set the default duration for new classes, breaks, or activities.")
        icon.name: "ic_fluent_calendar_arrow_counterclockwise_20_regular"

        Button {
            text: qsTr("Set")
            onClicked: {
                defaultDurationDialog.open()
            }
        }
    }

    Dialog {
        id: datePickerDialog
        modal: true
        title: qsTr("Set date and max weeks")
        width: 325

        Text {
            Layout.fillWidth: true
            text: qsTr("Start date:")
        }
        DatePicker {
            Layout.fillWidth: true
            locale: Qt.locale()
            id: datePicker
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("Max week cycle:")
        }
        SpinBox {
            Layout.fillWidth: true
            id: maxWeekCycleBox
            from: 1
            to: 12
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            const newDate = datePicker.date // 形如 "2025-9-1"
            if (!AppCentral.scheduleEditor.setStartDate(newDate)
                && !AppCentral.scheduleEditor.setMaxWeekCycle(maxWeekCycleBox.value)) {
                floatLayer.createInfoBar({
                    title: qsTr("Failed"),
                    text: qsTr("Failed to set start date or max week cycle. Please report this issue to the community or the developer.") ,
                    severity: Severity.Error,
                    duration: 5000,
                })
            }
        }
    }

    Dialog {
        id: defaultDurationDialog
        modal: true
        title: qsTr("Select Default Duration")
        width: 325

        RowLayout {
            Text {
                Layout.fillWidth: true
                text: qsTr("Class")
            }
            SpinBox {
                id: classDuration
                Layout.preferredWidth: 150
                from: 1
                to: 1440
                stepSize: 5
            }
        }

        RowLayout {
            Text {
                Layout.fillWidth: true
                text: qsTr("Break")
            }
            SpinBox {
                id: breakDuration
                Layout.preferredWidth: 150
                from: 1
                to: 1440
            }
        }

        RowLayout {
            Text {
                Layout.fillWidth: true
                text: qsTr("Activity")
            }
            SpinBox {
                id: activityDuration
                Layout.preferredWidth: 150
                from: 1
                to: 1440
                stepSize: 5
            }
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onOpened: {
            classDuration.value = Configs.data.schedule.default_duration.class_
            breakDuration.value = Configs.data.schedule.default_duration.break_
            activityDuration.value = Configs.data.schedule.default_duration.activity
        }

        onAccepted: {
            Configs.set("schedule.default_duration.class_", classDuration.value)
            Configs.set("schedule.default_duration.break_", breakDuration.value)
            Configs.set("schedule.default_duration.activity", activityDuration.value)
        }

        Component.onCompleted: {
            classDuration.value = Configs.data.schedule.default_duration.class_
            breakDuration.value = Configs.data.schedule.default_duration.break_
            activityDuration.value = Configs.data.schedule.default_duration.activity
        }
    }

    Item {
        visible: !days.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            width: parent.width * 0.75
            anchors.centerIn: parent
            opacity: 0.5

            Icon {
                Layout.alignment: Qt.AlignCenter
                name: "ic_fluent_square_hint_sparkles_20_regular"
                size: 46
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                typography: Typography.BodyLarge
                text: qsTr("No timelines yet")
            }
            Text {
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                typography: Typography.Caption
                text: qsTr("No timelines yet. Click \"New Timeline\" to get started.")

            }
        }
    }


    ListView {
        visible: model.length > 0
        id: timelinesView
        Layout.fillHeight: true
        Layout.fillWidth: true
        model: days

        onModelChanged: {
            for (let i = 0; i < model.length; i++) {
                if (model[i].id === root.oldId) {
                    currentIndex = i
                    return
                }
            }
        }

        delegate: ListViewDelegate {
            middleArea: [
                Text { text: getDayTitle(modelData); font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true },
                // Text { text: modelData.id; font.pixelSize: 12; color: Theme.currentTheme.colors.textSecondaryColor; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: getDaySubtitle(modelData); font.pixelSize: 12; color: Theme.currentTheme.colors.textSecondaryColor; elide: Text.ElideRight; Layout.fillWidth: true }
            ]

            rightArea: Button {
                icon.name: "ic_fluent_more_vertical_20_regular"
                flat: true
                width: 48
                height: 48
                onClicked: contextMenu.open()

                Menu {
                    id: contextMenu
                    MenuItem {
                        icon.name: "ic_fluent_edit_20_regular"
                        text: qsTr("Edit")
                        onTriggered: dayEditor.openFor(modelData)  // 打开编辑模式
                    }
                    MenuItem {
                        icon.name: "ic_fluent_delete_20_regular"
                        text: qsTr("Remove")
                        onTriggered: AppCentral.scheduleEditor.removeDay(modelData.id)  // 删除日程
                    }
                }
            }

            ToolTip {
                delay: 1500
                text: getDayTitle(modelData) + "\n" + getDaySubtitle(modelData) + "\n" + modelData.id
                visible: parent.hovered
            }

            onClicked: {
                root.oldId = modelData.id
            }
        }
    }

    Flow {
        spacing: 4
        Layout.fillWidth: true
        Button {
            flat: true
            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("New Timeline")
            onClicked: dayEditor.openFor(null)  // 新建
        }
        Button {
            flat: true; icon.name: "ic_fluent_document_copy_20_regular"; text: qsTr("Duplicate")
            enabled: selectedDayId !== ""
            onClicked: AppCentral.scheduleEditor.duplicateDay(selectedDayId)  // 复制
        }
        // 复制（后端暂无接口）
    }

    DayEditor {
        id: dayEditor
    }
}
