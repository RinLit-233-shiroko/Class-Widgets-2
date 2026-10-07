import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components
import QtQuick.Window as QQW

// 问题报告 / Problem Report
QQW.Window {
    id: problemReportWindow

    // 普通窗口：可拖动、可被 Alt+Tab / 任务栏选中，且不置顶。
    visible: false
    title: qsTr("Problem Report")
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // 面板四周留出的投影空间 / room for the drop shadow
    readonly property int shadowMargin: 32
    readonly property int dialogWidth: Math.min(700, Math.max(320, Screen.width - 96))
    readonly property int dialogRadius: Theme.currentTheme.appearance.windowRadius
    // 详细信息默认折叠 / Technical details start collapsed
    property bool detailsExpanded: false

    width: panelRoot.width + shadowMargin * 2
    height: panelRoot.height + shadowMargin * 2

    // 展开 / 收起时保持不变，从中心向上下两侧expand
    property real centerY: 0
    // 内部重定位标记，避免 onYChanged 把程序自己设的 y 又当成用户拖动。
    property bool recentering: false

    function moveToCenter(force) {
        if (force || problemReportWindow.centerY === 0)
            problemReportWindow.centerY = Screen.virtualY + Screen.height / 2
        problemReportWindow.recentering = true
        problemReportWindow.y = Math.round(problemReportWindow.centerY - problemReportWindow.height / 2)
        problemReportWindow.recentering = false
    }

    onHeightChanged: moveToCenter(false)

    onYChanged: {
        if (!problemReportWindow.recentering)
            problemReportWindow.centerY = problemReportWindow.y + problemReportWindow.height / 2
    }

    onVisibleChanged: {
        if (problemReportWindow.visible)
            moveToCenter(true)
    }

    Component.onCompleted: {
        // 首次显示时居中，之后用户可以自由拖动。
        problemReportWindow.x = Math.round((Screen.width - problemReportWindow.width) / 2) + Screen.virtualX
        moveToCenter(true)
    }

    onClosing: function(event) {
        // 必须由用户明确选择后续操作，不允许直接关掉报告。
        event.accepted = false
    }

    Connections {
        target: ProblemReportBridge

        function onReportChanged() {
            problemReportWindow.detailsExpanded = false
        }
    }

    // 运行环境条目：图标 + （标题 / 值）
    component EnvironmentItem: RowLayout {
        id: environmentItem

        property string iconName: ""
        property string label: ""
        property string value: ""

        spacing: 12
        Layout.fillWidth: true

        Icon {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 16
            Layout.minimumWidth: 16
            Layout.maximumWidth: 16
            size: 16
            icon: environmentItem.iconName
            color: Theme.currentTheme.colors.textColor
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 0

            Text {
                Layout.fillWidth: true
                typography: Typography.Caption
                color: Theme.currentTheme.colors.textSecondaryColor
                text: environmentItem.label
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                typography: Typography.Body
                text: environmentItem.value
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
            }
        }
    }

    Item {
        id: panelRoot
        anchors.centerIn: parent
        width: problemReportWindow.dialogWidth
        height: panel.implicitHeight

        // 投影 / Elevation
        Rectangle {
            id: shadowSource
            anchors.fill: parent
            radius: problemReportWindow.dialogRadius
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
            radius: problemReportWindow.dialogRadius
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
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: Theme.currentTheme.colors.cardTertiaryColor
                topLeftRadius: problemReportWindow.dialogRadius
                topRightRadius: problemReportWindow.dialogRadius

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
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    typography: Typography.Caption
                    text: qsTr("Problem Report - Class Widgets")
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
                        fallbackMoving = !problemReportWindow.startSystemMove()
                    }
                    onReleased: fallbackMoving = false
                    onPositionChanged: (mouse) => {
                        if (!fallbackMoving)
                            return
                        problemReportWindow.x += mouse.x - pressX
                        problemReportWindow.y += mouse.y - pressY
                    }
                }
            }

            // ── 内容 / Content ───────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                // 内容区高度 = 内容 + 上下内边距（8 / 23）
                implicitHeight: contentLayout.implicitHeight + 8 + 23
                color: Theme.currentTheme.colors.cardTertiaryColor

                ColumnLayout {
                    id: contentLayout
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: 8
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    anchors.bottomMargin: 23
                    spacing: 12

                    // 标题 / Headline
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32

                        Image {
                            id: headlineIcon
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 32
                            source: PathManager.images("icons/cw2_problem_report.png")
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                        }

                        Text {
                            anchors.left: headlineIcon.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            typography: Typography.Subtitle
                            text: qsTr("Class Widgets ran into a problem  (>_<)")
                        }
                    }

                    // 说明 / Body
                    Text {
                        Layout.fillWidth: true
                        typography: Typography.Body
                        text: qsTr(
                            "Sorry about that - Class Widgets ran into a problem it could not solve " +
                            "on its own and had to stop. Your class data has been saved automatically, " +
                            "so nothing is lost.\n" +
                            "You can try restarting. If you suspect a plugin or theme is involved, " +
                            "restart in safe mode to find the problematic component."
                        )
                    }

                    // ── 智能检测 / Smart detection ─────────────────────────
                    // 只有规则判定崩溃来自第三方插件时才出现。
                    ColumnLayout {
                        id: smartDetection
                        Layout.fillWidth: true
                        spacing: 8
                        visible: ProblemReportBridge.pluginDetected

                        Text {
                            typography: Typography.BodyStrong
                            text: qsTr("Smart detection")
                        }

                        Text {
                            Layout.fillWidth: true
                            typography: Typography.Body
                            wrapMode: Text.Wrap
                            text: qsTr(
                                "Class Widgets noticed that this problem was caused by the plugin \"%1\". " +
                                "You can try disabling it and restarting right away."
                            ).arg(ProblemReportBridge.pluginName)
                        }

                        // 插件卡片：图标 + 名称 + 快捷禁用 / plugin card
                        Rectangle {
                            id: pluginCard
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            radius: Theme.currentTheme.appearance.smallRadius
                            color: Theme.currentTheme.colors.cardColor
                            border.width: 1
                            border.color: Theme.currentTheme.colors.cardBorderColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Rectangle {
                                    Layout.alignment: Qt.AlignVCenter
                                    width: 48
                                    height: 48
                                    radius: 12
                                    color: Theme.currentTheme.colors.controlColor
                                    border.width: 1
                                    border.color: Theme.currentTheme.colors.controlBorderColor

                                    Icon {
                                        id: pluginCardIcon
                                        anchors.fill: parent
                                        // 有插件图标时铺满卡片，回退到字体图标时留出边距。
                                        size: ProblemReportBridge.pluginIcon === "" ? 32 : 48
                                        source: ProblemReportBridge.pluginIcon
                                        name: ProblemReportBridge.pluginIcon === "" ? "ic_fluent_apps_add_in_20_filled" : ""
                                        opacity: ProblemReportBridge.pluginIcon === "" ? 0.5 : 1

                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            anchors.fill: parent
                                            maskSource: Rectangle {
                                                width: pluginCardIcon.width
                                                height: pluginCardIcon.height
                                                radius: 12
                                            }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        typography: Typography.Body
                                        text: ProblemReportBridge.pluginName
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        typography: Typography.Caption
                                        color: Theme.currentTheme.colors.textSecondaryColor
                                        text: qsTr("* High risk, disabling it is recommended")
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                    }
                                }

                                // 快捷禁用：点过一次就变「已禁用」，不可反悔。
                                Button {
                                    id: disablePluginButton
                                    readonly property bool done: ProblemReportBridge.pluginDisabled

                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.minimumWidth: 120

                                    // 未禁用时是强调色主按钮；禁用后回到普通按钮。
                                    highlighted: !done
                                    // 已禁用时不再接受点击（pluginDisableAvailable 也会变 false）。
                                    enabled: ProblemReportBridge.pluginDisableAvailable || done
                                    text: done ? qsTr("Disabled") : qsTr("Disable")
                                    icon.name: done ? "ic_fluent_checkmark_20_filled" : ""
                                    icon.width: 16
                                    icon.height: 16
                                    onClicked: ProblemReportBridge.disableDetectedPlugin()
                                }
                            }
                        }
                    }

                    // 查看详细情况 / Toggle technical details
                    Button {
                        id: detailsToggle
                        Layout.alignment: Qt.AlignLeft
                        flat: true
                        text: qsTr("View details")
                        icon.name: problemReportWindow.detailsExpanded ?  "ic_fluent_chevron_up_20_regular" : "ic_fluent_chevron_down_20_regular"
                        icon.width: 16
                        icon.height: 16

                        onClicked: problemReportWindow.detailsExpanded = !problemReportWindow.detailsExpanded
                    }

                    // 技术细节 / Technical detail (collapsed by default)
                    Item {
                        id: detailsArea
                        Layout.fillWidth: true
                        implicitHeight: problemReportWindow.detailsExpanded ? detailsLayout.implicitHeight : 0
                        // 折叠动画播放期间保持可见，动画结束后再隐藏。
                        visible: problemReportWindow.detailsExpanded || implicitHeight > 0
                        clip: true

                        Behavior on implicitHeight {
                            NumberAnimation { duration: Utils.animationSpeedExpander; easing.type: Easing.OutQuint }
                        }

                        ColumnLayout {
                            id: detailsLayout
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 8

                            // 运行环境 / Environment summary
                            // 田字格：两行两列 —— 系统 / 版本 / 运行时间 / 插件。
                            // 各列给出首选宽度（不够时才省略），多余空间按比例摊到两列。
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 12
                                rowSpacing: 10

                                EnvironmentItem {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 199
                                    iconName: "ic_fluent_desktop_20_regular"
                                    label: qsTr("Operating system")
                                    value: ProblemReportBridge.osName
                                }

                                EnvironmentItem {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 197
                                    iconName: "ic_fluent_apps_20_regular"
                                    label: qsTr("Class Widgets version")
                                    value: ProblemReportBridge.appVersion
                                }

                                EnvironmentItem {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 82
                                    iconName: "ic_fluent_history_20_regular"
                                    label: qsTr("Uptime")
                                    value: ProblemReportBridge.uptimeText
                                }

                                EnvironmentItem {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 123
                                    iconName: "ic_fluent_puzzle_piece_20_regular"
                                    label: qsTr("Installed plugins")
                                    value: ProblemReportBridge.pluginCount
                                }
                            }
                            // 堆栈信息 / Traceback
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 150

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.currentTheme.appearance.smallRadius
                                    color: Theme.currentTheme.colors.controlColor
                                    border.width: 1
                                    border.color: Theme.currentTheme.colors.controlBorderColor
                                }

                                ScrollableTextArea {
                                    id: tracebackScrollView
                                    objectName: "tracebackArea"
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    readOnly: true
                                    font.family: "Menlo, Consolas, Ubuntu Mono, Courier New, monospace"
                                    textFormat: TextEdit.PlainText
                                    wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                                    text: ProblemReportBridge.tracebackText
                                    // RinUI 0.4.4.1 的 ScrollableTextArea 写着
                                    // `implicitHeight: defaultHeight`，而 defaultHeight 并不存在，
                                    // 一旦有人读 implicitHeight 就报 ReferenceError。
                                    // 这里由 anchors 决定尺寸，所以把 implicitHeight 钉死以绕开该绑定。
                                    implicitHeight: 0
                                }

                                Button {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.top: parent.top
                                    anchors.topMargin: 10
                                    text: qsTr("Copy summary")
                                    icon.name: "ic_fluent_copy_20_regular"
                                    onClicked: ProblemReportBridge.copySummary()


                                    AcrylicBrush {
                                        sourceItem: tracebackScrollView
                                        z: -99
                                    }
                                }
                            }
                        }
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

                    Button {
                        text: qsTr("Export logs")
                        icon.name: "ic_fluent_save_20_regular"
                        onClicked: ProblemReportBridge.exportLogs()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Ignore and continue")
                        flat: true
                        icon.name: "ic_fluent_play_20_regular"
                        onClicked: ProblemReportBridge.ignoreAndContinue()
                    }

                    SplitButton {
                        id: restartButton
                        text: qsTr("Restart")
                        onAccepted: ProblemReportBridge.restartNormally()

                        MenuItem {
                            text: qsTr("Restart in safe mode")
                            icon.name: "ic_fluent_shield_20_regular"
                            onTriggered: ProblemReportBridge.restartInSafeMode()
                        }

                        MenuItem {
                            text: qsTr("Restart")
                            icon.name: "ic_fluent_arrow_clockwise_20_regular"
                            onTriggered: ProblemReportBridge.restartNormally()
                        }
                    }
                }
            }
        }
    }
}
