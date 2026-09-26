import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import "../WeekRule.js" as WeekRule

ColumnLayout {
    id: root
    property alias currentIndex: timelinesView.currentIndex
    property var days: AppCentral.scheduleEditor.days
    readonly property string selectedDayId: timelinesView.currentIndex >= 0 ? days[timelinesView.currentIndex].id : ""
    property string oldId: ""
    property real listTopMargin: 0

    // Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 225
    Layout.maximumWidth: Math.max(parent.width * 0.25, 225)

    function getDayTitle(day) {
        // 日期
        if (day.date) {
            const dateObj = new Date(day.date)
            // getDay(): 0=Sun,1=Mon,...,6=Sat  →  转成 0=Mon..6=Sun 以匹配 getWeekDayName
            const isoIndex = (dateObj.getDay() + 6) % 7
            const dayName = getWeekDayName(isoIndex)
            return qsTr("%1").arg(dayName)
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
                const dateObj = new Date(day.date)
                return Qt.formatDate(dateObj, Qt.locale().dateFormat(Locale.ShortFormat))
            }

            if (day.dayOfWeek) {
                // `weeks` may be an array-like sequence from the backend, so the
                // rule is classified by WeekRule instead of Array.isArray().
                const type = WeekRule.kind(weeks)
                if (type === "all") return qsTr("Every Week")
                if (type === "odd") return qsTr("Odd Week")
                if (type === "even") return qsTr("Even Week")
                if (type === "specific")
                    return qsTr("Weeks %1").arg(WeekRule.specificWeeks(weeks).join(","))
                return qsTr("week %1 of the cycle").arg(weeks)
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

    Item {
        visible: !days.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            width: parent.width * 0.75
            anchors.centerIn: parent
            opacity: 0.5

            Icon {
                Layout.alignment: Qt.AlignCenter
                name: "ic_fluent_square_hint_sparkles_20_regular"
                size: 46
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                typography: Typography.BodyLarge
                text: qsTr("No timelines yet")
            }
            Text {
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                typography: Typography.Caption
                text: qsTr("No timelines yet. Click \"New Timeline\" to get started.")

            }
        }
    }


    ListView {
        visible: model.length > 0
        id: timelinesView
        Layout.fillHeight: true
        Layout.fillWidth: true
        model: days

        header: Item {
            width: timelinesView.width
            height: root.listTopMargin
        }

        // 列表铺满面板后，滚动条也会一直顶到面板上沿，顶部会被悬浮的日期按钮压住。
        // 这里把滚动条整体下移一个按钮高度，让它完整可见。
        // RinUI 的 ScrollBar 内部用 anchors.verticalCenter 定位，必须先清除，
        // 否则会与下面的 anchors.top 冲突。
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            anchors.verticalCenter: undefined
            anchors.top: parent.top
            anchors.topMargin: root.listTopMargin
            height: parent ? parent.height - root.listTopMargin : 0
        }

        onModelChanged: {
            for (let i = 0; i < model.length; i++) {
                if (model[i].id === root.oldId) {
                    currentIndex = i
                    return
                }
            }
        }

        // RinUI 的 ListView 在 onModelChanged 里会跑 updateAnimation：
        // 它把 contentY 从 -12 动画到 0。带 header 时列表"顶部"是 -headerHeight，
        // 这个动画会把 header 占位整段滚出视口，首项于是落到视口 y=0，
        // 正好被悬浮的日期按钮压住 —— 这就是进页面时默认被遮挡的原因。
        // 这里换成不含 contentY 的版本：保留淡入，不再改写滚动位置。
        updateAnimation: ParallelAnimation {
            NumberAnimation {
                target: timelinesView
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuart
            }
        }

        delegate: ListViewDelegate {
            contentItem: RowLayout {
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: getDayTitle(modelData); font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                // Text { text: modelData.id; font.pixelSize: 12; color: Theme.currentTheme.colors.textSecondaryColor; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { text: getDaySubtitle(modelData); font.pixelSize: 12; color: Theme.currentTheme.colors.textSecondaryColor; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                Button {
                    icon.name: "ic_fluent_more_vertical_20_regular"
                    flat: true
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
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
                        text: qsTr("Remove")
                        onTriggered: AppCentral.scheduleEditor.removeDay(modelData.id)  // 删除日程
                    }
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
        Button {
            flat: true; icon.name: "ic_fluent_document_copy_20_regular"; text: qsTr("Duplicate")
            enabled: selectedDayId !== ""
            onClicked: AppCentral.scheduleEditor.duplicateDay(selectedDayId)  // 复制
        }
        // 复制（后端暂无接口）
    }

    DayEditor {
        id: dayEditor
    }
}
