import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


Window {
    id: panel
    title: qsTr("Quick Access Panel")
    // title: Configs.data.app.version
    width: 375
    height: 475
    minimumWidth: 375
    minimumHeight: 475
    minimizeVisible: false
    maximizeVisible: false

    onActiveChanged: {
        if (!active && Qt.application.active !== true) {
            hide()
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        // width: 375
        width: parent.width + 8
        height: parent.height - bottomRow.height - 10
        color: Theme.currentTheme.colors.layerColor
        border.color: Theme.currentTheme.colors.cardBorderColor
        border.width: 1
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: bottomRow.top
        }
        // anchors.fill: parent
        anchors.margins: 14
        anchors.bottomMargin: 22
        spacing: 8

        RowLayout {
            Layout.margins: 4
            spacing: 8

            Image {
                mipmap: true
                source: PathManager.assets("images/logo.png")
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
            }

            Text {
                typography: Typography.BodyLarge
                text: "Class Widgets"
            }

            Item { Layout.fillWidth: true }

            Hyperlink {
                icon.name: "ic_fluent_star_emphasis_20_regular"
                text: qsTr("What's New")
                onClicked: {
                    WindowManager.openWhatsNew()
                    panel.hide()
                }
            }
        }

        TrayShortcuts {
            Layout.fillWidth: true
            Layout.fillHeight: true
            panelWidth: panel.width
            onShortcutTriggered: panel.hide()
        }

        ColumnLayout {
            Layout.fillWidth: true

            Text {
                typography: Typography.BodyStrong
                text: qsTr("Switch your schedule")
            }

            ListView {
                id: scheduleList
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                spacing: 8
                orientation: ListView.Horizontal
                model: AppCentral.scheduleManager.schedules()

                delegate: ScheduleClip {
                    width: 200
                    filename: modelData.name
                    selected: AppCentral.scheduleManager.currentScheduleName === modelData.name
                    iconVisible: false
                    actionEnabled: false
                    onClicked: AppCentral.scheduleManager.load(modelData.name)
                    onSelectedChanged: {
                        if (selected) {
                            scheduleList.positionViewAtIndex(index, ListView.Center)
                        }
                    }
                }

                ScrollBar.horizontal: ScrollBar { }
            }
        }

        // Item { Layout.fillHeight: true }
    }

    RowLayout {
        id: bottomRow
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        spacing: 0

        ToolButton {
            flat: true
            icon.name: "ic_fluent_developer_board_search_20_regular"
            visible: Configs.data.app.debug_mode
            enabled: Configs.data.app.debug_mode
            onClicked: {
                panel.hide()
                AppCentral.openDebugger()
            }
            ToolTip { text: qsTr("Debugger"); visible: parent.hovered }
        }

        ToolButton {
            flat: true
            icon.name: "ic_fluent_arrow_counterclockwise_20_regular"
            onClicked: AppCentral.restart()
            ToolTip { text: qsTr("Restart"); visible: parent.hovered }
        }

        ToolButton {
            flat: true
            icon.name: "ic_fluent_arrow_exit_20_regular"
            onClicked: AppCentral.quit()
            ToolTip { text: qsTr("Exit"); visible: parent.hovered }
        }
    }

    RescheduleDayDialog {
        id: rescheduleDayDialog
        title: qsTr("Reschedule Day")
        width: panel.width * 0.8

        ButtonGroup {
            id: buttonGroup
            exclusive: true
        }
    }

    Connections {
        target: AppCentral

        function onTrayShortcutRequested(shortcutId) {
            if (shortcutId === "com.classwidgets.reschedule-day") {
                rescheduleDayDialog.open()
            }
        }

        function onTogglePanel(pos) {
            const offsetY = 30
            let x = pos.x - panel.width / 2
            let y = pos.y + offsetY

            if (y + panel.height > panel.Screen.height) {
                y = pos.y - panel.height - offsetY
            }
            if (y < 0) {
                y = 0
            }

            panel.x = x
            panel.y = y
            panel.visible = true
            panel.raise()
            panel.requestActivate()
        }
    }
}
