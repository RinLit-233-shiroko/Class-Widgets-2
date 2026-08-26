import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

import QtQuick.Effects  // shadow

Item {
    // SaveFlyout {}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 8

        // 顶部设置卡片区域
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            SettingCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
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
                Layout.preferredHeight: 84
                title: qsTr("Set default duration")
                description: qsTr("Set the default duration for new classes, breaks, or activities.")
                icon.name: "ic_fluent_clock_bill_20_regular"

                Button {
                    text: qsTr("Set")
                    onClicked: {
                        defaultDurationDialog.open()
                    }
                }
            }
        }

        // 主内容区域
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            DayListView {
                enabled: !AppCentral.scheduleManager.isReadonly()
                id: dayList
            }

            ToolSeparator { Layout.fillHeight: true }

            EntryListView {
                enabled: !AppCentral.scheduleManager.isReadonly()
                id: entryList
                currentDayIndex: dayList.currentIndex
            }
        }
    }

    // Dialogs
    Dialog {
        id: datePickerDialog
        modal: true
        title: qsTr("Set date and max weeks")
        width: 325

        ColumnLayout {
            spacing: 8

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
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            const newDate = datePicker.date
            const startDateOk = AppCentral.scheduleEditor.setStartDate(newDate)
            const maxWeekOk = AppCentral.scheduleEditor.setMaxWeekCycle(maxWeekCycleBox.value)
            if (!startDateOk && !maxWeekOk) {
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

        ColumnLayout {
            spacing: 8

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
}