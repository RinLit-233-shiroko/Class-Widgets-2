import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Debugger


ColumnLayout {
    Layout.fillWidth: true
    Text {
        typography: Typography.BodyStrong
        text: "Dashboard"
    }
    Frame {
        Layout.fillWidth: true
        ColumnLayout {
            width: parent.width

            // ScheduleRuntime
            Text {
                typography: Typography.BodyStrong
                text: "ScheduleRuntime"
            }
            VarStatus {
                Layout.fillWidth: true
                columns: 3
                Layout.preferredHeight: 300
                model: [
                    { name: "currentTime", value: AppCentral.scheduleRuntime.currentTime },
                    {
                        name: "currentDate",
                        value: JSON.stringify(AppCentral.scheduleRuntime.currentDate)   // 显示字典
                    },
                    { name: "currentDayOfWeek", value: AppCentral.scheduleRuntime.currentDayOfWeek },
                    { name: "currentWeek", value: AppCentral.scheduleRuntime.currentWeek },
                    { name: "currentWeekOfCycle", value: AppCentral.scheduleRuntime.currentWeekOfCycle },
                    { name: "scheduleMeta", value: JSON.stringify(AppCentral.scheduleRuntime.scheduleMeta) },
                    { name: "currentDayEntries", value: JSON.stringify(AppCentral.scheduleRuntime.currentDayEntries) },
                    { name: "currentEntry", value: JSON.stringify(AppCentral.scheduleRuntime.currentEntry) },  // 显示字典
                    { name: "nextEntries", value: JSON.stringify(AppCentral.scheduleRuntime.nextEntries) },
                    { name: "remainingTime", value: JSON.stringify(AppCentral.scheduleRuntime.remainingTime) },  // 显示字典
                    { name: "currentStatus", value: AppCentral.scheduleRuntime.currentStatus },
                    { name: "currentSubject", value: JSON.stringify(AppCentral.scheduleRuntime.currentSubject) },
                    { name: "currentTitle", value: AppCentral.scheduleRuntime.currentTitle }
                ]
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                }
                // reload
                Button {
                    text: "Reload Schedule File"
                    onClicked: AppCentral.reloadSchedule()
                }
            }
        }
    }
}