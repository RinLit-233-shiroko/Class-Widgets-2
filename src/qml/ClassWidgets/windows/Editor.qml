import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


FluentWindow {
    id: settingsWindow
    icon: PathManager.assets("images/icons/cw2_editor.png")
    title: qsTr("Schedule Editor")
    width: Screen.width * 0.6
    height: Screen.height * 0.6
    minimumWidth: 600
    // visible: true
    navigationView.navMinimumExpandWidth: Screen.width
    navigationView.navigationBar.collapsed: true

    property bool notHint: false
    property bool hintVisible: false

    onClosing: function(event) {
        event.accepted = false
        settingsWindow.visible = false
    }

    titleBarArea: RowLayout {
        anchors.fill: parent
        spacing: 24

        Shortcut {
            sequence: "Ctrl+S"
            onActivated: {
                let result = AppCentral.scheduleManager.save()
                if (result) {
                    floatLayer.createInfoBar({
                        title: qsTr("Saved"),
                        severity: Severity.Success,
                        text: qsTr("Schedule saved successfully")
                    })
                } else {
                    floatLayer.createInfoBar({
                        title: qsTr("Save Failed"),
                        severity: Severity.Error,
                        text: qsTr("Failed to save schedule, see log for details")
                    })
                }
            }
        }

        ToolButton {
            flat: true
            Layout.alignment: Qt.AlignRight
            icon.name: "ic_fluent_save_20_regular"
            size: 18

            ToolTip {
                text: qsTr("Save Changes")
                visible: parent.hovered
            }

            onClicked: {
                let result = AppCentral.scheduleManager.save()
                if (result) {
                    floatLayer.createInfoBar({
                        title: qsTr("Saved"),
                        severity: Severity.Success,
                        text: qsTr("Schedule saved successfully")
                    })
                } else {
                    floatLayer.createInfoBar({
                        title: qsTr("Save Failed"),
                        severity: Severity.Error,
                        text: qsTr("Failed to save schedule, see log for details")
                    })
                }
            }
        }
    }

    navigationItems: [
        // {
        //     title: qsTr("Dashboard"),
        //     page: PathManager.qml("pages/Home.qml"),
        //     icon: "ic_fluent_board_20_regular",
        // },
        {
            title: qsTr("Home"),
            icon: "ic_fluent_home_20_regular",
            page: PathManager.qml("pages/editor/Home.qml"),
        },
        {
            title: qsTr("Timeline"),
            icon: "ic_fluent_timeline_20_regular",
            page: PathManager.qml("pages/editor/Timeline.qml"),
        },
        {
            title: qsTr("Schedule"),
            icon: "ic_fluent_calendar_20_regular",
            page: PathManager.qml("pages/editor/Schedule.qml"),
        }
        ,
        {
            title: qsTr("Subjects"),
            icon: "ic_fluent_book_20_regular",
            page: PathManager.qml("pages/editor/Subjects.qml"),
        }
    ]

    Component {
        id: saveHint
        InfoBar {
            timeout: -1
            position: Position.BottomRight
            severity: Severity.Warning
            closable: false
            title: qsTr("Unsaved Changes")
            text: qsTr(
                "Don\'t forget to save your changes before closing the editor or switching schedule. " +
                "You can click the save button in the title bar."
            )
            customContent: [
                Button {
                    text: qsTr("OK")
                    onClicked: {
                        notHint = true
                        close()
                    }
                }
            ]
        }
    }

    Connections {
        target: AppCentral.scheduleEditor
        onUpdated: {
            if (!notHint && !hintVisible && settingsWindow.visible) {
                floatLayer.createCustom(saveHint)
                hintVisible = true
            }
        }
    }

    // 测试水印
    Watermark {
        anchors.centerIn: parent
    }
}