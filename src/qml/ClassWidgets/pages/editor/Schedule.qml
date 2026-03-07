import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

import QtQuick.Effects  // shadow

Item {
    id: root
    // SaveFlyout { id: saveFlyout }
    function quickAddSubject(subjectid) {
        let row = scheduleTable.selectedCell.row
        let column = scheduleTable.selectedCell.column

        // 如果没有选中单元格，默认选择第一行第一列
        if (row < 0 || column < 0) {
            row = 0
            column = 0
        }

        let day = scheduleTable.getDayByColumn(column)
        let entry = scheduleTable.getEntryByDayAndRow(day, row, column)
        if (!entry) return;

        let weeks;
        if (scheduleTable.currentWeek === -1) {
            weeks = "all"; // 字符串
        } else if (Array.isArray(scheduleTable.currentWeek)) {
            weeks = scheduleTable.currentWeek.map(w => Number(w)); // 强制 int
        } else {
            weeks = Number(scheduleTable.currentWeek); // 单 int
        }

        let dayOfWeek = [column + 1]

        // 调用 scheduleEditor 的逻辑
        const existingId = AppCentral.scheduleEditor.findOverride(entry.id, dayOfWeek, weeks)
        if (existingId) {
            AppCentral.scheduleEditor.updateOverride(existingId, subjectid, null)
        } else {
            AppCentral.scheduleEditor.addOverride(entry.id, dayOfWeek, weeks, subjectid, null)
        }

        // 更新表格显示
        scheduleTable.currentEntry = scheduleTable.getEntryByDayAndRow(day, row, column)

        // 移动焦点到下一行
        let nextRow = row + 1
        let nextColumn = column

        if (nextRow === scheduleTable.maxRows) {
            nextRow = 0
            nextColumn = column + 1
            if (nextColumn >= 7) nextColumn = 0 // 超出一周列就回到第一列
        }

        scheduleTable.selectedCell = { row: nextRow, column: nextColumn }
    }

    property bool editable: segmented.currentIndex === 1  // 是否可编辑

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 24
        // anchors.topMargin: 24 + saveFlyout.height
        spacing: 10

        Segmented {
            id: segmented
            Layout.alignment: Qt.AlignCenter

            SegmentedItem {
                icon.name: "ic_fluent_content_view_20_regular"
                text: qsTr("Preview")
            }

            SegmentedItem {
                icon.name: "ic_fluent_calendar_edit_20_regular"
                text: qsTr("Edit")
            }
        }

        RowLayout {
            id: scheduleViewer
            visible: !editable
            Layout.alignment: Qt.AlignCenter

            property int currentWeek: 1  // 当前周数

            ToolButton {
                id: previousButton
                icon.name: "ic_fluent_chevron_left_20_regular"
                flat: true
                enabled: scheduleViewer.currentWeek > 1
                onClicked: scheduleViewer.currentWeek--
            }

            Text {
                id: weekText
                text: qsTr("Week %1").arg(scheduleViewer.currentWeek)
            }

            ToolButton {
                id: nextButton
                icon.name: "ic_fluent_chevron_right_20_regular"
                flat: true
                onClicked: scheduleViewer.currentWeek++
            }
        }

        RowLayout {
            id: rowLayout
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScheduleTableView {
                id: scheduleTable
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentWeek: editable ? weekSelector.currentWeek : scheduleViewer.currentWeek || 1

                onCellClicked: (row, column, entry, delegate) => {
                    if (!editable) {
                        return
                    }
                    entryFlyout.entry = entry
                    entryFlyout.selectedCell = selectedCell
                    entryFlyout.weekSelector = weekSelector
                    entryFlyout.parent = delegate   // 定位到点击的 cell
                    entryFlyout.open()
                }
            }

            ScheduleFlyout {
                id: entryFlyout
            }

            ColumnLayout {
                visible: editable
                Layout.maximumWidth: Math.max(root.width * 0.32, 275)
                spacing: 12
                SettingExpander {
                    Layout.fillWidth: true
                    // Layout.fillHeight: true
                    expanded: true
                    title: qsTr("Week Cycle")
                    icon.name: "ic_fluent_calendar_week_numbers_20_regular"

                    WeekSelector {
                        Layout.margins: 18
                        id: weekSelector
                        onCurrentWeekChanged: {
                            scheduleTable.currentWeek = currentWeek
                        }
                    }
                }

                // 快速添加学科
                Frame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    padding: 16

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8
                        Text {
                            typography: Typography.BodyStrong
                            text: qsTr("Quick Add Subject")
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: subjectsFlow.height
                            clip: true

                            ScrollBar.vertical: ScrollBar {}

                            Flow {
                                id: subjectsFlow
                                width: parent.width
                                Repeater {
                                    model: AppCentral.scheduleRuntime.subjects
                                    Button {
                                        flat: true
                                        icon.name: modelData.icon
                                        text: modelData.name
                                        onClicked: {
                                            quickAddSubject(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}