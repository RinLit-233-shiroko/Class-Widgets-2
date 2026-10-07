import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import QtQuick.Window as QQW
import "../editor/CoursePalette.js" as CoursePalette

// 换课窗口 / Class Swap
// 普通窗口：可拖动、可被 Alt+Tab / 任务栏选中，且不置顶。样式与行为对齐
// Windows/ProblemReport.qml —— 无边框 + 自定义标题栏 + 四周投影留白，
// 并保留标题栏右侧的关闭按钮（关窗统一交给 WindowManager 释放）。
QQW.Window {
    id: classSwapWindow

    visible: false
    title: qsTr("Class Swap")
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // 面板四周留出的投影空间 / room for the drop shadow
    readonly property int shadowMargin: 32
    readonly property int dialogWidth: 600
    readonly property int dialogHeight: 675
    readonly property int titleBarHeight: 32
    readonly property int dialogRadius: Theme.currentTheme.appearance.windowRadius

    width: panelRoot.width + shadowMargin * 2
    height: panelRoot.height + shadowMargin * 2

    Component.onCompleted: {
        // 首次显示时居中，之后用户可以自由拖动。
        classSwapWindow.x = Math.round((Screen.width - classSwapWindow.width) / 2) + Screen.virtualX
        classSwapWindow.y = Math.round((Screen.height - classSwapWindow.height) / 2) + Screen.virtualY
    }

    onClosing: function(event) {
        // 不接受 Qt 的默认关闭流程，统一交给 WindowManager 释放窗口，
        // 这样下次打开换课窗口时还能重新创建。
        event.accepted = false
        WindowManager.closeClassSwap()
    }

    // ── 分页 ────────────────────────────────────────────────────────────
    // 0 = 选择课程, 1 = 选择交换/替换目标
    property int currentPage: 0
    property bool navigationPending: false
    property int pendingPage: -1
    property int normalExitDirection: 0
    // ── 选择状态 ────────────────────────────────────────────────────────
    property string sourceEntryId: ""
    property string sourceSubjectId: ""
    property string sourceSubjectName: ""
    property string targetEntryId: ""
    property string targetSubjectName: ""
    // 第二页的目标模式："swap" 与另一课程交换，"replace" 替换为学科
    property string targetMode: "swap"
    property string pickedSubjectId: ""
    property string pickedSubjectName: ""
    // ── 数据 ────────────────────────────────────────────────────────────
    property var dailyEntries: []
    property var subjects: []
    property int maxWeekCycle: 2
    property int selectedDayOfWeek: ClassSwapManager.getPreferredDayOfWeek()
    property int selectedWeekCycle: ClassSwapManager.getPreferredWeekOfCycle()
    property bool pickerSyncing: false
    readonly property var weekdayNames: [
        qsTr("Monday"), qsTr("Tuesday"), qsTr("Wednesday"), qsTr("Thursday"),
        qsTr("Friday"), qsTr("Saturday"), qsTr("Sunday")
    ]
    // ── 周次选择框 ──────────────────────────────────────────────────────
    // 双周轮换直接显示「单 / 双」，更长的周期则把数字夹在「第 x 周」之间。
    readonly property bool showWeekCycleSelector: maxWeekCycle > 1
    readonly property bool parityCycle: maxWeekCycle === 2
    readonly property string weekFormat: qsTr("Week {value}")
    readonly property var weekFormatParts: weekFormat.split("{value}")
    readonly property string weekCyclePrefix: parityCycle ? "" : weekFormatParts[0]
    readonly property string weekCycleSuffix: parityCycle ? qsTr("Week") : weekFormatParts[1]
    readonly property var weekCycleOptions: {
        const options = []
        if (maxWeekCycle <= 2) {
            options.push({ text: qsTr("Odd"), value: 1 })
            options.push({ text: qsTr("Even"), value: 2 })
        } else {
            for (let i = 1; i <= maxWeekCycle; ++i)
                options.push({ text: String(i), value: i })
        }
        return options
    }
    // Page 2 cannot reuse the source course, nor any course of its subject in
    // the shown week. Resolving the whole set here keeps the timeline free of
    // any knowledge about *why* something is unavailable.
    readonly property var disabledEntryIds: {
        const ids = []
        if (!sourceEntryId)
            return ids
        const entries = dailyEntries || []
        for (let i = 0; i < entries.length; ++i) {
            const entry = entries[i]
            if (!entry)
                continue
            if (entry.id === sourceEntryId
                    || (sourceSubjectId && entry.subjectId === sourceSubjectId))
                ids.push(String(entry.id))
        }
        return ids
    }

    // ── 底部按钮 ──────────────────────────────────────────────────────────
    readonly property bool canCommit: currentPage === 0
        ? sourceEntryId.length > 0
        : (targetMode === "swap" ? targetEntryId.length > 0 : pickedSubjectId.length > 0)
    readonly property string commitLabel: {
        if (currentPage === 0)
            return qsTr("Continue")
        // 名称缺失（空状态）时退回不带名称的短文案，避免出现「替换为 ""」。
        if (targetMode === "swap")
            return targetSubjectName.length > 0
                ? qsTr("Swap with \"%1\"").arg(targetSubjectName)
                : qsTr("Swap")
        return pickedSubjectName.length > 0
            ? qsTr("Replace subject with \"%1\"").arg(pickedSubjectName)
            : qsTr("Replace")
    }
    property ParallelAnimation normalPageExit: ParallelAnimation {
        NumberAnimation {
            target: pageStack.currentItem
            property: "x"
            to: pageStack.width * 0.25 * classSwapWindow.normalExitDirection
            duration: 220
            easing.type: Easing.Bezier
            easing.bezierCurve: [1, 0, 1, 1, 1, 1]
        }
        NumberAnimation {
            target: pageStack.currentItem
            property: "opacity"
            to: 0
            duration: 140
            easing.type: Easing.OutCubic
        }
        onStopped: {
            if (classSwapWindow.navigationPending)
                classSwapWindow.finishNavigation()
        }
    }
    // ── 生命周期 ────────────────────────────────────────────────────────
    onVisibleChanged: {
        if (!visible)
            return
        // 这个窗口按需创建，但可视化状态仍然只在显示时刷新，
        // 确保 schedule 已加载后能拿到数据。
        refreshSubjects()
        syncPickerOnShow()
        refreshWeekCycle()
        refreshDailyEntries()
        resetToFirstPage()
    }
    // ── 数据刷新 ────────────────────────────────────────────────────────
    function refreshSubjects() {
        subjects = ClassSwapManager.getAllSubjects() || []
    }
    function refreshDailyEntries() {
        dailyEntries = ClassSwapManager.getDayEntries(selectedDayOfWeek, selectedWeekCycle) || []
    }
    function refreshWeekCycle() {
        maxWeekCycle = ClassSwapManager.getMaxWeekCycle()
        if (selectedWeekCycle < 1 || selectedWeekCycle > maxWeekCycle)
            selectedWeekCycle = 1
    }
    function syncPickerOnShow() {
        if (ClassSwapManager.hasTodaySwaps()) {
            selectedDayOfWeek = ClassSwapManager.getPreferredDayOfWeek()
            selectedWeekCycle = ClassSwapManager.getPreferredWeekOfCycle()
        } else {
            selectedDayOfWeek = ClassSwapManager.getCurrentDayOfWeek()
            selectedWeekCycle = ClassSwapManager.getCurrentWeekOfCycle()
        }
    }
    function onWeekCyclePicked(index) {
        if (pickerSyncing || index < 0 || index >= weekCycleOptions.length)
            return
        const value = weekCycleOptions[index].value
        if (value === selectedWeekCycle)
            return
        applyPicker(selectedDayOfWeek, value)
    }
    function onDayOfWeekPicked(day) {
        if (day === selectedDayOfWeek)
            return
        applyPicker(day, selectedWeekCycle)
    }
    // 切换星期/周次时，把所选时间线立即投射到今天，与旧版换课窗口一致。
    function applyPicker(day, week) {
        selectedDayOfWeek = day
        selectedWeekCycle = week
        // Picker changes are preview-only. Do not write temporary overrides
        // until the user confirms a swap/replacement on page 2.
        clearSource()
        refreshDailyEntries()
    }
    // ── 选择 ────────────────────────────────────────────────────────────
    function selectSource(entry) {
        if (!entry || !entry.id)
            return
        if (sourceEntryId === entry.id) {
            clearSource()
            return
        }
        sourceEntryId = entry.id
        sourceSubjectId = entry.subjectId || ""
        sourceSubjectName = entry.subjectName || entry.title || ""
    }
    function selectTarget(entry) {
        if (!entry || !entry.id)
            return
        if (targetEntryId === entry.id) {
            clearTarget()
            return
        }
        targetEntryId = entry.id
        targetSubjectName = entry.subjectName || entry.title || ""
    }
    function selectSubject(subjectId, subjectName) {
        if (pickedSubjectId === subjectId) {
            pickedSubjectId = ""
            pickedSubjectName = ""
            return
        }
        pickedSubjectId = subjectId
        pickedSubjectName = subjectName
    }
    function switchTargetMode(mode) {
        if (targetMode === mode)
            return
        targetMode = mode
        clearTarget()
    }
    function clearSource() {
        sourceEntryId = ""
        sourceSubjectId = ""
        sourceSubjectName = ""
        clearTarget()
    }
    function clearTarget() {
        targetEntryId = ""
        targetSubjectName = ""
        pickedSubjectId = ""
        pickedSubjectName = ""
    }
    // ── 分页导航 ────────────────────────────────────────────────────────
    function resetToFirstPage() {
        normalPageExit.stop()
        navigationPending = false
        pendingPage = -1
        currentPage = 0
        clearSource()
        targetMode = "swap"
        if (pageStack.depth > 1)
            pageStack.pop(pageStack.get(0), StackView.Immediate)
        if (pageStack.currentItem) {
            pageStack.currentItem.x = 0
            pageStack.currentItem.opacity = 1
        }
    }
    function switchTo(page) {
        if (pageStack.busy || navigationPending || page < 0 || page > 1
                || page === currentPage)
            return
        pendingPage = page
        normalExitDirection = page > currentPage ? -1 : 1
        navigationPending = true
        normalPageExit.start()
    }
    function finishNavigation() {
        const page = pendingPage
        pendingPage = -1
        navigationPending = false
        if (page > currentPage)
            pageStack.push(pageChooseTarget)
        else
            pageStack.pop()
        currentPage = page
    }
    // 取消：第一页直接关闭，第二页退回上一步重新选择课程。
    function cancelStep() {
        if (currentPage === 0)
            WindowManager.closeClassSwap()
        else
            switchTo(0)
    }
    function commit() {
        if (currentPage === 0) {
            if (canCommit)
                switchTo(1)
            return
        }
        const success = targetMode === "swap" ? applySwap() : applyReplace()
        if (success)
            WindowManager.closeClassSwap()
    }
    function applySwap() {
        if (!sourceEntryId || !targetEntryId)
            return false
        return ClassSwapManager.swapTwoEntries(
            sourceEntryId, targetEntryId, selectedDayOfWeek, selectedWeekCycle)
    }
    function applyReplace() {
        if (!sourceEntryId || !pickedSubjectId)
            return false
        return ClassSwapManager.replaceEntry(
            sourceEntryId, pickedSubjectId, selectedDayOfWeek, selectedWeekCycle)
    }

    // ── 面板 / Panel ────────────────────────────────────────────────────
    Item {
        id: panelRoot
        anchors.centerIn: parent
        width: classSwapWindow.dialogWidth
        height: classSwapWindow.dialogHeight

        // 投影 / Elevation
        Rectangle {
            id: shadowSource
            anchors.fill: parent
            radius: classSwapWindow.dialogRadius
            color: Theme.currentTheme.colors.backgroundColor

            layer.enabled: true
            layer.effect: Shadow {
                // 投影空间有限，使用较小的投影样式，避免被窗口边缘裁切。
                style: "flyout"
                source: shadowSource
            }
        }

        // 对话框底板 / Dialog base (fill & stroke)
        Rectangle {
            anchors.fill: parent
            radius: classSwapWindow.dialogRadius
            color: Theme.currentTheme.colors.backgroundColor
            border.width: 1
            border.color: Qt.alpha("#757575", 0.4)
        }

        ColumnLayout {
            id: panel
            anchors.fill: parent
            spacing: 0

            // ── 标题栏 / Title bar ────────────────────────────────────────
            Rectangle {
                id: titleBar
                Layout.fillWidth: true
                Layout.preferredHeight: classSwapWindow.titleBarHeight
                color: Theme.currentTheme.colors.cardTertiaryColor
                topLeftRadius: classSwapWindow.dialogRadius
                topRightRadius: classSwapWindow.dialogRadius

                Icon {
                    id: titleBarIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    size: 16
                    source: PathManager.images("logo.png")
                }

                Text {
                    anchors.left: titleBarIcon.right
                    anchors.leftMargin: 12
                    anchors.right: closeButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    typography: Typography.Caption
                    text: classSwapWindow.title
                    elide: Text.ElideRight
                }

                // 拖动标题栏移动窗口（原生拖动，支持 Windows 贴边）。
                MouseArea {
                    id: titleBarDragArea
                    anchors.fill: parent

                    property real pressX: 0
                    property real pressY: 0
                    property bool fallbackMoving: false

                    onPressed: (mouse) => {
                        pressX = mouse.x
                        pressY = mouse.y
                        fallbackMoving = !classSwapWindow.startSystemMove()
                    }
                    onReleased: fallbackMoving = false
                    onPositionChanged: (mouse) => {
                        if (!fallbackMoving)
                            return
                        classSwapWindow.x += mouse.x - pressX
                        classSwapWindow.y += mouse.y - pressY
                    }
                }

                // 关闭按钮 / Close button：样式与 RinUI 窗口标题栏的关闭按钮一致
                // （悬停变红），声明在拖动区域之后，优先接收点击。
                // 不复用 RinUI 的 CtrlBtn：它内部依赖 TitleBar 声明的 window 属性，
                // 单独使用会抛 "ReferenceError: window is not defined"。
                Item {
                    id: closeButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: 48
                    height: classSwapWindow.titleBarHeight

                    readonly property bool hovered: closeHoverHandler.hovered
                    readonly property bool pressed: closeMouseArea.pressed

                    Rectangle {
                        anchors.fill: parent
                        // 贴住右上角，随面板圆角收边。
                        topRightRadius: classSwapWindow.dialogRadius
                        color: (closeButton.hovered || closeButton.pressed)
                            ? Theme.currentTheme.colors.captionCloseColor
                            : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 100; easing.type: Easing.InOutQuad }
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        size: 16
                        icon: "ic_fluent_dismiss_20_regular"
                        color: (closeButton.hovered || closeButton.pressed)
                            ? Theme.currentTheme.colors.captionCloseTextColor
                            : Theme.currentTheme.colors.textColor
                    }

                    ToolTip {
                        parent: closeButton
                        delay: 500
                        visible: closeButton.hovered
                        text: qsTr("Close")
                    }

                    HoverHandler {
                        id: closeHoverHandler
                        acceptedDevices: PointerDevice.Mouse
                    }

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        onClicked: classSwapWindow.close()
                    }
                }
            }

            // ── 内容 / Content ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.currentTheme.colors.cardTertiaryColor

                StackView {
                    id: pageStack
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    clip: true
                    initialItem: pagePickCourse
                    pushEnter: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "x"
                                from: pageStack.width * 0.25
                                to: 0
                                duration: 220
                                easing.type: Easing.Bezier
                                easing.bezierCurve: [0, 0, 0, 1, 1, 1]
                            }
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    pushExit: Transition {
                        PropertyAction { property: "x"; value: -pageStack.width * 0.25 }
                        PropertyAction { property: "opacity"; value: 0 }
                    }
                    popEnter: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "x"
                                from: -pageStack.width * 0.25
                                to: 0
                                duration: 220
                                easing.type: Easing.Bezier
                                easing.bezierCurve: [0, 0, 0, 1, 1, 1]
                            }
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 180
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    popExit: Transition {
                        PropertyAction { property: "x"; value: pageStack.width * 0.25 }
                        PropertyAction { property: "opacity"; value: 0 }
                    }
                }
            }

            // 分隔线 / Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.currentTheme.colors.cardBorderColor
            }

            // ── 按钮区 / Button grid ─────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 80

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    spacing: 8

                    // 第一页取消关闭，第二页返回重选。
                    Button {
                        Layout.fillWidth: true
                        text: classSwapWindow.currentPage === 0 ? qsTr("Cancel") : qsTr("Back")
                        onClicked: classSwapWindow.cancelStep()
                    }

                    Button {
                        Layout.fillWidth: true
                        highlighted: true
                        enabled: classSwapWindow.canCommit
                        text: classSwapWindow.commitLabel
                        onClicked: classSwapWindow.commit()
                    }
                }
            }
        }
    }

    // 星期选择使用独占按钮组，互斥由 ButtonGroup 负责。
    ButtonGroup {
        id: weekdayGroup
        exclusive: true
    }
    // ── 第一页：选择课程 ────────────────────────────────────────────────
    Component {
        id: pagePickCourse
        Item {
            id: pagePickRoot

            ClassSwapTimeline {
                anchors.fill: parent
                header: weekPicker
                entries: classSwapWindow.dailyEntries
                selectedId: classSwapWindow.sourceEntryId
                onEntryClicked: function(entry, index) {
                    classSwapWindow.selectSource(entry)
                }
            }
            // 星期 + 周次选择器，作为时间线的 header 插槽内容。
            Component {
                id: weekPicker
                ColumnLayout {
                    id: weekPickerRoot
                    spacing: 12

                    // The picker ids live in this component, so the reverse
                    // sync (window state -> widget) has to live here too.
                    function syncWeekday() {
                        const day = classSwapWindow.selectedDayOfWeek
                        if (day < 1 || day > 7) {
                            weekdayGroup.checkedButton = null
                            return
                        }
                        const pill = weekdayPills.itemAt(day - 1)
                        if (pill && !pill.checked)
                            weekdayGroup.checkedButton = pill
                    }

                    function syncWeekCycle() {
                        const options = classSwapWindow.weekCycleOptions
                        let index = -1
                        for (let i = 0; i < options.length; ++i) {
                            if (options[i].value === classSwapWindow.selectedWeekCycle) {
                                index = i
                                break
                            }
                        }
                        if (index < 0 || weekCyclePicker.currentIndex === index)
                            return
                        classSwapWindow.pickerSyncing = true
                        weekCyclePicker.currentIndex = index
                        classSwapWindow.pickerSyncing = false
                    }

                    Component.onCompleted: {
                        syncWeekday()
                        syncWeekCycle()
                    }

                    Connections {
                        target: classSwapWindow
                        function onSelectedDayOfWeekChanged() { weekPickerRoot.syncWeekday() }
                        function onSelectedWeekCycleChanged() { weekPickerRoot.syncWeekCycle() }
                        function onMaxWeekCycleChanged() { weekPickerRoot.syncWeekCycle() }
                    }

                    Text {
                        Layout.fillWidth: true
                        typography: Typography.Body
                        wrapMode: Text.WordWrap
                        text: qsTr("Pick a course to swap with another course of the day, "
                                  + "or to replace its subject.")
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        RowLayout {
                            spacing: 6
                            Repeater {
                                id: weekdayPills
                                model: 7
                                PillButton {
                                    ButtonGroup.group: weekdayGroup
                                    // ISO weekday
                                    property int weekday: index + 1
                                    text: classSwapWindow.weekdayNames[index]
                                    onClicked: classSwapWindow.onDayOfWeekPicked(weekday)
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        RowLayout {
                            spacing: 0
                            visible: classSwapWindow.showWeekCycleSelector
                            Text {
                                visible: text.length > 0
                                text: classSwapWindow.weekCyclePrefix
                                Layout.alignment: Qt.AlignVCenter
                            }
                            ComboBox {
                                id: weekCyclePicker
                                Layout.preferredWidth: 92
                                Layout.alignment: Qt.AlignVCenter
                                model: classSwapWindow.weekCycleOptions
                                textRole: "text"
                                valueRole: "value"
                                onActivated: classSwapWindow.onWeekCyclePicked(currentIndex)
                            }
                            Text {
                                visible: text.length > 0
                                text: classSwapWindow.weekCycleSuffix
                                Layout.leftMargin: classSwapWindow.parityCycle ? 6 : 0
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
    // ── 第二页：选择目标 ────────────────────────────────────────────────
    Component {
        id: pageChooseTarget
        Item {
            id: pageTargetRoot
            // 精简版 SubjectClip：只保留学科图标与名字，选中时加主导色边框。
            Component {
                id: subjectCardComponent
                Clip {
                    id: subjectCard
                    readonly property string subjectId: modelData && modelData.id
                        ? String(modelData.id) : ""
                    readonly property string subjectName: modelData && modelData.name
                        ? String(modelData.name) : ""
                    readonly property string subjectIcon: modelData && modelData.icon
                        ? modelData.icon : ""
                    readonly property color subjectBaseColor: (modelData && modelData.color)
                        ? modelData.color : Colors.proxy.systemNeutralColor
                    readonly property bool isSelected: classSwapWindow.pickedSubjectId === subjectId
                    readonly property bool isDisabled: classSwapWindow.sourceSubjectId.length > 0
                        && classSwapWindow.sourceSubjectId === subjectId
                    width: 150
                    height: 48
                    radius: 6
                    enabled: !isDisabled
                    opacity: isDisabled ? 0.45 : 1
                    onClicked: {
                        if (isDisabled)
                            return
                        classSwapWindow.selectSubject(subjectId, subjectName)
                    }
                    // 选中高亮使用主导色边框：Clip 的 border 别名与 Frame 内部绑定冲突，
                    // 因此与 SubjectClip 一样用覆盖层实现。
                    Rectangle {
                        anchors.fill: parent
                        z: 1
                        radius: subjectCard.radius
                        color: "transparent"
                        border.width: subjectCard.isSelected ? 1 : 0
                        border.color: Colors.proxy.primaryColor
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 12
                        spacing: 10
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 26
                            Layout.preferredHeight: 26
                            radius: width / 2
                            color: subjectCard.iconBackgroundColor
                            Icon {
                                anchors.centerIn: parent
                                size: 16
                                color: subjectCard.iconColor
                                name: subjectCard.subjectIcon.length > 0
                                    ? subjectCard.subjectIcon
                                    : "ic_fluent_hexagon_three_20_regular"
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: subjectCard.subjectName
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            verticalAlignment: Text.AlignVCenter
                            color: Colors.proxy.textColor
                        }
                    }
                    // 与 SubjectClip / ScheduleCourseCard 一致的色彩推导
                    readonly property bool darkTheme: Theme.currentTheme
                        ? Theme.currentTheme.isDark : false
                    readonly property real surfaceLuminance: darkTheme ? 0.05 : 0.72
                    readonly property real textLuminance: darkTheme ? 0.60 : 0.05
                    readonly property color iconBackgroundColor: CoursePalette.atLuminance(
                        subjectBaseColor, surfaceLuminance
                    )
                    readonly property color iconColor: CoursePalette.atLuminance(
                        subjectBaseColor, textLuminance
                    )
                }
            }
            function syncMode() {
                if (classSwapWindow.targetMode === "swap")
                    swapModePill.checked = true
                else
                    replaceModePill.checked = true
            }
            Component.onCompleted: syncMode()
            Connections {
                target: classSwapWindow
                function onTargetModeChanged() { pageTargetRoot.syncMode() }
            }
            ColumnLayout {
                anchors.fill: parent
                spacing: 12
                Text {
                    Layout.fillWidth: true
                    typography: Typography.Body
                    wrapMode: Text.WordWrap
                    text: qsTr("Now pick another course of the day to swap with, "
                              + "or a subject to replace it with.")
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Item { Layout.fillWidth: true }
                    PillButton {
                        id: swapModePill
                        icon.name: "ic_fluent_arrow_swap_20_regular"
                        ButtonGroup.group: targetModeGroup
                        text: qsTr("Swap with another course")
                        onClicked: classSwapWindow.switchTargetMode("swap")
                    }
                    PillButton {
                        id: replaceModePill
                        icon.name: "ic_fluent_bookmark_multiple_20_regular"
                        ButtonGroup.group: targetModeGroup
                        text: qsTr("Replace with a subject")
                        onClicked: classSwapWindow.switchTargetMode("replace")
                    }
                    Item { Layout.fillWidth: true }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    // 交换模式：复用第一页的时间线，但禁用源课程与同科目课程。
                    ClassSwapTimeline {
                        anchors.fill: parent
                        visible: classSwapWindow.targetMode === "swap"
                        entries: classSwapWindow.dailyEntries
                        selectedId: classSwapWindow.targetEntryId
                        disabledIds: classSwapWindow.disabledEntryIds
                        onEntryClicked: function(entry, index) {
                            classSwapWindow.selectTarget(entry)
                        }
                    }
                    // 替换模式：精简学科卡片网格。
                    Flickable {
                        anchors.fill: parent
                        visible: classSwapWindow.targetMode === "replace"
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        contentWidth: width
                        contentHeight: subjectFlow.height
                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.vertical: ScrollBar {}
                        Flow {
                            id: subjectFlow
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: classSwapWindow.subjects
                                delegate: subjectCardComponent
                            }
                        }
                    }
                }
            }
            ButtonGroup {
                id: targetModeGroup
                exclusive: true
            }
        }
    }
}
