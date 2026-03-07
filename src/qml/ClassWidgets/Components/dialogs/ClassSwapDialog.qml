import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Window {
    id: classSwapWindow
    title: qsTr("Class Swap")
    width: 680
    height: 420
    minimumWidth: 680
    minimumHeight: 420
    minimizeVisible: false
    maximizeVisible: false

    onClosing: function(event) {
        event.accepted = false
        classSwapWindow.hide()
    }

    // ── 状态机 ──────────────────────────────────────────────
    // "idle"           → 等待第一次点选
    // "source_selected"→ 已选中源课程，等待目标
    // "ready"          → 双方已选好，等待确认
    property string swapState: "idle"

    // 源课程 (dailyScheduleView 中的)
    property var sourceEntry: null    // {id, subjectId, subjectName, ...}
    property int sourceIndex: -1

    // 目标课程
    property var targetEntry: null    // : dailyScheduleView 中另一节
    property string targetSubjectId: "" // : courseTypeNavigator 选中的科目 id
    property string targetSubjectName: ""
    property bool isSwap: false        // true=互换  false=替换

    // 上次操作记录文本
    property string lastSwapText: ""

    // ComboBox 当前值
    property int selectedDayOfWeek: ClassSwapManager.getPreferredDayOfWeek()
    property int selectedWeekCycle: ClassSwapManager.getPreferredWeekOfCycle()
    property bool pickerSyncing: false

    Component.onCompleted: {
        // 加载科目列表
        let subjects = ClassSwapManager.getAllSubjects()
        subjectsModel.clear()
        for (let i = 0; i < subjects.length; i++) {
            subjectsModel.append({
                sid: subjects[i].id,
                name: subjects[i].name,
                color: subjects[i].color || "",
                icon: subjects[i].icon || ""
            })
        }

        // 加载周次列表
        refreshWeekCycleModel()

        // 加载换课记录
        loadSwapRecords()
        refreshDailyEntries()
    }

    onVisibleChanged: {
        if (!visible)
            return

        // 这个窗口在 App 启动时就会被创建，Component.onCompleted 只触发一次。
        // 因此每次显示窗口时都主动刷新，确保 schedule 已加载后能拿到数据。
        syncPickerOnShow()
        refreshWeekCycleModel()
        refreshDailyEntries()
        loadSwapRecords()
    }

    function syncPickerOnShow() {
        if (ClassSwapManager.hasTodaySwaps()) {
            selectedDayOfWeek = ClassSwapManager.getPreferredDayOfWeek()
            selectedWeekCycle = ClassSwapManager.getPreferredWeekOfCycle()
        } else {
            selectedDayOfWeek = ClassSwapManager.getCurrentDayOfWeek()
            selectedWeekCycle = ClassSwapManager.getCurrentWeekOfCycle()
        }

        pickerSyncing = true
        dayInWeekPicker.currentIndex = selectedDayOfWeek - 1
        pickerSyncing = false
    }

    function loadSwapRecords() {
        if (ClassSwapManager.hasTodaySwaps()) {
            let records = ClassSwapManager.getSwapRecords()
            if (records.length > 0) {
                let last = records[records.length - 1]
                lastSwapText = formatRecordText(last)
            }
        }
    }

    function formatRecordText(record) {
        let oldName = ClassSwapManager.getSubjectName(record.old_subject) || record.old_subject
        let newName = ClassSwapManager.getSubjectName(record.new_subject) || record.new_subject
        if (record.type === "swap") {
            return `${oldName} ⇌ ${newName}`
        } else {
            return `${oldName} → ${newName}`
        }
    }

    function refreshDailyEntries() {
        let entries = ClassSwapManager.getDayEntries(selectedDayOfWeek, selectedWeekCycle)
        dailyModel.clear()
        for (let i = 0; i < entries.length; i++) {
            let e = entries[i]
            dailyModel.append({
                entryId: e.id || "",
                subjectId: e.subjectId || "",
                subjectName: e.subjectName || "",
                title: e.title || "",
                startTime: e.startTime || "",
                endTime: e.endTime || "",
                subjectColor: e.subjectColor || "",
                subjectIcon: e.subjectIcon || ""
            })
        }
    }

    function refreshWeekCycleModel() {
        let maxCycle = ClassSwapManager.getMaxWeekCycle()
        weekCycleModel.clear()

        for (let i = 1; i <= maxCycle; i++) {
            weekCycleModel.append({
                text: maxCycle === 2
                    ? (i === 1 ? qsTr("Odd Week") : qsTr("Even Week"))
                    : qsTr("Week %1").arg(i),
                value: i
            })
        }

        if (selectedWeekCycle < 1 || selectedWeekCycle > maxCycle) {
            selectedWeekCycle = 1
        }
        weekCyclePicker.currentIndex = selectedWeekCycle - 1
    }

    function resetSelection() {
        swapState = "idle"
        sourceEntry = null
        sourceIndex = -1
        targetEntry = null
        targetSubjectId = ""
        targetSubjectName = ""
        isSwap = false
    }

    function getSourceDisplayText() {
        if (!sourceEntry) return ""
        return sourceEntry.subjectName || sourceEntry.title || ""
    }

    function getTargetDisplayText() {
        if (isSwap && targetEntry) {
            return targetEntry.subjectName || targetEntry.title || ""
        }
        if (!isSwap && targetSubjectName) {
            return targetSubjectName
        }
        return ""
    }

    function getPreviewText() {
        let src = getSourceDisplayText()
        if (isSwap) {
            let tgt = getTargetDisplayText()
            return `${src} ⇌ ${tgt} ?`
        } else {
            let tgt = getTargetDisplayText()
            return `${src} → ${tgt} ?`
        }
    }

    function getStatusText() {
        let src = getSourceDisplayText()
        if (isSwap) {
            let tgt = getTargetDisplayText()
            return `${src} ⇌ ${tgt}`
        } else {
            let tgt = getTargetDisplayText()
            return `${src} → ${tgt}`
        }
    }

    // ── 内容 ────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ── 上半部分：左右布局 ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // ─── 左侧：时序调度区 ───
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                // 筛选器
                RowLayout {
                    spacing: 8

                    ComboBox {
                        id: dayInWeekPicker
                        Layout.preferredWidth: 130
                        textRole: "text"
                        valueRole: "value"
                        model: ListModel {
                            id: dayModel
                            ListElement { text: qsTr("Monday"); value: 1 }
                            ListElement { text: qsTr("Tuesday"); value: 2 }
                            ListElement { text: qsTr("Wednesday"); value: 3 }
                            ListElement { text: qsTr("Thursday"); value: 4 }
                            ListElement { text: qsTr("Friday"); value: 5 }
                            ListElement { text: qsTr("Saturday"); value: 6 }
                            ListElement { text: qsTr("Sunday"); value: 7 }
                        }

                        Component.onCompleted: {
                            currentIndex = selectedDayOfWeek - 1
                        }

                        onCurrentIndexChanged: {
                            if (pickerSyncing)
                                return

                            if (currentIndex < 0 || currentIndex >= dayModel.count)
                                return

                            selectedDayOfWeek = dayModel.get(currentIndex).value
                            ClassSwapManager.setSwapPickerContext(selectedDayOfWeek, selectedWeekCycle)
                            ClassSwapManager.applyPickerToToday(selectedDayOfWeek, selectedWeekCycle)
                            resetSelection()
                            refreshDailyEntries()
                        }
                    }

                    ComboBox {
                        id: weekCyclePicker
                        Layout.preferredWidth: 120
                        textRole: "text"
                        valueRole: "value"
                        model: ListModel { id: weekCycleModel }

                        onCurrentIndexChanged: {
                            if (pickerSyncing)
                                return

                            if (currentIndex < 0 || currentIndex >= weekCycleModel.count)
                                return

                            selectedWeekCycle = weekCycleModel.get(currentIndex).value
                            ClassSwapManager.setSwapPickerContext(selectedDayOfWeek, selectedWeekCycle)
                            ClassSwapManager.applyPickerToToday(selectedDayOfWeek, selectedWeekCycle)
                            resetSelection()
                            refreshDailyEntries()
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // 提示标签
                Text {
                    typography: Typography.Caption
                    text: qsTr("Click to select a class to swap")
                    visible: swapState === "idle"
                }

                // 日课表流视图
                ListView {
                    id: dailyScheduleView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Vertical
                    clip: true
                    spacing: 6
                    model: ListModel { id: dailyModel }

                    delegate: Button {
                        id: entryDelegate
                        width: dailyScheduleView.width
                        height: 44

                        property bool isSource: sourceIndex === index
                        property bool isTarget: isSwap && targetEntry && targetEntry.entryId === model.entryId

                        highlighted: isSource || isTarget

                        contentItem: RowLayout {
                            spacing: 8
                            anchors.fill: parent
                            anchors.margins: 8

                            // 科目色条
                            Rectangle {
                                Layout.preferredWidth: 4
                                Layout.preferredHeight: 20
                                radius: 2
                                color: model.subjectColor
                            }

                            Text {
                                Layout.fillWidth: true
                                typography: Typography.BodyStrong
                                text: model.subjectName || model.title || qsTr("(Empty)")
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            Text {
                                typography: Typography.Caption
                                text: model.startTime + " - " + model.endTime
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        onClicked: {
                            if (swapState === "idle") {
                                // 第一下：选中源
                                sourceEntry = dailyModel.get(index)
                                sourceIndex = index
                                swapState = "source_selected"
                            } else if (swapState === "source_selected") {
                                if (index === sourceIndex) {
                                    // 点自己 → 取消选中
                                    resetSelection()
                                    return
                                }
                                // 第二下：选中另一节 → 互换
                                targetEntry = dailyModel.get(index)
                                isSwap = true
                                swapState = "ready"
                            }
                            // ready 状态再点不做操作
                        }
                    }

                    ScrollBar.vertical: ScrollBar {}
                }
            }

            // ─── 右侧：全局课程池 ───
            ColumnLayout {
                Layout.preferredWidth: 160
                Layout.fillHeight: true
                spacing: 4

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("All Subjects")
                }

                ListView {
                    id: courseTypeNavigator
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    model: ListModel { id: subjectsModel }

                    delegate: ListViewDelegate {
                        width: courseTypeNavigator.width
                        height: 36

                        highlighted: !isSwap && targetSubjectId === model.sid
                        text: model.name

                        leftArea: [
                            Rectangle {
                                width: 4
                                height: 20
                                radius: 2
                                color: model.color
                            }
                        ]

                        onClicked: {
                            if (swapState === "source_selected") {
                                // ：替换为此科目
                                targetSubjectId = model.sid
                                targetSubjectName = model.name
                                isSwap = false
                                swapState = "ready"
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {}
                }
            }
        }

        // ── 下方状态与决策区 ──────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // 上次操作记录
            Text {
                id: swapStatusDisplay
                typography: Typography.Caption
                text: lastSwapText
                elide: Text.ElideRight
                Layout.preferredWidth: 180
                visible: lastSwapText.length > 0
            }

            Item { Layout.fillWidth: true }

            // 交互引导文本
            Text {
                id: interactionGuide
                typography: Typography.Body
                text: {
                    if (swapState === "idle")
                        return qsTr("Click a class to swap")
                    if (swapState === "source_selected")
                        return qsTr("Select target class")
                    if (swapState === "ready")
                        return getPreviewText()
                    return ""
                }
            }

            Item { Layout.fillWidth: true }

            // 确认按钮
            Button {
                id: commitSwapBtn
                text: qsTr("Confirm Swap")
                highlighted: true
                visible: swapState === "ready"

                onClicked: {
                    let success = false
                    if (isSwap && sourceEntry && targetEntry) {
                        success = ClassSwapManager.swapTwoEntries(
                            sourceEntry.entryId, targetEntry.entryId,
                            selectedDayOfWeek, selectedWeekCycle
                        )
                    } else if (!isSwap && sourceEntry && targetSubjectId) {
                        success = ClassSwapManager.replaceEntry(
                            sourceEntry.entryId, targetSubjectId,
                            selectedDayOfWeek, selectedWeekCycle
                        )
                    }

                    if (success) {
                        lastSwapText = getStatusText()
                        refreshDailyEntries()
                        resetSelection()
                    }
                }
            }

            // 取消按钮
            Button {
                id: abortSwapBtn
                text: qsTr("Cancel")

                onClicked: {
                    if (swapState === "idle") {
                        // 没有进行中的操作 → 关闭窗口
                        classSwapWindow.hide()
                    } else {
                        // 有进行中的操作 → 还原选择
                        resetSelection()
                    }
                }
            }
        }
    }
}
