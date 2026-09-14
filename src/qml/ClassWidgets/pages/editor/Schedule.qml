import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

import QtQuick.Effects  // shadow

Item {
    id: root

    function quickAddSubject(subjectid) {
        let row = scheduleTable.selectedCell.row
        let column = scheduleTable.selectedCell.column

        if (row < 0 || column < 0) {
            row = 0
            column = 0
        }

        let day = scheduleTable.getDayByColumn(column)
        let entry = scheduleTable.getEntryByDayAndRow(day, row, column)
        if (!entry) return;

        // currentWeek is always an absolute week here; it is converted to a
        // week within the cycle when the override is written.
        let weeks = scheduleTable.cycleWeekFor(root.currentWeek);
        let dayOfWeek = [scheduleTable.dayOfWeekForColumn(column)]

        const existingId = AppCentral.scheduleEditor.findOverride(entry.id, dayOfWeek, weeks)
        if (existingId) {
            AppCentral.scheduleEditor.updateOverride(existingId, subjectid, null)
        } else {
            AppCentral.scheduleEditor.addOverride(entry.id, dayOfWeek, weeks, subjectid, null)
        }

        scheduleTable.currentEntry = scheduleTable.getEntryByDayAndRow(day, row, column)
        advanceQuickAddSelection()
    }

    function advanceQuickAddSelection() {
        let row = scheduleTable.selectedCell.row
        let column = scheduleTable.selectedCell.column

        if (row < 0 || column < 0) {
            row = 0
            column = 0
        }

        let nextRow = row + 1
        let nextColumn = column

        if (nextRow === scheduleTable.maxRows) {
            nextRow = 0
            nextColumn = column + 1
            if (nextColumn >= 7) nextColumn = 0
        }

        scheduleTable.selectedCell = { row: nextRow, column: nextColumn }
        scheduleTable.currentEntry = scheduleTable.getEntryByDayAndRow(
            scheduleTable.getDayByColumn(nextColumn), nextRow, nextColumn
        )
    }

    // Jump back to the backend's current week and focus today's column.
    function goToToday() {
        root.currentWeek = Math.max(1, AppCentral.scheduleRuntime.currentWeek || 1)
        scheduleTable.selectToday()
    }

    property bool editable: !AppCentral.scheduleManager.isReadonly()

    // Absolute week currently shown; defaults to the current week, which is
    // derived from the term start date.
    property int currentWeek: Math.max(1, AppCentral.scheduleRuntime.currentWeek || 1)

    // Week context read by ScheduleFlyout.
    QtObject {
        id: weekContext
        property int currentWeek: root.currentWeek
        property int maxWeekCycle: AppCentral.scheduleEditor.meta.maxWeekCycle
    }

    // Clicking empty page background clears the selection; clicks inside the
    // table are handled by ScheduleTableView.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: scheduleTable.clearSelection()
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 24
        spacing: 10

        // Top row: week title + month + previous / today / next week.
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 0
                Layout.alignment: Qt.AlignBottom

                Text {
                    text: qsTr("Week %1").arg(root.currentWeek)
                    typography: Typography.Title
                }
                Text {
                    // Year and month only. The format string is translated, so
                    // each language can reorder the fields and supply its own
                    // year/month markers.
                    text: Qt.formatDate(scheduleTable.weekStart, qsTr("MMMM yyyy"))
                    typography: Typography.Body
                    color: Colors.proxy.textSecondaryColor
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignBottom
                spacing: 4

                ToolButton {
                    icon.name: "ic_fluent_chevron_left_20_regular"
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: root.currentWeek--
                }
                Button {
                    text: qsTr("Today")
                    implicitHeight: 32
                    onClicked: root.goToToday()
                }
                ToolButton {
                    icon.name: "ic_fluent_chevron_right_20_regular"
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: root.currentWeek++
                }
            }
        }

        ScheduleTableView {
            id: scheduleTable
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentWeek: root.currentWeek
            zoomFactor: zoomSlider.value

            onCellClicked: (row, column, entry, delegate) => {
                if (!editable) {
                    return
                }
                entryFlyout.entry = entry
                entryFlyout.selectedCell = { row: row, column: column }
                entryFlyout.weekSelector = weekContext
                entryFlyout.parent = delegate
                entryFlyout.open()
            }

            onSelectionCleared: entryFlyout.close()
        }


        RowLayout {
            id: bottomBar
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            spacing: 8

            Button {
                id: quickFillButton
                implicitHeight: 32
                icon.name: "ic_fluent_flash_20_regular"
                text: qsTr("Quick Fill")
                onClicked: addSubjectPanel.toggle()
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Math.round(zoomSlider.value * 100) + "%"
                typography: Typography.Body
            }

            Slider {
                id: zoomSlider
                Layout.preferredWidth: 120
                Layout.alignment: Qt.AlignVCenter
                from: 0.75
                to: 2.0
                stepSize: 0.25
                value: 1.0
                // The percentage is already shown on the left, so disable the
                // hover tooltip to avoid duplicating it.
                toolTip.visible: false
            }
        }

        ScheduleFlyout {
            id: entryFlyout
            sourceItem: scheduleTable
        }
    }


    // Not affected by a Popup's click-outside-to-close or automatic
    // positioning, so the header stays draggable.
    AddSubjectExpander {
        id: addSubjectPanel
        bottomAnchorY: mainLayout.y + bottomBar.y
        bottomGap: 10
        sourceItem: mainLayout
        onSubjectClicked: (subjectId) => quickAddSubject(subjectId)
        onNextRequested: advanceQuickAddSelection()
    }
}
