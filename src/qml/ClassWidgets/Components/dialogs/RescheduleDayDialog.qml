import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Dialog {
    id: reScheduleDayDialog

    // width: 400
    title: qsTr("Reschedule Day")
    modal: true

    // selectedWeekday: 1..7（ISO 星期），0 表示尚未选择
    property int selectedWeekday: 0
    property string selectedDate: ""

    // 当前课程表的多周轮换长度，用于结果预览里的「单周 / 双周 / 第 N 周」
    readonly property int maxWeekCycle: {
        const cycle = Number(AppCentral.scheduleRuntime.scheduleMeta.maxWeekCycle)
        return isFinite(cycle) && cycle >= 1 ? Math.floor(cycle) : 1
    }
    // 所选日期落在当前周期的第几周；0 表示日期不可用
    property int weekOfCycle: 0
    property bool selectedDateIsToday: false
    readonly property bool canApply: selectedWeekday >= 1 && selectedDate.length > 0

    // 与 WeekdaySelector 保持一致：短格式星期名（中文为「周一…周日」）
    readonly property var weekdayNames: [
        qsTr("Mon"), qsTr("Tue"), qsTr("Wed"), qsTr("Thu"),
        qsTr("Fri"), qsTr("Sat"), qsTr("Sun")
    ]

    // ── 日期与周次 ─────────────────────────────────────────

    function parseDate(value) {
        const parts = String(value || "").split("-")
        if (parts.length !== 3)
            return null
        const date = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]))
        return isFinite(date.getTime()) ? date : null
    }

    // 与后端一致：按自然日计算天数差，避免夏令时导致的小数天偏差。
    function dayOffset(from, to) {
        const start = Date.UTC(from.getFullYear(), from.getMonth(), from.getDate())
        const end = Date.UTC(to.getFullYear(), to.getMonth(), to.getDate())
        return Math.round((end - start) / 86400000)
    }

    // 对应后端 utils.get_week_number()
    function absoluteWeek(date) {
        const start = parseDate(AppCentral.scheduleRuntime.scheduleMeta.startDate)
        if (!date || !start)
            return 0
        const delta = dayOffset(start, date)
        return delta >= 0 ? Math.floor(delta / 7) + 1 : -Math.ceil(-delta / 7)
    }

    // 对应后端 utils.get_cycle_week()
    function cycleWeek(week) {
        const cycle = maxWeekCycle
        return week >= 1
            ? ((week - 1) % cycle) + 1
            : (((week % cycle) + cycle) % cycle) + 1
    }

    function cycleLabel() {
        if (maxWeekCycle <= 1 || weekOfCycle < 1)
            return ""
        if (maxWeekCycle === 2)
            return weekOfCycle === 1 ? qsTr("Odd Week") : qsTr("Even Week")
        return qsTr("Week %1").arg(weekOfCycle)
    }

    function sameDay(left, right) {
        return !!left && !!right
            && left.getFullYear() === right.getFullYear()
            && left.getMonth() === right.getMonth()
            && left.getDate() === right.getDate()
    }

    function previewText() {
        if (selectedWeekday < 1)
            return qsTr("* Select a weekday to see which timetable will be used")
        const weekLabel = cycleLabel()
        return qsTr("* %1%2 will follow the %3%4 timetable")
            .arg(Qt.formatDate(datePicker.selectedDate, qsTr("yyyy MMMM d")))
            .arg(selectedDateIsToday ? qsTr("(Today)") : "")
            .arg(weekdayNames[selectedWeekday - 1])
            .arg(weekLabel.length > 0 ? qsTr("(%1)").arg(weekLabel) : "")
    }

    function refreshSelection() {
        const date = datePicker.selectedDate
        selectedDate = date ? Qt.formatDate(date, "yyyy-MM-dd") : ""
        weekOfCycle = date ? cycleWeek(absoluteWeek(date)) : 0
        selectedDateIsToday = sameDay(date, new Date())
    }

    // ── 生命周期 ───────────────────────────────────────────

    onAboutToShow: {
        selectedWeekday = 0
        syncWeekdayButton()
        if (!datePicker.selectedDate)
            datePicker.selectedDate = new Date()
        refreshSelection()
    }

    onMaxWeekCycleChanged: refreshSelection()
    onSelectedWeekdayChanged: syncWeekdayButton()

    // 独占 ButtonGroup 只会在点击时更新选中项，这里把 selectedWeekday 反向同步到按钮
    function syncWeekdayButton() {
        if (!weekdayPills)
            return
        if (selectedWeekday < 1 || selectedWeekday > weekdayPills.count) {
            rescheduleDayButtonGroup.checkedButton = null
            return
        }
        const target = weekdayPills.itemAt(selectedWeekday - 1)
        if (target && !target.checked)
            rescheduleDayButtonGroup.checkedButton = target
    }

    ColumnLayout {
        id: contentColumn
        spacing: 12

        Text {
            Layout.fillWidth: true
            typography: Typography.Body
            text: qsTr(
                "When a holiday shift or another change affects a whole day, "
                + "you can apply another weekday's timetable to that date here."
            )
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    typography: Typography.Body
                    text: qsTr("Replace")
                }

                CalendarDatePicker {
                    id: datePicker
                    Layout.preferredWidth: 132
                    Layout.minimumWidth: 132
                    Layout.preferredHeight: 32
                    textFormat: "yyyy/MM/dd"
                    iconSize: 16
                    iconColor: Colors.proxy.textColor

                    onSelectedDateChanged: reScheduleDayDialog.refreshSelection()
                    onDateSelected: reScheduleDayDialog.refreshSelection()
                }

                Text {
                    Layout.fillWidth: true
                    typography: Typography.Body
                    elide: Text.ElideRight
                    text: qsTr("schedule with")
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    id: weekdayPills
                    model: 7

                    PillButton {
                        ButtonGroup.group: rescheduleDayButtonGroup

                        // iso-weekday
                        property int weekday: index + 1

                        text: reScheduleDayDialog.weekdayNames[index]
                        onClicked: reScheduleDayDialog.selectedWeekday = weekday
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumHeight: 32
            typography: Typography.Caption
            color: Colors.proxy.textSecondaryColor
            text: reScheduleDayDialog.previewText()
        }
    }

    ButtonGroup {
        id: rescheduleDayButtonGroup
        exclusive: true
    }

    footer: DialogButtonBox {
        id: dialogButtons

        // 供外部（如快捷键入口）读取确认按钮状态
        property Button okButton: applyButton

        Button {
            Layout.fillWidth: true
            Layout.preferredWidth: dialogButtons.availableWidth / 2
            text: qsTr("Cancel")
            onClicked: reScheduleDayDialog.close()
        }

        Button {
            id: applyButton
            Layout.fillWidth: true
            Layout.preferredWidth: dialogButtons.availableWidth / 2
            highlighted: true
            text: qsTr("Apply Schedule")
            enabled: reScheduleDayDialog.canApply

            onClicked: {
                if (!reScheduleDayDialog.canApply)
                    return
                Configs.set(
                    `schedule.reschedule_day.${reScheduleDayDialog.selectedDate}`,
                    reScheduleDayDialog.selectedWeekday
                )
                reScheduleDayDialog.close()
            }
        }
    }
}
