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


    ListView {
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
                        text: qsTr("Delete")
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
        Button { flat: true; icon.name: "ic_fluent_document_copy_20_regular"; text: qsTr("Duplicate") }  // 复制（后端暂无接口）
    }

    DayEditor {
        id: dayEditor
    }
}
