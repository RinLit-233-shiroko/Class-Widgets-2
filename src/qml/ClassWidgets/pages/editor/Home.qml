import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    title: qsTr("Home")
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    property string pendingScheduleName: ""
    property bool selectionMode: false
    property int viewMode: 0  // 0 = 网格视图，1 = 表格视图
    property string searchText: ""
    property var scheduleItems: []
    property var selectedNames: []
    property string renameName: ""
    readonly property var visibleSchedules: root.filteredSchedules()

    function refreshSchedules() {
        root.scheduleItems = AppCentral.scheduleManager.schedules()
        root.selectedNames = []
    }
    function filteredSchedules() {
        const query = root.searchText.trim().toLocaleLowerCase()
        return query ? root.scheduleItems.filter(function(item) {
            return String(item.name || "").toLocaleLowerCase().indexOf(query) >= 0
        }) : root.scheduleItems
    }
    function toggleSelected(name) {
        const next = root.selectedNames.slice()
        const index = next.indexOf(name)
        if (index >= 0) next.splice(index, 1)
        else next.push(name)
        root.selectedNames = next
    }
    function selectAll() { root.selectedNames = root.visibleSchedules.map(function(item) { return item.name }) }
    // 全选按钮同时承担取消全选：勾选状态由工具栏判断，这里按传入的意图执行。
    function setAllSelected(select) {
        if (select) root.selectAll()
        else root.selectedNames = []
    }
    function openSchedule(name) {
        if (root.selectionMode) { root.toggleSelected(name); return }
        if (AppCentral.scheduleEditor.dirty) {
            root.pendingScheduleName = name
            switchScheduleDialog.open()
        } else AppCentral.scheduleManager.load(name)
    }
    function showResult(title, text) {
        floatLayer.createInfoBar({ severity: Severity.Success, title: title, text: text })
        root.refreshSchedules()
    }
    function exportSchedule(name, format) {
        const ok = format === "json"
            ? AppCentral.scheduleManager.export(name)
            : AppCentral.scheduleManager.scheduleIO.exportToCSES(name)
        root.showResult(ok ? qsTr("Export complete") : qsTr("Export failed"),
                        ok ? qsTr("The schedule has been exported.") : qsTr("Failed to export the schedule."))
    }
    // 批量导出同样按格式分支：json 直接复制 CW2 文件，cses 走转换器。
    function exportSchedules(names, format) {
        const ok = AppCentral.scheduleEditor.exportSchedules(names, format)
        floatLayer.createInfoBar({
            severity: ok ? Severity.Success : Severity.Error,
            title: ok ? qsTr("Export complete") : qsTr("Export failed"),
            text: ok ? qsTr("Selected schedules were exported.")
                     : qsTr("Failed to export the schedule.")
        })
        root.refreshSchedules()
    }

    Connections {
        target: AppCentral.scheduleManager
        function onSchedulesChanged() { root.refreshSchedules() }
        function onScheduleSwitched() { root.refreshSchedules() }
    }
    Component.onCompleted: Qt.callLater(root.refreshSchedules)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 18

        Introduction {
            Layout.fillWidth: true
            source: PathManager.images("editor/new_editor_schedule-" + (Theme.isDark() ? "dark" : "light") + ".png")
            title: qsTr("The new way to edit schedules")
            description: qsTr("1. Tap and drag to adjust class times;\n2. Quickly fill in courses at a glance;\n3. Done in just 3 steps — editing your schedule has never been easier!")
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button { flat: true; icon.name: "ic_fluent_folder_open_20_regular"; text: qsTr("Open schedules folder"); onClicked: AppCentral.scheduleManager.openSchedulesFolder() }
                ToolSeparator { Layout.fillHeight: true }
                Button {
                    enabled: !AppCentral.scheduleManager.isReadonly()
                    flat: true; highlighted: true; icon.name: "ic_fluent_add_20_regular"; text: qsTr("New Schedule")
                    onClicked: scheduleSetupDialog.open()
                }
            }
        }

        ScheduleBrowserToolbar {
            Layout.fillWidth: true
            selectionMode: root.selectionMode
            selectedCount: root.selectedNames.length
            itemCount: root.visibleSchedules.length
            readOnly: AppCentral.scheduleManager.isReadonly()
            viewIndex: root.viewMode
            onViewIndexRequested: function(index) { root.viewMode = index }
            onSearchChanged: function(text) { root.searchText = text }
            onSelectionModeRequested: function(enabled) {
                root.selectionMode = enabled
                if (!enabled) root.selectedNames = []
            }
            onSelectAllRequested: function(select) { root.setAllSelected(select) }
            onDuplicateSelected: if (AppCentral.scheduleEditor.duplicateSchedules(root.selectedNames)) root.showResult(qsTr("Schedules copied"), qsTr("Selected schedules were duplicated."))
            onExportSelected: function(format) { root.exportSchedules(root.selectedNames, format) }
            onDeleteSelected: deleteSelectedDialog.open()
        }

        // 网格 / 表格由同一个组件按 viewMode 切换呈现方式。
        ScheduleFileView {
            Layout.fillWidth: true
            Layout.minimumHeight: root.viewMode === 0 ? 180 : 200
            Layout.preferredHeight: root.viewMode === 0
                ? Math.max(180, Math.ceil(root.visibleSchedules.length / Math.max(1, Math.floor(width / 124))) * 124)
                : Math.max(200, 90 + root.visibleSchedules.length * 40)
            viewMode: root.viewMode
            schedules: root.visibleSchedules
            selectedNames: root.selectedNames
            currentName: AppCentral.scheduleManager.currentScheduleName
            selectionMode: root.selectionMode
            onScheduleActivated: root.openSchedule(name)
            onSelectionToggled: root.toggleSelected(name)
            onDuplicateRequested: if (AppCentral.scheduleManager.duplicate(name, name + " (Copy)")) root.refreshSchedules()
            onDeleteRequested: { root.selectedNames = [name]; deleteSelectedDialog.open() }
            onExportRequested: function(name, format) { root.exportSchedule(name, format) }
            onRenameRequested: function(name) { root.renameName = name; renameField.text = name; renameDialog.open() }
        }
    }

    Dialog {
        id: renameDialog
        modal: true
        title: qsTr("Rename Schedule")
        ColumnLayout { TextField { id: renameField; Layout.fillWidth: true } }
        standardButtons: Dialog.Ok | Dialog.Cancel
        onAccepted: if (renameField.text.length > 0 && AppCentral.scheduleManager.rename(root.renameName, renameField.text)) root.refreshSchedules()
    }

    Dialog {
        id: switchScheduleDialog
        modal: true
        title: qsTr("Save changes to the timetable")
        Text { Layout.fillWidth: true; text: qsTr("Do you want to save the changes to \"%1\"?").arg(AppCentral.scheduleEditor.filename) }
        standardButtons: Dialog.Save | Dialog.Discard | Dialog.Cancel
        onAccepted: {
            if (AppCentral.scheduleManager.save()) {
                AppCentral.scheduleEditor.markSaved()
                AppCentral.scheduleManager.load(root.pendingScheduleName)
            } else floatLayer.createInfoBar({ severity: Severity.Error, title: qsTr("Save Failed"), text: qsTr("Failed to save schedule, see log for details") })
        }
        onDiscarded: { AppCentral.scheduleEditor.markSaved(); AppCentral.scheduleManager.load(root.pendingScheduleName) }
    }

    Dialog {
        id: deleteSelectedDialog
        modal: true
        title: qsTr("Delete selected schedules?")
        Text { Layout.fillWidth: true; text: qsTr("The current schedule will be kept. This action cannot be undone.") }
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: if (AppCentral.scheduleEditor.deleteSchedules(root.selectedNames)) root.showResult(qsTr("Schedules deleted"), qsTr("Selected schedules were deleted."))
    }

    ScheduleSetupDialog {
        id: scheduleSetupDialog
        onScheduleCreated: {
            root.refreshSchedules()
            root.showResult(qsTr("Schedule Created"), qsTr("The schedule has been created successfully."))
        }
    }
}
