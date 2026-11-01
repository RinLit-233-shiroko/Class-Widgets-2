import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../editor"
import "../plaza"


/* “永不自动隐藏的课程”选择器：左侧课表列表，右侧复用学科卡片勾选。
   勾选按课程名称记录、对所有课表生效——同名课程在任意课表中的勾选状态始终一致。 */
Dialog {
    id: root

    title: qsTr("Never Auto-Hide These Courses")
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    width: Math.min(760, (Overlay.overlay ? Overlay.overlay.width : 800) - 80)

    // 课表分组：[{ name, isCurrent, subjects: [{ id, name, ... }, ...] }]
    property var scheduleGroups: []
    // 已勾选的课程名称（全局生效，跨课表共享）
    property var selectedNames: []
    // 已勾选、但不存在于任何课表中的名称（早期手输遗留），单独成组以便取消
    property var orphanNames: []
    property int currentGroupIndex: 0

    readonly property bool locked: Configs.isKeyLocked("interactions.hide.no_hide_subjects")

    // 课表列表与课程网格共用的分组数据
    readonly property var groups: {
        var list = []
        for (var i = 0; i < scheduleGroups.length; ++i) {
            list.push({
                "name": scheduleGroups[i].name,
                "label": scheduleGroups[i].name,
                "isCurrent": scheduleGroups[i].isCurrent === true,
                "subjects": toArray(scheduleGroups[i].subjects)
            })
        }
        if (orphanNames.length > 0) {
            var orphans = []
            for (var j = 0; j < orphanNames.length; ++j) {
                var name = String(orphanNames[j] || "")
                orphans.push({
                    "id": "__orphan__:" + name,
                    "name": name,
                    "simplifiedName": "",
                    "teacher": "",
                    "icon": "",
                    "color": "",
                    "location": "",
                    "isLocalClassroom": true
                })
            }
            list.push({
                "name": "",
                "label": qsTr("Not in any schedule"),
                "isCurrent": false,
                "subjects": orphans
            })
        }
        return list
    }

    readonly property var currentSubjects:
        (currentGroupIndex >= 0 && currentGroupIndex < groups.length)
            ? groups[currentGroupIndex].subjects : []

    readonly property bool hasSchedules: scheduleGroups.length > 0

    property string searchText: ""

    readonly property var filteredSubjects: {
        var query = String(searchText || "").trim().toLowerCase()
        if (!query)
            return currentSubjects
        var out = []
        for (var i = 0; i < currentSubjects.length; ++i) {
            if (matchesSubject(currentSubjects[i], query))
                out.push(currentSubjects[i])
        }
        return out
    }

    readonly property bool allFilteredSelected: {
        if (filteredSubjects.length === 0)
            return false
        for (var i = 0; i < filteredSubjects.length; ++i) {
            if (!isSelected(filteredSubjects[i].name))
                return false
        }
        return true
    }

    onCurrentGroupIndexChanged: {
        if (scheduleList.currentIndex !== currentGroupIndex)
            scheduleList.currentIndex = currentGroupIndex
        resetSearch()
        rememberCurrentSchedule()
    }

    onGroupsChanged: {
        if (currentGroupIndex >= groups.length)
            currentGroupIndex = Math.max(0, groups.length - 1)
    }

    // 每次打开时重新读取课表与当前配置，避免课表改动后列表过期。
    // 先恢复 selectedNames，最后才赋值 scheduleGroups——网格委托创建时据此读取勾选态。
    function reloadData() {
        resetSearch()
        var loadedGroups = AppCentral.scheduleManager.allSchedulesSubjects()
        var remembered = String(Configs.data.interactions.hide.last_exempt_schedule || "")
        var targetIndex = 0
        for (var i = 0; i < loadedGroups.length; ++i) {
            if (loadedGroups[i].name === remembered) {
                targetIndex = i
                break
            }
        }

        selectedNames = readSelection()
        orphanNames = collectOrphans(selectedNames, loadedGroups)
        scheduleGroups = loadedGroups
        currentGroupIndex = targetIndex
        rememberCurrentSchedule()
    }

    function rememberCurrentSchedule() {
        if (currentGroupIndex < 0 || currentGroupIndex >= groups.length)
            return
        var name = groups[currentGroupIndex].name
        if (name && Configs.data.interactions.hide.last_exempt_schedule !== name)
            Configs.set("interactions.hide.last_exempt_schedule", name)
    }

    onAboutToShow: reloadData()

    onAccepted: Configs.set("interactions.hide.no_hide_subjects", selectedNames)

    // 来自 Python 的 list 在 QML 侧并不是真正的 JS 数组（Array.isArray 为 false），
    // 这种对象直接当模型会导致一个子项都渲染不出来。统一转成真正的 JS 数组。
    function toArray(value) {
        var out = []
        if (!value)
            return out
        if (Array.isArray(value)) {
            for (var i = 0; i < value.length; ++i)
                out.push(value[i])
            return out
        }
        if (typeof value.length === "number") {
            for (var j = 0; j < value.length; ++j)
                out.push(value[j])
        }
        return out
    }

    function isSelected(name) {
        return selectedNames.indexOf(name) >= 0
    }

    function setSelected(name, on) {
        var next = selectedNames.slice()
        var at = next.indexOf(name)
        if (on) {
            if (at >= 0)
                return
            next.push(name)
        } else {
            if (at < 0)
                return
            next.splice(at, 1)
        }
        selectedNames = next
        syncOrphans()
    }

    // 取消勾选孤儿课程后该分组即消失
    function syncOrphans() {
        if (orphanNames.length === 0)
            return
        var kept = []
        for (var i = 0; i < orphanNames.length; ++i) {
            if (selectedNames.indexOf(orphanNames[i]) >= 0)
                kept.push(orphanNames[i])
        }
        if (kept.length !== orphanNames.length) {
            orphanNames = kept
            if (currentGroupIndex >= groups.length)
                currentGroupIndex = Math.max(0, groups.length - 1)
        }
    }

    function matchesSubject(subject, query) {
        if (!subject)
            return false
        var fields = [subject.name, subject.simplifiedName, subject.teacher]
        for (var i = 0; i < fields.length; ++i) {
            if (String(fields[i] || "").toLowerCase().indexOf(query) >= 0)
                return true
        }
        return false
    }

    function setAllFilteredSelected(select) {
        var next = selectedNames.slice()
        for (var i = 0; i < filteredSubjects.length; ++i) {
            var name = filteredSubjects[i].name
            var at = next.indexOf(name)
            if (select) {
                if (at < 0)
                    next.push(name)
            } else if (at >= 0) {
                next.splice(at, 1)
            }
        }
        selectedNames = next
        syncOrphans()
    }

    function clearAllSelected() {
        selectedNames = []
        orphanNames = []
        if (currentGroupIndex >= groups.length)
            currentGroupIndex = Math.max(0, groups.length - 1)
    }

    function resetSearch() {
        searchText = ""
        if (searchField)
            searchField.text = ""
    }

    // SubjectClip 只回传 subjectId，勾选键仍是课程名称。
    function toggleSubject(subjectId) {
        for (var i = 0; i < currentSubjects.length; ++i) {
            if (String(currentSubjects[i].id) === String(subjectId)) {
                var name = currentSubjects[i].name
                setSelected(name, !isSelected(name))
                return
            }
        }
    }

    // Configs.data 中的列表在 QML 侧不一定是真正的 JS 数组，按类数组安全展开
    function readSelection() {
        var stored = Configs.data.interactions.hide.no_hide_subjects
        var out = []
        if (stored && typeof stored.length === "number") {
            for (var i = 0; i < stored.length; ++i) {
                var name = String(stored[i] || "").trim()
                if (name && out.indexOf(name) < 0)
                    out.push(name)
            }
        }
        return out
    }

    function collectOrphans(selection, sourceGroups) {
        var known = []
        for (var i = 0; i < sourceGroups.length; ++i) {
            var subjects = sourceGroups[i].subjects || []
            for (var j = 0; j < subjects.length; ++j) {
                var name = subjects[j] && subjects[j].name
                if (name && known.indexOf(name) < 0)
                    known.push(name)
            }
        }
        var out = []
        for (var k = 0; k < selection.length; ++k) {
            if (known.indexOf(selection[k]) < 0)
                out.push(selection[k])
        }
        return out
    }

    ColumnLayout {
        Layout.preferredWidth: root.width - 48
        spacing: 12

        Text {
            Layout.fillWidth: true
            typography: Typography.Body
            wrapMode: Text.Wrap
            text: qsTr("Selected courses will never be auto-hidden. Applies to all schedules.")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 360
            spacing: 12

            // 左侧课表列表：课表多时可滚动，不挤占课程区域
            ColumnLayout {
                Layout.preferredWidth: 220
                Layout.maximumWidth: 220
                Layout.fillHeight: true

                ListView {
                    id: scheduleList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.groups
                    currentIndex: root.currentGroupIndex
                    enabled: !root.locked
                    onItemClicked: function(index) { root.currentGroupIndex = index }

                    delegate: ListViewDelegate {
                        required property var modelData
                        required property int index

                        rightPadding: 16
                        highlighted: index === root.currentGroupIndex

                        contentItem: RowLayout {
                            spacing: 8

                            Icon {
                                Layout.alignment: Qt.AlignVCenter
                                name: "ic_fluent_calendar_20_regular"
                                size: 18
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                text: modelData.label
                                typography: Typography.Body
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: Theme.currentTheme.colors.controlBorderColor
            }

            // 右侧课程卡片：复用编辑器里的学科卡片（图标、颜色、教师、地点）
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: qsTr("Search courses")
                        leftPadding: 34
                        onTextChanged: root.searchText = text

                        Icon {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 10
                            name: "ic_fluent_search_20_regular"
                            size: 16
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        // 固定宽度并居中，数字变化时不会挤压搜索框，视觉间距也与按钮一致
                        Item {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 32
                            Layout.alignment: Qt.AlignVCenter
                            opacity: root.selectedNames.length > 0 ? 1 : 0.45

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Icon {
                                    name: "ic_fluent_checkbox_checked_20_regular"
                                    size: 16
                                    color: Theme.currentTheme.colors.textSecondaryColor
                                }

                                Text {
                                    text: root.selectedNames.length
                                    typography: Typography.Caption
                                    color: Theme.currentTheme.colors.textSecondaryColor
                                }
                            }
                        }

                        ToolButton {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 0
                            enabled: !root.locked && root.filteredSubjects.length > 0
                            flat: true
                            icon.name: root.allFilteredSelected
                                ? "ic_fluent_select_all_off_20_regular"
                                : "ic_fluent_select_all_on_20_regular"
                            onClicked: root.setAllFilteredSelected(!root.allFilteredSelected)

                            ToolTip {
                                text: root.allFilteredSelected
                                    ? qsTr("Clear selection")
                                    : qsTr("Select all")
                                visible: parent.hovered
                            }
                        }

                        ToolButton {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            padding: 0
                            enabled: !root.locked && root.selectedNames.length > 0
                            flat: true
                            icon.name: "ic_fluent_eraser_20_regular"
                            onClicked: root.clearAllSelected()

                            ToolTip {
                                text: qsTr("Clear all selections")
                                visible: parent.hovered
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: subjectsGrid
                        anchors.fill: parent
                        clip: true
                        cellWidth: Math.max(200, width / Math.max(1, Math.floor(width / 220)))
                        cellHeight: 92

                        model: root.filteredSubjects

                        delegate: SubjectClip {
                            required property var modelData

                            width: subjectsGrid.cellWidth - 8
                            height: subjectsGrid.cellHeight - 6
                            enabled: !root.locked
                            selectionMode: true
                            selected: root.isSelected(modelData.name)
                            // 选择器里不允许通过右键菜单删除课程
                            readOnly: true
                            onSelectionToggled: function(subjectId) { root.toggleSubject(subjectId) }
                        }

                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    }

                    EmptyState {
                        anchors.fill: parent
                        visible: root.filteredSubjects.length === 0
                        icon.name: "ic_fluent_square_hint_sparkles_20_regular"
                        title: !root.hasSchedules
                            ? qsTr("No schedules")
                            : root.currentSubjects.length === 0
                                ? qsTr("No courses in this schedule")
                                : qsTr("No matching courses")
                        description: !root.hasSchedules
                            ? qsTr("Create a schedule in the schedule editor first.")
                            : root.currentSubjects.length === 0
                                ? qsTr("Add subjects in the schedule editor to choose them here.")
                                : qsTr("Try a different search term.")
                    }
                }
            }
        }
    }
}
