import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


/*  “永不自动隐藏的课程”选择器。
    居中弹窗（确认后生效），顶部是课表选择条（可横向滑动），下方是该课表的课程胶囊。
    勾选结果以课程名称记录、对所有课表生效——同名课程在任意课表中的
    勾选状态始终一致。 */
Dialog {
    id: root

    title: qsTr("永不自动隐藏这些课程")
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    width: 460

    // 课表分组：[{ name, isCurrent, subjects: [课程名, ...] }]
    property var scheduleGroups: []
    // 已勾选的课程名称（全局生效，跨课表共享）
    property var selectedNames: []
    // 已勾选、但不存在于任何课表中的名称（早期手输遗留），单独成组以便取消
    property var orphanNames: []
    property int currentGroupIndex: 0

    readonly property bool locked: Configs.isKeyLocked("interactions.hide.no_hide_subjects")

    // 选择条与胶囊列表共用的分组数据
    readonly property var groups: {
        var list = []
        for (var i = 0; i < scheduleGroups.length; ++i) {
            list.push({
                "label": scheduleGroups[i].name,
                "subjects": toArray(scheduleGroups[i].subjects)
            })
        }
        if (orphanNames.length > 0)
            list.push({ "label": qsTr("不在任何课表中"), "subjects": toArray(orphanNames) })
        return list
    }

    readonly property var currentSubjects:
        (currentGroupIndex >= 0 && currentGroupIndex < groups.length)
            ? groups[currentGroupIndex].subjects : []

    onCurrentGroupIndexChanged: {
        if (scheduleBar.currentIndex !== currentGroupIndex)
            scheduleBar.currentIndex = currentGroupIndex
    }

    // 每次打开时重新读取课表与当前配置，避免课表改动后列表过期。
    // 顺序很关键：必须先恢复 selectedNames，最后才赋值 scheduleGroups——
    // 后者会触发 Repeater 重建胶囊，而胶囊的勾选态只在创建时读一次
    // （Component.onCompleted: checked = ...）。先建胶囊后填选择，
    // 会让所有胶囊都显示为未勾选。
    onAboutToShow: {
        var loadedGroups = AppCentral.scheduleManager.allSchedulesSubjects()
        selectedNames = readSelection()
        orphanNames = collectOrphans(selectedNames, loadedGroups)
        scheduleGroups = loadedGroups
        currentGroupIndex = 0
    }

    onAccepted: Configs.set("interactions.hide.no_hide_subjects", selectedNames)

    // 来自 Python 的 list 在 QML 侧并不是真正的 JS 数组（Array.isArray 为 false），
    // 这种对象直接当作 Repeater 的 model 会导致一个胶囊都渲染不出来。
    // 统一转成真正的 JS 数组。
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

        // 取消勾选孤儿课程后该分组即消失
        if (!on && orphanNames.length > 0) {
            var kept = []
            for (var i = 0; i < orphanNames.length; ++i) {
                if (next.indexOf(orphanNames[i]) >= 0)
                    kept.push(orphanNames[i])
            }
            if (kept.length !== orphanNames.length) {
                orphanNames = kept
                if (currentGroupIndex >= groups.length)
                    currentGroupIndex = Math.max(0, groups.length - 1)
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
                if (known.indexOf(subjects[j]) < 0)
                    known.push(subjects[j])
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
            color: Theme.currentTheme.colors.textSecondaryColor
            wrapMode: Text.Wrap
            text: qsTr("这些课程永远不会被自动隐藏（无论是上课、窗口最大化还是全屏触发），选择对所有课表生效。")
        }

        // 课表选择条：课表过多时横向滑动，而不是把弹窗撑宽
        Flickable {
            id: scheduleBarFlickable
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            contentWidth: scheduleBar.width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentWidth > width

            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

            Segmented {
                id: scheduleBar
                width: implicitWidth
                height: 32
                enabled: !root.locked

                onCurrentIndexChanged: {
                    if (root.currentGroupIndex !== currentIndex)
                        root.currentGroupIndex = currentIndex
                }

                Repeater {
                    model: root.groups

                    delegate: SegmentedItem {
                        required property var modelData

                        width: implicitWidth
                        text: modelData.label
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 248
            radius: Theme.currentTheme.appearance.buttonRadius
            color: Theme.currentTheme.colors.controlAltSecondaryColor
            border.width: Theme.currentTheme.appearance.borderWidth
            border.color: Theme.currentTheme.colors.controlBorderColor

            Flickable {
                id: chipFlickable
                anchors.fill: parent
                anchors.margins: 12
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: width
                contentHeight: chipFlow.height

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Flow {
                    id: chipFlow
                    width: chipFlickable.width
                    spacing: 8

                    Repeater {
                        model: root.currentSubjects

                        delegate: PillButton {
                            required property string modelData

                            text: modelData
                            checkable: true
                            enabled: !root.locked
                            // 勾选状态来自全局选择，不绑定以免被点击时的内部赋值打断
                            Component.onCompleted: checked = root.isSelected(modelData)
                            onClicked: root.setSelected(modelData, checked)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.currentSubjects.length === 0
                typography: Typography.Body
                color: Theme.currentTheme.colors.textSecondaryColor
                text: qsTr("该课表中暂无课程")
            }
        }
    }
}
