import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

Clip {
    id: subjectClip
    width: subjectsGrid.cellWidth - 8
    height: subjectsGrid.cellHeight - 6
    onClicked: openEditDialog()

    property string subjectId: modelData.id
    property string subjectIcon: modelData.icon || ""
    property string subjectSimplifiedNameText: modelData.simplifiedName || ""
    property string subjectNameText: modelData.name
    property string subjectTeacherText: modelData.teacher || ""
    property string subjectLocationText: modelData.location || ""
    property string subjectColorText: modelData.color || ""
    property bool subjectIsLocal: modelData.isLocalClassroom || true

    function openEditDialog() {
        // 初始化编辑框
        subjectID.text = subjectId
        subjectSimplifiedName.text = subjectSimplifiedNameText || ""
        subjectName.text = subjectNameText || ""
        subjectTeacher.text = subjectTeacherText || ""
        subjectLocation.text = subjectLocationText || ""
        subjectColor.color = subjectColorText || "#13c4d6"
        subjectIsLocalClassroom.checked = subjectIsLocal
        iconBtn.icon.name = subjectIcon || "ic_fluent_square_hint_20_regular"
        editDialog.open()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        anchors.bottomMargin: 18

        ColumnLayout {
            id: subjectNameLayout
            // Layout.alignment: Qt.AlignTop | Qt.AlignLeft
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                spacing: 6
                Rectangle {
                    // circle
                    width: 26
                    height: 26
                    radius: width / 2
                    color: Qt.alpha(subjectColorText ||"#197", 0.2)  // 学科自定色

                    Icon {  //subject icon
                        anchors.centerIn: parent
                        size: 18; name: subjectIcon || "ic_fluent_hexagon_three_20_regular";
                    }
                }
                // 非本班课程
                Rectangle {
                    // circle
                    visible: !subjectIsLocal
                    width: 26
                    height: 26
                    radius: width / 2
                    color: Colors.proxy.systemCautionBackgroundColor

                    Icon {  //subject icon
                        anchors.centerIn: parent
                        color: Colors.proxy.systemCautionColor
                        size: 18; name: "ic_fluent_sign_out_20_filled";
                    }
                }
                Item { Layout.fillWidth: true }

                ToolButton {
                    Layout.preferredWidth: 32; Layout.preferredHeight: 32;
                    flat: true
                    icon.name: "ic_fluent_delete_20_regular"
                    onClicked: AppCentral.scheduleEditor.removeSubject(subjectId)
                }
            }

            Item { Layout.fillHeight: true }

            // 详细信息
            ColumnLayout {
                Layout.fillWidth: true

                Repeater {
                    model: [subjectTeacherText, subjectLocationText]

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: modelData
                        Text {
                            opacity: 0.5
                            text: index === 0 ? qsTr("Teacher: ") : qsTr("Location: ")
                        }
                        Text {
                            id: subjectInfo
                            Layout.fillWidth: true
                            opacity: 0.75
                            horizontalAlignment: Text.AlignRight
                            text: modelData
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                typography: Typography.BodyLarge
                text: subjectNameText
            }
        }
    }

    // 编辑

    Dialog {
        id: editDialog
        title: qsTr("Edit Subject")
        width: 420
        modal: true

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("ID") }
                    TextField { id: subjectID; readOnly: true; Layout.fillWidth: true }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("Simplified Name") }
                    TextField { id: subjectSimplifiedName; Layout.fillWidth: true }
                }
            }

            RowLayout {
                Text { text: qsTr("Subject Name"); Layout.fillWidth: true }
                TextField { id: subjectName; placeholderText: qsTr("e.g. Science") ; Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Teacher"); Layout.fillWidth: true }
                TextField { id: subjectTeacher; Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Location"); Layout.fillWidth: true }
                TextField { id: subjectLocation; placeholderText: qsTr("e.g. Room 7813") ; Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Color"); Layout.fillWidth: true }
                DropDownColorPicker {
                    id: subjectColor
                    position: Position.Left
                    textVisible: true
                    hexText: true
                }
                // TextField { id: subjectColor; placeholderText: qsTr("e.g. #FF0000, blue, #197, etc.") ; Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Held in homeroom"); Layout.fillWidth: true }
                Button {
                    id: explainButton
                    icon.name: "ic_fluent_question_circle_20_regular"; implicitWidth: 24; implicitHeight: 24;
                    onClicked: {
                        explainFlyout.open()
                    }
                }
                Switch { id: subjectIsLocalClassroom; }
            }

            RowLayout {
                Text { text: qsTr("Icon"); Layout.fillWidth: true }
                DropDownButton {
                    id: iconBtn
                    icon.name: "ic_fluent_square_hint_20_regular"
                    onClicked: iconPicker.open()

                    IconPicker {
                        id: iconPicker
                        parent: iconBtn
                        position: Position.Top

                        onIconPicked: function(name) {
                            iconBtn.icon.name = name
                        }
                    }
                }
            }
        }

        Flyout {
            id: explainFlyout
            parent: explainButton
            width: 300
            text: qsTr(
                "Enable if the subject is taught in your homeroom classroom.  \n" +
                "If it takes place in another location, such as a sport field, lab, or another classroom, leave it off."
            )
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: {
            AppCentral.scheduleEditor.updateSubject(
                subjectId,
                subjectName.text,
                subjectSimplifiedName.text,
                subjectTeacher.text,
                iconBtn.icon.name,
                subjectColor.color.toString(),
                subjectLocation.text,
                subjectIsLocalClassroom.checked
            )
        }
    }
}