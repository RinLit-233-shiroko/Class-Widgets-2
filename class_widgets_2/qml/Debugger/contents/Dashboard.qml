import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Debugger


ColumnLayout {
    Layout.fillWidth: true
    //
    // EditSchedule {
    //     id: editScheduleWindow
    // }

    Text {
        typography: Typography.BodyStrong
        text: "Dashboard"
    }

    Frame {
        Layout.fillWidth: true
        ColumnLayout {
            anchors.fill: parent
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            Text {
                text: "Logs"
                typography: Typography.BodyStrong
            }
            ListView {
                id: logsList
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                clip: true
                model: UtilsBackend.logs
                spacing: 0

                property bool autoScroll: true

                // onContentYChanged: {
                //     autoScroll = (contentY + height >= contentHeight - 2);
                // }

                onCountChanged: {
                    if (autoScroll) {
                        positionViewAtEnd();
                    }
                }

                delegate: Frame {
                    width: logsList.width
                    HoverHandler { id: logHoverHandler }
                    frameless: !logHoverHandler.hovered
                    leftPadding: 12
                    padding: 4

                    RowLayout {
                        width: parent.width
                        spacing: 10
                        Text {
                            Layout.preferredWidth: 90
                            text: modelData.time; color: Colors.proxy.textSecondaryColor
                        }
                        Text {
                            Layout.preferredWidth: 80
                            text: modelData.level
                            color: {
                                switch (modelData.level) {
                                    case "DEBUG": return Colors.proxy.systemNeutralColor
                                    case "INFO": return Colors.proxy.textColor
                                    case "WARNING": return Colors.proxy.systemCautionColor
                                    case "ERROR": return Colors.proxy.systemCriticalColor
                                    case "SUCCESS": return Colors.proxy.systemSuccessColor
                                    default: return Colors.proxy.textColor
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.message
                            color: {
                                switch (modelData.level) {
                                    case "DEBUG": return Colors.proxy.systemNeutralColor
                                    case "INFO": return Colors.proxy.textColor
                                    case "WARNING": return Colors.proxy.systemCautionColor
                                    case "ERROR": return Colors.proxy.systemCriticalColor
                                    case "SUCCESS": return Colors.proxy.systemSuccessColor
                                    default: return Colors.proxy.textColor
                                }
                            }
                        }
                        ToolButton {
                            flat: true
                            onClicked: {
                                if (UtilsBackend.copyToClipboard(JSON.stringify(modelData))) {
                                    floatLayer.createInfoBar({
                                        severity: Severity.Success,
                                        text: "Copied to clipboard!",
                                    })
                                }
                            }
                            icon.name: "ic_fluent_copy_20_regular"
                            size: 18
                        }
                    }
                }
            }

        }
    }

    Expander {
        text: "Runtime Variables"
        Layout.fillWidth: true
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 12

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Item {
                    Layout.fillWidth: true
                }
                // edit
                // Button {
                //     text: "Edit Schedule"
                //     // onClicked: DebuggerCentral.showEditor()
                //     onClicked: editScheduleWindow.show()
                // }
                // reload
                Button {
                    text: "Reload Schedule File"
                    onClicked: AppCentral.scheduleManager.reload()
                }
            }

            // ScheduleRuntime
            Text {
                typography: Typography.BodyStrong
                text: "ScheduleRuntime"
            }
            VarStatus {
                Layout.fillWidth: true
                columns: 3
                Layout.preferredHeight: 350
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
        }
    }
}