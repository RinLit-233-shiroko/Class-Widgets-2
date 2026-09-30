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

        // 顶部设置区域
        InfoBar {
            Layout.fillWidth: true
            severity: Severity.Info
            title: qsTr("Customize default durations")
            text: qsTr("Choose default durations for new classes, breaks, and activities to speed up editing.")
            // closable: false

            customContent: Hyperlink {
                text: qsTr("Open Editor Settings")
                onClicked: {
                    navigationView.push(PathManager.qml("pages/editor/Settings.qml"))
                }
            }
        }

        // 主内容区域
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Item {
                id: dayListPane
                Layout.fillHeight: true
                Layout.minimumWidth: 250
                Layout.maximumWidth: Math.max(parent.width * 0.3, 300)

                DayListView {
                    enabled: !AppCentral.scheduleManager.isReadonly()
                    id: dayList
                    anchors.fill: parent
                    listTopMargin: dateButton.implicitHeight + 8
                }

                Clip {
                    id: dateButton
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: Math.max(iconItem.implicitHeight, labelText.implicitHeight) + 16
                    onClicked: {
                        const currentDate = AppCentral.scheduleEditor.getStartDate()
                        const parts = String(currentDate).split("-")
                        datePicker.selectedDate = new Date(
                            Number(parts[0]),
                            Number(parts[1]) - 1,
                            Number(parts[2])
                        )
                        const maxWeekCycle = AppCentral.scheduleEditor.getMaxWeekCycle()
                        maxWeekCycleBox.value = maxWeekCycle
                        datePickerDialog.open()
                    }

                    radius: 6

                    AcrylicBrush {
                        sourceItem: dayList
                    }

                    // 用锚定而不是 Layout 定宽：文本宽度直接由按钮宽度推出，
                    // 避免 Layout 先按 implicitWidth 撑开、导致长文案顶出外框。
                    Icon {
                        id: iconItem
                        size: 20
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        name: "ic_fluent_calendar_arrow_repeat_all_20_regular"
                    }
                    Text {
                        id: labelText
                        anchors.left: iconItem.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: qsTr("Set Start Date & Maximum Rotation Weeks")
                    }
                }
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
        title: qsTr("Start Date & Maximum Rotation Weeks")
        width: 480

        ColumnLayout {
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.preferredWidth: 200
                    Layout.maximumWidth: 200
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
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

                Item {
                    Layout.fillWidth: true
                }

                CalendarDatePicker {
                    id: datePicker
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
                    Layout.maximumWidth: 200
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
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

                Item {
                    Layout.fillWidth: true
                }

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

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            const newDate = datePicker.selectedDate
            const dateStr = newDate ? Qt.formatDate(newDate, "yyyy-MM-dd") : ""
            if (!AppCentral.scheduleEditor.setTimelineSettings(dateStr, maxWeekCycleBox.value)) {
                floatLayer.createInfoBar({
                    title: qsTr("Failed"),
                    text: qsTr("Failed to set start date or max week cycle. Please report this issue to the community or the developer.") ,
                    severity: Severity.Error,
                    duration: 5000,
                })
            }
        }
    }

}
