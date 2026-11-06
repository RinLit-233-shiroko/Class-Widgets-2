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

    readonly property string displayText: subjectId
        ? (AppCentral.scheduleEditor.subjectNameById(subjectId) || placeholderText)
        : placeholderText
    readonly property real textAvailableWidth: Math.max(1,
            root.width - root.leftPadding - root.rightPadding
                - (root.icon.name ? root.icon.width + 8 : 0)
                - (root.suffixIconName !== "" ? 20 : 0)
                - 4
    )

    text: displayText
    icon.name: showSubjectIcon ? subjectIcon(subjectId) : ""
    onClicked: subjectsFlyout.open()

    contentItem: Item {
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: 8

            Item {
                width: root.icon.name ? root.icon.width : 0
                height: root.font.pixelSize * 1.5
                visible: root.icon.name !== ""

                IconWidget {
                    anchors.centerIn: parent
                    width: root.icon.width
                    height: root.icon.height
                    icon: root.icon.name
                    color: root.highlighted
                        ? (root.flat
                            ? Theme.currentTheme.colors.textAccentColor
                            : Theme.currentTheme.colors.textOnAccentColor)
                        : Theme.currentTheme.colors.textColor
                }
            }

            Text {
                width: root.textAvailableWidth
                height: root.font.pixelSize * 1.5
                text: root.displayText
                typography: Typography.Body
                color: root.highlighted
                    ? (root.flat
                        ? Theme.currentTheme.colors.textAccentColor
                        : Theme.currentTheme.colors.textOnAccentColor)
                    : Theme.currentTheme.colors.textColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Item {
                width: root.suffixIconName !== "" ? 12 : 0
                height: root.font.pixelSize * 1.5
                visible: root.suffixIconName !== ""

                IconWidget {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    icon: root.suffixIconName
                    color: Theme.currentTheme.colors.textSecondaryColor
                }
            }
        }
    }

    ToolTip {
        text: root.displayText
        visible: parent.hovered && text !== root.text
    }

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
