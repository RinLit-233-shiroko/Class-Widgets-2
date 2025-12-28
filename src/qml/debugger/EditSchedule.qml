import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Debugger


ApplicationWindow {
    id: mainWindow
    title: "Class Widgets Debugger"
    width: 900
    height: 600
    minimumWidth: 425
    minimumHeight: 400
    visible: false

    // color: {
    //     if (Theme.isDark()) {
    //         return "#333"
    //     } else {
    //         return "#eee"
    //     }
    // }

    // notification signal from AppCentral.notification.notified
    Item {
        id: notificationLayer
        property var level: [Severity.Info, Severity.Success, Severity.Warning, Severity.Error]

        Connections {
            target: AppCentral.notification
            onNotified: (payload) => {
                // 处理通知数据
                var levelIndex = payload.level || 0
                var title = payload.title || "通知"
                var message = payload.message || ""
                
                floatLayer.createInfoBar({
                    severity: notificationLayer.level[levelIndex],
                    title: title,
                    text: message
                })
            }
        }
    }

    FluentPage {
        anchors.fill: parent
        title: "Edit Schedule"

        SettingExpander {
            Layout.fillWidth: true
            title: "MetaInfo"
            icon.name: "ic_fluent_notepad_20_regular"

            SettingItem {
                title: "ID"
                TextField {
                    text: AppCentral.scheduleEditor.meta.id
                    readOnly: true
                }
            }
            SettingItem {
                title: "Version"
                TextField {
                    text: AppCentral.scheduleEditor.meta.version
                    readOnly: true
                }
            }
            SettingItem {
                title: "fMax Week Cycle Length"
                SpinBox {
                    from: 1
                    to: 4
                    value: AppCentral.scheduleEditor.meta.maxWeekCycle
                }
            }
            SettingItem {
                title: "Start Date"
                DatePicker {
                    Component.onCompleted: {
                        setDate(AppCentral.scheduleEditor.meta.startDate)
                    }
                }
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            title: "Schedule"
            icon.name: "ic_fluent_calendar_clock_20_regular"
            action: Button {
                text: "Add Day"
                onClicked: AppCentral.scheduleEditor.addDay(
                    0, null, null
                )
            }

            Repeater {
                id: daysRepeater
                model: AppCentral.scheduleEditor.days

                // 天编辑
                SettingExpander {
                    title: getDayTitle(modelData)
                    description: modelData.id
                    Layout.fillWidth: true
                    DayEditor {
                        id: dayEditor
                    }

                    action: Row {
                        spacing: 4
                        Button {
                            icon.name: "ic_fluent_add_20_regular"
                            text: "Add"
                            onClicked: AppCentral.scheduleEditor.addEntry(
                                modelData.id, "class", null, null, null, null
                            )
                        }
                        ToolButton {
                            icon.name: "ic_fluent_delete_20_regular"
                            onClicked: AppCentral.scheduleEditor.removeDay(modelData.id)
                        }
                        ToolButton {
                            icon.name: "ic_fluent_edit_20_regular"
                            onClicked: dayEditor.open()
                        }
                    }

                    // 课程编辑
                    Repeater {
                        id: entriesRepeater
                        model: modelData.entries

                        SettingItem {
                            title: modelData.subjectId || modelData.title
                            description: modelData.id
                            EntryEditor {
                                id: entryEditor
                            }

                            RowLayout {
                                InfoBadge {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: modelData.type
                                    severity: {
                                        switch (modelData.type) {
                                            case "class": return Severity.Error
                                            case "break": return Severity.Success
                                            case "activity": return Severity.Warning
                                        }
                                    }
                                }
                                spacing: 8
                                ToolButton {
                                    icon.name: "ic_fluent_edit_20_regular"
                                    onClicked: entryEditor.open()
                                }
                                ToolButton {
                                    icon.name: "ic_fluent_delete_20_regular"
                                    onClicked: AppCentral.scheduleEditor.removeEntry(modelData.id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    // func
    function getDayTitle(day) {
        const weekDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

        if (day.date) {
            // 日期模式
            const dateObj = new Date(day.date)
            const dayName = weekDays[dateObj.getDay() === 0 ? 6 : dateObj.getDay() - 1]  // JS周日是0
            return `${day.date} (${dayName})`
        }

        if (day.dayOfWeek) {
            const dayName = weekDays[day.dayOfWeek - 1]
            const weeks = day.weeks

            if (weeks === "all") {
                return `${dayName} (All Weeks)`
            } else if (typeof weeks === "number") {
                return `${dayName} (Cycle: ${weeks})`
            } else if (Array.isArray(weeks)) {
                return `${dayName} (Weeks: ${weeks.join(",")})`
            }
        }

        return "Unknown"
    }

    Frame {
        background: Item {}
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: 40

        Button {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            highlighted: false
            text: "Save"
            onClicked: AppCentral.scheduleEditor.save()
        }
    }
}