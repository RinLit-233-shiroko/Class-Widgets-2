import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

DropDownButton {
    id: root

    property string subjectId: ""
    property var subjects: AppCentral.scheduleRuntime.subjects || []
    property bool showSubjectIcon: false
    property string placeholderText: qsTr("Select Subject")

    signal subjectSelected(string subjectId)

    text: subjectId
        ? (AppCentral.scheduleEditor.subjectNameById(subjectId) || placeholderText)
        : placeholderText
    icon.name: showSubjectIcon ? subjectIcon(subjectId) : ""
    onClicked: subjectsFlyout.open()

    function subjectIcon(id) {
        for (let i = 0; i < subjects.length; ++i) {
            if (subjects[i].id === id)
                return subjects[i].icon || ""
        }
        return ""
    }

    Flyout {
        id: subjectsFlyout
        position: Position.Left
        implicitWidth: Overlay.overlay
            ? Math.max(180, Math.min(300, Overlay.overlay.width - 32))
            : 300

        Flow {
            Layout.fillWidth: true
            spacing: 4

            ButtonGroup {
                id: subjectsGroup
                exclusive: true
            }

            Repeater {
                model: root.subjects

                ToggleButton {
                    property string sid: modelData.id
                    icon.name: modelData.icon || ""
                    text: modelData.name
                    flat: true
                    checked: sid === root.subjectId
                    ButtonGroup.group: subjectsGroup
                }
            }
        }

        buttonBox: Button {
            highlighted: true
            text: qsTr("Set Subject")
            onClicked: {
                if (subjectsGroup.checkedButton) {
                    root.subjectSelected(subjectsGroup.checkedButton.sid)
                    subjectsFlyout.close()
                }
            }
        }
    }
}