import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Dialog {
    id: reScheduleDayDialog
    title: qsTr("Reschedule day")
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true

    // selectedWeekday: 1..7, 0 表示未选择
    property int selectedWeekday: 0
    property string selectedDate: ""

    onOpened: {
        // 初始化 selection 与 date
        selectedWeekday = 0
        footer.okButton.enabled = false

        selectedDate = Qt.formatDateTime(new Date(), "yyyy-MM-dd")
        rescheduleDayDatePicker.setDate(selectedDate)
    }

    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: qsTr("Apply a day-of-week schedule to a specific date")
            wrapMode: Text.Wrap
        }

        DatePicker {
            id: rescheduleDayDatePicker
            Layout.fillWidth: true

            // 日期变更时更新 selectedDate（用于保存）
            onDateChanged: {
                selectedDate = Qt.formatDate(rescheduleDayDatePicker.date, "yyyy-MM-dd")
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 4

            // 按周一..周日生成按钮
            Repeater {
                model: 7
                delegate: PillButton {
                    ButtonGroup.group: rescheduleDayButtonGroup

                    // iso-weekday
                    property int weekday: index + 1

                    text: locale.standaloneDayName(weekday, Locale.ShortFormat)

                    onClicked: {
                        reScheduleDayDialog.selectedWeekday = weekday
                        footer.okButton.enabled = true
                    }
                }
            }
        }
    }

    ButtonGroup {
        id: rescheduleDayButtonGroup
        exclusive: true
    }

    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
        property Button okButton: standardButton(DialogButtonBox.Ok)

        Component.onCompleted: {
            okButton.enabled = false
        }

        onAccepted: {
            if (reScheduleDayDialog.selectedWeekday > 0 && reScheduleDayDialog.selectedDate.length > 0) {
                Configs.set(
                    `schedule.reschedule_day.${reScheduleDayDialog.selectedDate}`, reScheduleDayDialog.selectedWeekday
                )
                reScheduleDayDialog.close()
            }
        }

        onRejected: reScheduleDayDialog.close()
    }
}
