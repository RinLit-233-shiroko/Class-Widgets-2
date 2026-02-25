import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

import QtQuick.Effects  // shadow

Item {
    // SaveFlyout {}

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 8

        DayListView {
            id: dayList
        }

        ToolSeparator { Layout.fillHeight: true }

        EntryListView {
            id: entryList
            currentDayIndex: dayList.currentIndex

            property var currentEntry: (currentIndex >= 0 && currentDayIndex >= 0) ?
                AppCentral.scheduleEditor.days[currentDayIndex].entries[currentIndex] : null

            onCurrentEntryChanged: {
                refreshTimer.restart()
            }

            Timer {
                id: refreshTimer
                interval: 0

                onTriggered: {
                    detailView.refresh(entryList.currentEntry)
                }
            }
        }

        ToolSeparator { Layout.fillHeight: true }

        EntryDetailView {
            id: detailView
            Layout.preferredWidth: 220
        }
    }
}