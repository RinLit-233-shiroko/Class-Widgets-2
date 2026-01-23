import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


Window {
    id: panel
    title: Configs.data.app.version
    width: 375
    height: 550
    minimumWidth: 375
    // maximumWidth: width
    minimumHeight: 550
    // maximumHeight: height

    minimizeVisible: false
    maximizeVisible: false

    onActiveChanged: {
        if (!active && Qt.application.active !== true) {
            hide()  // 脱离焦点隐藏
        }
    }

    // background
    Rectangle {
        id: appLayer
        anchors.horizontalCenter: parent.horizontalCenter
        width: 375
        height: parent.height - bottomRow.height - 10
        color: Theme.currentTheme.colors.layerColor
        border.color: Theme.currentTheme.colors.cardBorderColor
        border.width: 1
        // radius: Theme.currentTheme.appearance.windowRadius
    }

    ColumnLayout {
        id: mianlayout
        anchors.fill: parent
        anchors.margins: 14
        anchors.bottomMargin: 4
        spacing: 10

        RowLayout {
            Layout.margins: 4
            spacing: 8
            Image {
                id: logo
                mipmap: true
                source: PathManager.assets("images/logo.png")
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
            }
            Text {
                typography: Typography.BodyLarge
                text: "Class Widgets"
            }
            Item {
                Layout.fillWidth: true
            }
            Hyperlink {
                icon.name: "ic_fluent_star_emphasis_20_regular"
                text: qsTr("What's New")
                onClicked: {
                    AppCentral.openWhatsNew()
                    panel.hide()
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            SettingCard {
                Layout.fillWidth: true
                icon.name: "ic_fluent_settings_20_regular"
                title: qsTr("Settings")
                description: qsTr("Adjust the settings of Class Widgets")
                Hyperlink {
                    text: qsTr("Open")
                    onClicked: {
                        panel.hide()
                        AppCentral.openSettings()
                    }
                }
            }

            SettingCard {
                Layout.fillWidth: true
                icon.name: "ic_fluent_document_bullet_list_multiple_20_regular"
                title: qsTr("Schedules")
                description: qsTr("Edit your schedule profile")
                Hyperlink {
                    text: qsTr("Open")
                    onClicked: {
                        panel.hide()
                        AppCentral.openEditor()
                    }
                }
            }

            SettingCard {
                Layout.fillWidth: true
                icon.name: "ic_fluent_apps_add_in_20_regular"
                title: qsTr("Extension Plaza (WEB)")
                description: qsTr("Discover and download plugins and themes")
                Hyperlink {
                    text: qsTr("Open")
                    // enabled: false
                    onClicked: {
                        // Qt.openUrlExternally("https://plaza.cw.rinlit.cn")
                        panel.hide()
                        AppCentral.openPlaza()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true

            Text {
                typography: Typography.BodyStrong
                text: qsTr("Shortcuts")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.maximumWidth: parent.width / 2
                    Layout.fillWidth: true
                    icon.name: "ic_fluent_calendar_arrow_counterclockwise_20_regular"
                    text: qsTr("Reschedule Day")
                    onClicked: rescheduleDayDialog.open()
                }
                Button {
                    enabled: false
                    Layout.maximumWidth: parent.width / 2
                    Layout.fillWidth: true
                    icon.name: "ic_fluent_arrow_swap_20_regular"
                    text: qsTr("Class Swap")
                }
            }
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
                    onClicked: {
                        AppCentral.scheduleManager.load(modelData.name)
                    }
                    onSelectedChanged: {
                        if (selected) {
                            // 让选中的 item 滚动到视图中心
                            scheduleList.positionViewAtIndex(index, ListView.Center)
                        }
                    }
                }

                ScrollBar.horizontal: ScrollBar { }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    RowLayout {
        id: bottomRow
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 4
        Layout.fillWidth: true
        spacing: 0

        ToolButton {
            icon.name: "ic_fluent_developer_board_search_20_regular"
            flat: true
            onClicked: {
                panel.hide()
                AppCentral.openDebugger()
            }
            ToolTip {
                text: qsTr("Debugger")
                visible: parent.hovered
            }

            Component.onCompleted: {
                enabled = Configs.data.app.debug_mode
            }
        }

        ToolButton {
            icon.name: "ic_fluent_arrow_counterclockwise_20_regular"
            flat: true
            ToolTip {
                text: qsTr("Restart")
                visible: parent.hovered
            }
            onClicked: AppCentral.restart()
        }

        ToolButton {
            icon.name: "ic_fluent_arrow_exit_20_regular"
            flat: true
            ToolTip {
                text: qsTr("Exit")
                visible: parent.hovered
            }
            onClicked: AppCentral.quit()
        }
    }

    // dialogs
    RescheduleDayDialog {
        id: rescheduleDayDialog
        title: qsTr("Reschedule Day")
        width: panel.width * 0.8

        ButtonGroup {
            id: buttonGroup
            exclusive: true
        }
    }


    // connet to AppCentral
    Connections {
        target: AppCentral
        function onTogglePanel(pos) {
            let offsetY = 30
            let x = pos.x - trayPanel.width / 2
            let y = pos.y + offsetY

            if (y + trayPanel.height > trayPanel.Screen.height) {
                y = pos.y - trayPanel.height - offsetY
            }

            if (y < 0) {
                y = 0
            }
            trayPanel.x = x
            trayPanel.y = y

            trayPanel.visible = true
            trayPanel.raise()
            trayPanel.requestActivate()
        }
    }
}