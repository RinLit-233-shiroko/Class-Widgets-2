import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


Item {
    // SaveFlyout {}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 8

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignRight

            Button {
                icon.name: "ic_fluent_arrow_reset_20_regular"
                text: qsTr("Restore Defaults")
                onClicked: {
                    restoreConfirmDialog.open()
                }

                Dialog {
                    id: restoreConfirmDialog
                    title: qsTr("Restore Defaults")
                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Are you sure you want to restore the default subjects?")
                    }
                    standardButtons: Dialog.Yes | Dialog.No
                    onAccepted: {
                        AppCentral.scheduleEditor.restoreDefaultSubjects()
                        restoreConfirmDialog.close()
                    }
                }
            }

            ToolSeparator {}

            Button {
                highlighted: true
                icon.name: "ic_fluent_add_20_regular"
                text: qsTr("Add Subject")
                onClicked: {
                    AppCentral.scheduleEditor.addSubject(
                        qsTr("Subject"), "", "", "#13b4d6", "", true
                    )
                }
            }
        }

        GridView {
            id: subjectsGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            property int spacing: 8

            cellWidth: Math.max(200, width / Math.floor(width / 200))
            cellHeight: 175
            flow: GridView.FlowLeftToRight

            model: AppCentral.scheduleEditor.subjects

            delegate: SubjectClip {
                id: subjectClip
            }

            ScrollBar.vertical: ScrollBar {}
        }
    }
}