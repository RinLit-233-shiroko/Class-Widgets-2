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
                        datePicker.setDate(currentDate)
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
            if (!AppCentral.scheduleEditor.setTimelineSettings(newDate, maxWeekCycleBox.value)) {
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
