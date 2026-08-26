import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Debugger


ApplicationWindow {
    id: mainWindow
    title: qsTr("ClassWidgets 调试器")
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
        title: qsTr("编辑课程表")

        SettingExpander {
            Layout.fillWidth: true
            title: qsTr("课表元数据")
            icon.name: "ic_fluent_notepad_20_regular"

            SettingItem {
                title: "ID"
                TextField {
                    text: AppCentral.scheduleEditor.meta.id
                    readOnly: true
                }
            }
            SettingItem {
                title: qsTr("版本")
                TextField {
                    text: AppCentral.scheduleEditor.meta.version
                    readOnly: true
                }
            }
            SettingItem {
                title: qsTr("最大周循环长度")
                SpinBox {
                    from: 1
                    to: 4
                    value: AppCentral.scheduleEditor.meta.maxWeekCycle
                }
            }
            SettingItem {
                title: qsTr("开始日期")
                DatePicker {
                    Component.onCompleted: {
                        setDate(AppCentral.scheduleEditor.meta.startDate)
                    }
                }
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            title: qsTr("课程表")
            icon.name: "ic_fluent_calendar_clock_20_regular"
            action: Button {
                text: qsTr("添加日期")
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
                            text: qsTr("添加")
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
                                    text: getEntryTypeName(modelData.type)
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
    function getEntryTypeName(type) {
        switch (type) {
            case "class": return qsTr("课程")
            case "break": return qsTr("课间")
            case "activity": return qsTr("活动")
            case "free": return qsTr("空闲")
            case "preparation": return qsTr("准备")
            default: return type
        }
    }

    function getDayTitle(day) {
        const weekDays = [qsTr("星期一"), qsTr("星期二"), qsTr("星期三"), qsTr("星期四"), qsTr("星期五"), qsTr("星期六"), qsTr("星期日")]

        if (day.date) {
            // 日期模式
            const dateObj = new Date(day.date)
            const dayName = weekDays[dateObj.getDay() === 0 ? 6 : dateObj.getDay() - 1]  // JS周日是0
            return `${day.date}（${dayName}）`
        }

        if (day.dayOfWeek) {
            const dayName = weekDays[day.dayOfWeek - 1]
            const weeks = day.weeks

            if (weeks === "all") {
                return `${dayName}（${qsTr("全部周")}）`
            } else if (typeof weeks === "number") {
                return `${dayName}（${qsTr("循环")}: ${weeks}）`
            } else if (Array.isArray(weeks)) {
                return `${dayName}（${qsTr("周次")}: ${weeks.join(",")}）`
            }
        }

        return qsTr("未知")
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
            text: qsTr("保存")
            onClicked: AppCentral.scheduleEditor.save()
        }
    }
}