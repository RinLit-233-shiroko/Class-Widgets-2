import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Clip {
    id: clip
    width: 278
    height: 72
    radius: 6

    property alias filename: title.text
    property alias description: description.text
    property alias selected: indicator.visible
    property alias iconVisible: icon.visible
    property alias actionEnabled: editButton.visible

    Rectangle {
        id: indicator
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        color: Colors.proxy.primaryColor
        property int currentItemHeight: parent.height * 0.75

        implicitWidth: 3
        implicitHeight: currentItemHeight - 23
        radius: 10
        visible: false

        onVisibleChanged: {
            if (visible) {
                enterAnimation.start()
            }
        }

        // 动画 / Animation //
        ParallelAnimation {
            id: enterAnimation
            PropertyAnimation {
                target: indicator
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Utils.animationSpeed
                easing.type: Easing.OutQuad
            }
            ScriptAction {
                script: enterAnimationVertical.start()
            }
        }

        ParallelAnimation {
            id: enterAnimationVertical
            PropertyAnimation {
                target: indicator
                property: "height"
                from: 0
                to: indicator.implicitHeight
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
            }

            PropertyAnimation {
                target: indicator
                property: "y"
                from: clip.height / 2
                to: (clip.height - indicator.implicitHeight) / 2
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 14
        spacing: 16

        Icon {
            id: icon
            Layout.alignment: Qt.AlignVCenter
            name: "ic_fluent_calendar_clock_20_regular"
            // layout内部宽高
            size: 24
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
        }
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4
            Text {
                id: title
                width: parent.width
                typography: Typography.BodyStrong
                text: "课程表（1）"
            }
            Text {
                id: description
                width: parent.width
                typography: Typography.Caption
                color: Theme.currentTheme.colors.textSecondaryColor
                text: qsTr("Local")  // 伏笔（）
            }
        }

        ToolButton {
            id: editButton
            flat: true
            icon.name: "ic_fluent_more_vertical_20_regular"
            onClicked: actionMenu.open()

            Menu {
                id: actionMenu
                MenuItem {
                    icon.name: "ic_fluent_copy_add_20_regular"
                    text: qsTr("Duplicate")
                    onTriggered: {
                        AppCentral.scheduleManager.duplicate(filename, filename + " (Copy)")
                    }
                }
                MenuItem {
                    icon.name: "ic_fluent_rename_20_regular"
                    text: qsTr("Rename")
                    onTriggered: {
                        renameDialog.open()
                    }
                }
                MenuItem {
                    icon.name: "ic_fluent_delete_20_regular"
                    text: qsTr("Delete")
                    enabled: !selected
                    onTriggered: {
                        confirmDeleteDialog.open()
                    }
                }
                MenuSeparator {}
                Menu {
                    icon.name: "ic_fluent_share_20_regular"
                    title: qsTr("Export")
                    MenuItem {
                        text: qsTr("Export to JSON")
                        onClicked: {
                            if (AppCentral.scheduleManager.export(filename)) {
                                floatLayer.createInfoBar(
                                    {
                                        severity: Severity.Success,
                                        title: qsTr("Export Success"),
                                        text: qsTr("The schedule has been exported")
                                    }
                                )
                            } else {
                                floatLayer.createInfoBar(
                                    {
                                        severity: Severity.Error,
                                        title: qsTr("Export Failed"),
                                        text: qsTr(
                                            "Failed to export the schedule. " +
                                            "Please change the output directory "+
                                            "or send the log file to the developer or community to help us sort it out."
                                        )
                                    }
                                )
                            }
                        }
                    }
                    MenuItem {
                        text: qsTr("Export to CSES")
                        onClicked: {
                            if (AppCentral.scheduleManager.scheduleIO.exportToCSES(filename)) {
                                floatLayer.createInfoBar(
                                    {
                                        severity: Severity.Success,
                                        title: qsTr("Export Success"),
                                        text: qsTr("The schedule has been exported as CSES format")
                                    }
                                )
                            } else {
                                floatLayer.createInfoBar(
                                    {
                                        severity: Severity.Error,
                                        title: qsTr("Export Failed"),
                                        text: qsTr(
                                            "Failed to export the schedule as CSES format. " +
                                            "Please change the output directory "+
                                            "or send the log file to the developer or community to help us sort it out."
                                        )
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // dialogs

    Dialog {
        id: renameDialog
        modal: true
        title: qsTr("Rename Schedule")
        Text {
            Layout.fillWidth: true
            text: qsTr("Rename this schedule")
        }

        ColumnLayout {
            Layout.fillWidth: true
            TextField {
                id: scheduleNameField
                Layout.fillWidth: true
                placeholderText: qsTr("New name ╰(*°▽°*)╯")
                onTextChanged: {
                    const okBtn = renameDialog.footer.standardButton(DialogButtonBox.Ok)
                    okBtn.enabled = scheduleNameField.text.length > 0 &&
                        !AppCentral.scheduleManager.checkNameExists(scheduleNameField.text)
                    validator.visible = true
                }
            }
            Text {
                id: validator
                visible: false
                Layout.fillWidth: true
                typography: Typography.Caption
                color: {
                    if (!scheduleNameField.text) {
                        return Colors.proxy.systemCriticalColor
                    }
                    if (AppCentral.scheduleManager.checkNameExists(scheduleNameField.text)) {
                        return Colors.proxy.systemCriticalColor
                    }
                    return Colors.proxy.systemSuccessColor
                }
                text: {
                    if (!scheduleNameField.text) {
                        return qsTr("Cannot be empty (⊙x⊙;)")
                    }
                    if (AppCentral.scheduleManager.checkNameExists(scheduleNameField.text)) {
                        return qsTr("Cannot duplicate existing name (⊙x⊙;)")
                    }
                    return qsTr("Great! That's it. ヾ(≧▽≦*)o")
                }
            }
        }

        footer: DialogButtonBox {
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel

            onAccepted: {
                AppCentral.scheduleManager.rename(filename, scheduleNameField.text)
                createScheduleDialog.close()
            }
            onRejected: renameDialog.close()

            Component.onCompleted: {
                const okBtn = standardButton(DialogButtonBox.Ok)
                okBtn.enabled = false // 初始禁用
            }
        }
    }

    Dialog {
        // 确认删除
        id: confirmDeleteDialog
        modal: true
        title: qsTr("Are you sure to delete this schedule?")
        Text {
            Layout.fillWidth: true
            text: qsTr("This action cannot be undone.")
        }
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            if (filename === AppCentral.scheduleManager.currentScheduleName) {
                floatLayer.createInfoBar(
                    {
                        severity: Severity.Error,
                        title: qsTr("Failed to delete"),
                        text: qsTr("Cannot delete the current schedule. Please switch to another schedule first.")
                    }
                )
                return
            }
            if (!AppCentral.scheduleManager.delete(filename)) {
                floatLayer.createInfoBar(
                    {
                        severity: Severity.Error,
                        title: qsTr("Failed to delete"),
                        text: qsTr("Please send the log file to the developer or community to help us sort it out.")
                    }
                )
            }
        }
    }
}