import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


Item {
    id: root
    // SaveFlyout {}
    property string editedSubjectId: ""
    property bool isNewSubject: false

    // 选择模式与批量删除状态
    property bool selectionMode: false
    property var selectedSubjectIds: []
    // 待删除的科目 id 列表；单个右键删除与批量删除共用同一个确认对话框
    property var pendingDeleteIds: []

    readonly property var visibleSubjects: AppCentral.scheduleEditor.subjects || []
    readonly property bool allSelected: visibleSubjects.length > 0
                                      && selectedSubjectIds.length >= visibleSubjects.length
    readonly property bool readOnly: AppCentral.scheduleManager.isReadonly()

    function resetDialogFields(name, simplifiedName, teacher, icon, color, location, isLocalClassroom) {
        subjectSimplifiedName.text = simplifiedName || ""
        subjectName.text = name || ""
        subjectTeacher.text = teacher || ""
        subjectLocation.text = location || ""
        subjectColor.color = color || "#13c4d6"
        subjectIsLocalClassroom.checked = isLocalClassroom
        iconBtn.icon.name = icon || "ic_fluent_square_hint_20_regular"
    }

    function openEditDialog(subjectId, name, simplifiedName, teacher, icon, color, location, isLocalClassroom) {
        isNewSubject = false
        editedSubjectId = subjectId
        resetDialogFields(name, simplifiedName, teacher, icon, color, location, isLocalClassroom)
        editDialog.open()
    }

    function openAddDialog() {
        isNewSubject = true
        editedSubjectId = ""
        resetDialogFields("", "", "", "", "", "", true)
        editDialog.open()
    }

    function isSelected(subjectId) {
        return (selectedSubjectIds || []).indexOf(subjectId) >= 0
    }

    function toggleSelected(subjectId) {
        const next = (selectedSubjectIds || []).slice()
        const index = next.indexOf(subjectId)
        if (index >= 0) next.splice(index, 1)
        else next.push(subjectId)
        selectedSubjectIds = next
    }

    // 全选按钮同时承担取消全选：勾选状态在 QML 侧判断，这里按传入意图执行。
    function setAllSelected(select) {
        selectedSubjectIds = select
            ? visibleSubjects.map(function(subject) { return subject.id })
            : []
    }

    function subjectNameById(subjectId) {
        const list = visibleSubjects
        for (let i = 0; i < list.length; ++i) {
            if (list[i].id === subjectId)
                return String(list[i].name || "")
        }
        return ""
    }

    function requestRemove(subjectId) {
        pendingDeleteIds = [subjectId]
        removeConfirmDialog.open()
    }

    function requestRemoveSelected() {
        pendingDeleteIds = (selectedSubjectIds || []).slice()
        if (pendingDeleteIds.length > 0)
            removeConfirmDialog.open()
    }

    function removeConfirmText() {
        const ids = pendingDeleteIds || []
        if (ids.length === 1) {
            return qsTr("Are you sure you want to remove \"%1\"? Courses using this subject will also be removed.")
                .arg(subjectNameById(ids[0]) || qsTr("Subject"))
        }
        return qsTr("Are you sure you want to remove %1 subjects? Courses using these subjects will also be removed.")
            .arg(ids.length)
    }

    // 科目列表变化后清理失效的选中项，避免删除后残留 id。
    Connections {
        target: AppCentral.scheduleEditor
        function onSubjectsChanged() {
            // 直接读后端列表，不依赖 visibleSubjects 绑定的刷新时机。
            const list = AppCentral.scheduleEditor.subjects || []
            const valid = {}
            for (let i = 0; i < list.length; ++i)
                valid[list[i].id] = true
            root.selectedSubjectIds = (root.selectedSubjectIds || []).filter(function(id) {
                return valid[id]
            })
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Item {
            //     Layout.fillWidth: true
            // }
            Button {
                flat: true
                text: root.selectionMode ? qsTr("Cancel") : qsTr("Select")
                onClicked: {
                    root.selectionMode = !root.selectionMode
                    if (!root.selectionMode)
                        root.selectedSubjectIds = []
                }
            }

            ToolSeparator { visible: root.selectionMode; }

            // 选择模式下的批量操作
            ToolButton {
                visible: root.selectionMode
                enabled: root.visibleSubjects.length > 0
                flat: true
                icon.name: root.allSelected ? "ic_fluent_select_all_off_20_regular"
                                            : "ic_fluent_select_all_on_20_regular"
                onClicked: root.setAllSelected(!root.allSelected)

                ToolTip {
                    visible: parent.hovered
                    text: root.allSelected ? qsTr("Clear selection") : qsTr("Select all")
                }
            }

            ToolSeparator { visible: root.selectionMode; }

            ToolButton {
                visible: root.selectionMode
                enabled: root.selectedSubjectIds.length > 0 && !root.readOnly
                flat: true
                icon.name: "ic_fluent_delete_20_regular"
                onClicked: root.requestRemoveSelected()

                ToolTip {
                    visible: parent.hovered
                    text: qsTr("Delete selected")
                }
            }

            Item {
                Layout.fillWidth: true
            }
            // ToolSeparator {}

            Button {
                flat: true
                enabled: !root.readOnly
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
                flat: true
                enabled: !root.readOnly
                highlighted: true
                icon.name: "ic_fluent_add_20_regular"
                text: qsTr("Add Subject")
                onClicked: {
                    root.openAddDialog()
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
            cellHeight: 92
            flow: GridView.FlowLeftToRight

            model: root.visibleSubjects

            delegate: SubjectClip {
                enabled: !root.readOnly
                selectionMode: root.selectionMode
                selected: root.isSelected(modelData.id)
                readOnly: root.readOnly
                onEditRequested: function(subjectId, name, simplifiedName, teacher, icon, color, location, isLocalClassroom) {
                    root.openEditDialog(
                        subjectId, name, simplifiedName, teacher, icon, color, location, isLocalClassroom
                    )
                }
                onSelectionToggled: function(subjectId) { root.toggleSelected(subjectId) }
                onDeleteRequested: function(subjectId) { root.requestRemove(subjectId) }
            }

            ScrollBar.vertical: ScrollBar {}
        }
    }

    Dialog {
        id: editDialog
        title: root.isNewSubject ? qsTr("Add Subject") : qsTr("Edit Subject")
        width: 420
        modal: true

        ColumnLayout {
            spacing: 12
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                Text { text: qsTr("Simplified Name"); Layout.fillWidth: true }
                TextField { id: subjectSimplifiedName; Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Subject Name"); Layout.fillWidth: true }
                TextField { id: subjectName; placeholderText: qsTr("e.g. Science"); Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Teacher"); Layout.fillWidth: true }
                TextField { id: subjectTeacher; Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Location"); Layout.fillWidth: true }
                TextField { id: subjectLocation; placeholderText: qsTr("e.g. Room 7813"); Layout.preferredWidth: 250 }
            }

            RowLayout {
                Text { text: qsTr("Color"); Layout.fillWidth: true }
                DropDownColorPicker {
                    id: subjectColor
                    Layout.preferredWidth: 128
                    position: Position.Left
                    textVisible: true
                    hexText: true
                }
            }

            RowLayout {
                Text { text: qsTr("Held in homeroom"); Layout.fillWidth: true }
                Button {
                    id: explainButton
                    icon.name: "ic_fluent_question_circle_20_regular"
                    implicitWidth: 24
                    implicitHeight: 24
                    onClicked: explainFlyout.open()
                }
                Switch { id: subjectIsLocalClassroom }
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
                        onIconPicked: function(name) { iconBtn.icon.name = name }
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

        // 删除入口已移到卡片右键菜单，这里只保留确定 / 取消。
        footer: DialogButtonBox {
            standardButtons: DialogButtonBox.Ok | DialogButtonBox.Cancel
            property Button okButton: standardButton(DialogButtonBox.Ok)

            Component.onCompleted: {
                if (okButton)
                    okButton.enabled = !root.readOnly
            }

            onAccepted: {
                const name = subjectName.text || qsTr("Subject")
                if (root.isNewSubject) {
                    const newSubjectId = AppCentral.scheduleEditor.addSubject(
                        name, subjectTeacher.text, iconBtn.icon.name,
                        subjectColor.color.toString(), subjectLocation.text,
                        subjectIsLocalClassroom.checked
                    )
                    // addSubject 不支持简称，创建后再补充其余字段
                    AppCentral.scheduleEditor.updateSubject(
                        newSubjectId, name, subjectSimplifiedName.text, subjectTeacher.text,
                        iconBtn.icon.name, subjectColor.color.toString(), subjectLocation.text,
                        subjectIsLocalClassroom.checked
                    )
                } else {
                    AppCentral.scheduleEditor.updateSubject(
                        root.editedSubjectId, name, subjectSimplifiedName.text, subjectTeacher.text,
                        iconBtn.icon.name, subjectColor.color.toString(), subjectLocation.text,
                        subjectIsLocalClassroom.checked
                    )
                }
            }
            onRejected: editDialog.close()
        }
    }

    // 单个删除与批量删除共用的二次确认。
    Dialog {
        id: removeConfirmDialog
        title: qsTr("Remove Subject")
        modal: true

        Text {
            Layout.fillWidth: true
            text: root.removeConfirmText()
        }

        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: {
            AppCentral.scheduleEditor.removeSubjects(root.pendingDeleteIds)
            root.selectedSubjectIds = []
            root.pendingDeleteIds = []
            removeConfirmDialog.close()
        }
        onRejected: {
            root.pendingDeleteIds = []
            removeConfirmDialog.close()
        }
    }
}
