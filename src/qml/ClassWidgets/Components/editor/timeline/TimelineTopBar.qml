import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

RowLayout {
    id: root

    property bool compactTopBar: false
    property int viewMode: 0
    property int pendingViewMode: -1

    signal viewModeRequested(int index)
    signal settingsRequested()
    signal newTimelineRequested(int ruleMode)

    implicitHeight: 32
    spacing: 8

    Segmented {
        Layout.preferredWidth: root.compactTopBar ? 280 : 360
        currentIndex: root.pendingViewMode >= 0
            ? root.pendingViewMode : root.viewMode
        onCurrentIndexChanged: {
            if (currentIndex === root.viewMode
                    && root.pendingViewMode < 0)
                return
            root.viewModeRequested(currentIndex)
        }

        SegmentedItem { text: qsTr("All") }
        SegmentedItem { text: qsTr("By Week") }
        SegmentedItem { text: qsTr("By Date") }
    }

    Item { Layout.fillWidth: true }

    Button {
        id: newTimelineButton
        Layout.maximumWidth: root.compactTopBar ? 40 : 999
        flat: false
        icon.name: "ic_fluent_calendar_arrow_repeat_all_20_regular"
        text: root.compactTopBar
            ? ""
            : qsTr("Set Start Date & Maximum Rotation Weeks")
        onClicked: root.settingsRequested()

        ToolTip {
            text: qsTr("Set Start Date & Maximum Rotation Weeks")
            visible: root.compactTopBar && parent.hovered
        }
    }

    Button {
        Layout.maximumWidth: root.compactTopBar ? 40 : 999
        highlighted: true
        icon.name: "ic_fluent_add_20_regular"
        text: root.compactTopBar ? "" : qsTr("New Timeline")
        onClicked: newTimelineMenu.open()

        ToolTip {
            text: qsTr("New Timeline")
            visible: root.compactTopBar && parent.hovered
        }

        Menu {
            id: newTimelineMenu
            // Menu coordinates are relative to the top-bar item, so place it
            // directly below the New Timeline button instead of using the
            // default popup position.
            x: newTimelineButton.x + newTimelineButton.width - width
            y: newTimelineButton.y + newTimelineButton.height + 4
            MenuItem {
                text: qsTr("By Week")
                icon.name: "ic_fluent_calendar_week_numbers_20_regular"
                onTriggered: root.newTimelineRequested(0)
            }
            MenuItem {
                text: qsTr("By Date")
                icon.name: "ic_fluent_calendar_date_20_regular"
                onTriggered: root.newTimelineRequested(1)
            }
        }
    }
}
