import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


ColumnLayout {
    id: root
    spacing: 12

    property alias customSubjectsModel: customModel
    property var defaultSubjects: AppCentral.scheduleEditor.defaultSubjects || []

    function selectedSubjects() {
        const result = []
        for (let i = 0; i < defaultSubjectsModel.count; i++) {
            const item = defaultSubjectsModel.get(i)
            if (item.selected) {
                result.push({
                    id: item.subjectId,
                    name: item.name,
                    simplifiedName: item.simplifiedName,
                    teacher: item.teacher,
                    icon: item.iconName,
                    color: item.subjectColor,
                    location: item.location,
                    isLocalClassroom: item.isLocalClassroom
                })
            }
        }
        for (let j = 0; j < customModel.count; j++) {
            const custom = customModel.get(j)
            result.push({
                id: custom.subjectId,
                name: custom.name,
                simplifiedName: custom.simplifiedName,
                teacher: custom.teacher,
                icon: custom.iconName,
                color: custom.subjectColor,
                location: custom.location,
                isLocalClassroom: custom.isLocalClassroom
            })
        }
        return result
    }

    function applySubjects() {
        return AppCentral.scheduleEditor.overwriteSubjects(selectedSubjects())
    }

    function addCustomSubject() {
        const name = customNameField.text.trim()
        if (!name) return
        const subjectId = "custom_" + Date.now().toString() + "_" + customModel.count
        customModel.append({
            subjectId: subjectId,
            name: name,
            simplifiedName: customShortField.text.trim(),
            teacher: "",
            iconName: "ic_fluent_book_20_regular",
            subjectColor: customColorField.text.trim() || "#607D8B",
            location: "",
            isLocalClassroom: customLocalSwitch.checked
        })
        customNameField.text = ""
        customShortField.text = ""
        customColorField.text = "#607D8B"
        customLocalSwitch.checked = true
    }

    ListModel { id: defaultSubjectsModel }
    ListModel { id: customModel }

    Component.onCompleted: {
        defaultSubjectsModel.clear()
        for (let i = 0; i < root.defaultSubjects.length; i++) {
            const subject = root.defaultSubjects[i]
            defaultSubjectsModel.append({
                selected: true,
                subjectId: subject.id || "",
                name: subject.name || "",
                simplifiedName: subject.simplifiedName || "",
                teacher: subject.teacher || "",
                iconName: subject.icon || "",
                subjectColor: subject.color || "#607D8B",
                location: subject.location || "",
                isLocalClassroom: subject.isLocalClassroom !== false
            })
        }
    }

    InfoBar {
        Layout.fillWidth: true
        closable: false
        severity: Severity.Info
        title: qsTr("Subjects")
        text: qsTr("Choose the subjects to include in the initial schedule. You can also add custom subjects.")
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 16

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 12

            ColumnLayout {
                anchors.fill: parent
                Text { typography: Typography.BodyStrong; text: qsTr("Default Subjects") }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 160
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    model: defaultSubjectsModel
                    spacing: 4
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: CheckBox {
                        width: ListView.view.width
                        text: name + (simplifiedName ? " (" + simplifiedName + ")" : "")
                        checked: selected
                        onCheckedChanged: defaultSubjectsModel.setProperty(index, "selected", checked)
                    }
                }
            }
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 12

            ColumnLayout {
                anchors.fill: parent
                Text { typography: Typography.BodyStrong; text: qsTr("Custom Subjects") }

                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: customNameField; Layout.fillWidth: true; placeholderText: qsTr("Subject name") }
                    TextField { id: customShortField; Layout.preferredWidth: 100; placeholderText: qsTr("Short") }
                }

                RowLayout {
                    Layout.fillWidth: true
                    TextField { id: customColorField; Layout.fillWidth: true; text: "#607D8B"; placeholderText: "#607D8B" }
                    Switch { id: customLocalSwitch; checked: true; text: qsTr("Local") }
                    Button { text: qsTr("Add"); highlighted: true; onClicked: root.addCustomSubject() }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 120
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    model: customModel
                    spacing: 6
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    delegate: RowLayout {
                        width: ListView.view.width
                        Rectangle { width: 12; height: 12; radius: 6; color: subjectColor }
                        TextField {
                            Layout.fillWidth: true
                            text: name
                            onEditingFinished: customModel.setProperty(index, "name", text.trim())
                        }
                        TextField {
                            Layout.preferredWidth: 90
                            text: simplifiedName
                            onEditingFinished: customModel.setProperty(index, "simplifiedName", text.trim())
                        }
                        Button { text: qsTr("Delete"); onClicked: customModel.remove(index) }
                    }
                }
            }
        }
    }
}