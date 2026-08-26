import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


FluentWindow {
    id: settingsWindow
    icon: PathManager.assets("images/icons/cw2_editor.png")
    title: qsTr("Schedule Editor") + " - " + AppCentral.scheduleEditor.filename + (AppCentral.scheduleEditor.dirty ? " *" : "")
    width: Math.max(Screen.width * 0.6, 800)
    height: Math.max(Screen.height * 0.7, 700)
    minimumWidth: 600
    // visible: true
    // navigationView.navMinimumExpandWidth: Screen.width
    // navigationView.navigationBar.collapsed: true

    property bool notHint: false
    property bool hintVisible: false

    onClosing: function(event) {
        event.accepted = false
        if (AppCentral.scheduleEditor.dirty) {
            saveTipDialog.open()
        } else {
            WindowManager.closeEditor()
        }
    }

    Dialog {
        id: saveTipDialog
        title: qsTr("Save changes to the timetable")
        modal: true
        Text {
            Layout.fillWidth: true
            text: qsTr("Do you want to save the changes to \"%1\"?").arg(AppCentral.scheduleEditor.filename)
        }
        standardButtons: Dialog.Save | Dialog.Discard | Dialog.Cancel

        onAccepted: {
            let result = AppCentral.scheduleManager.save()
            if (result) {
                AppCentral.scheduleEditor.markSaved()
                WindowManager.closeEditor()
            } else {
                floatLayer.createInfoBar({
                    title: qsTr("Save Failed"),
                    severity: Severity.Error,
                    text: qsTr("Failed to save schedule, see log for details")
                })
            }
        }
        onDiscarded: {
            AppCentral.scheduleManager.reload()
            WindowManager.closeEditor()
        }
        onRejected: {
            close()
        }
    }

    titleBarArea: RowLayout {
        anchors.fill: parent
        spacing: 24

        Shortcut {
            sequence: "Ctrl+S"
            onActivated: {
                let result = AppCentral.scheduleManager.save()
                if (result) {
                    AppCentral.scheduleEditor.markSaved()
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
            enabled: !AppCentral.scheduleManager.isReadonly()

            ToolTip {
                text: qsTr("Save Changes")
                visible: parent.hovered
            }

            onClicked: {
                let result = AppCentral.scheduleManager.save()
                if (result) {
                    AppCentral.scheduleEditor.markSaved()
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