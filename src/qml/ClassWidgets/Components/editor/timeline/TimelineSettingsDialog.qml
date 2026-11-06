import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Dialog {
    id: root

    signal settingsAccepted(string dateString, int maxWeekCycle)

    modal: true
    title: qsTr("Start Date & Maximum Rotation Weeks")
    width: 480
    standardButtons: Dialog.Ok | Dialog.Cancel

    function openFor(startDate, maxWeekCycle) {
        startDatePicker.selectedDate = startDate
        maxWeekCycleBox.value = maxWeekCycle
        open()
    }

    ColumnLayout {
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.preferredWidth: 200
                Text {
                    text: qsTr("Start date")
                    typography: Typography.Body
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("The first day of the schedule, used for multi-week rotation. Usually a Monday.")
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                    wrapMode: Text.WordWrap
                }
            }

            Item { Layout.fillWidth: true }

            CalendarDatePicker {
                id: startDatePicker
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignVCenter
                textFormat: "yyyy/M/d"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.preferredWidth: 200
                Text {
                    text: qsTr("Maximum Rotation Weeks")
                    typography: Typography.Body
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("Most schools alternate weekly (every 2 weeks). Choose as needed.")
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                    wrapMode: Text.WordWrap
                }
            }

            Item { Layout.fillWidth: true }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: qsTr("Every")
                    typography: Typography.Body
                }
                SpinBox {
                    id: maxWeekCycleBox
                    Layout.preferredWidth: 124
                    from: 1
                    to: 12
                }
                Text {
                    text: qsTr("weeks")
                    typography: Typography.Body
                }
            }
        }
    }

    onAccepted: root.settingsAccepted(
        Qt.formatDate(startDatePicker.selectedDate, "yyyy-MM-dd"),
        maxWeekCycleBox.value
    )
}
