import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

FluentPage {
    id: root
    title: qsTr("自动化")

    property var profilesData: []
    property var selectedProfile: null
    property string selectedProfileId: ""
    readonly property var triggerKeys: [
        "app_started", "app_exiting", "process_started", "process_running",
        "process_exited", "class_started", "break_started", "school_dismissal",
        "noon_dismissal"
    ]
    readonly property var triggerNames: [
        qsTr("应用启动时"), qsTr("应用退出时"), qsTr("进程启动时"),
        qsTr("进程运行时"), qsTr("进程退出时"), qsTr("上课时"),
        qsTr("课间时"), qsTr("放学时"), qsTr("中午放学时")
    ]
    readonly property var actionKeys: ["notification", "run_program"]
    readonly property var actionNames: [qsTr("显示提醒"), qsTr("运行程序")]

    function indexFor(values, value) {
        const index = values.indexOf(value)
        return index >= 0 ? index : 0
    }

    function refreshProfiles() {
        profilesData = AppCentral.automationProfiles.profiles
        if (selectedProfileId === "" && profilesData.length > 0)
            selectedProfileId = profilesData[0].id
        selectedProfile = null
        for (let index = 0; index < profilesData.length; index++) {
            if (profilesData[index].id === selectedProfileId) {
                selectedProfile = profilesData[index]
                break
            }
        }
        if (selectedProfile === null && profilesData.length > 0) {
            selectedProfileId = profilesData[0].id
            selectedProfile = profilesData[0]
        }
    }

    Component.onCompleted: refreshProfiles()

    Connections {
        target: AppCentral.automationProfiles
        function onChanged() { root.refreshProfiles() }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            typography: Typography.BodyStrong
            text: qsTr("自动化")
        }

        Text {
            Layout.fillWidth: true
            color: Colors.proxy.textSecondaryColor
            wrapMode: Text.Wrap
            text: qsTr("自动化配置文件保存在本机，默认未启用。每个配置文件可以包含多条“当……时，执行……”规则；运行程序动作只会启动你明确配置的本地可执行文件和参数。")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_folder_multiple_20_regular"
            title: qsTr("自动化配置文件")
            description: qsTr("可创建多个相互独立的配置文件；新建文件默认关闭。")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ComboBox {
                        id: profileSelector
                        Layout.fillWidth: true
                        textRole: "name"
                        model: root.profilesData
                        currentIndex: root.indexFor(
                            root.profilesData.map(function(item) { return item.id }),
                            root.selectedProfileId
                        )
                        onActivated: {
                            if (currentIndex >= 0 && currentIndex < root.profilesData.length) {
                                root.selectedProfileId = root.profilesData[currentIndex].id
                                root.refreshProfiles()
                            }
                        }
                    }

                    Button {
                        text: qsTr("新建")
                        onClicked: {
                            root.selectedProfileId = AppCentral.automationProfiles.createProfile(qsTr("新自动化配置"))
                            root.refreshProfiles()
                        }
                    }

                    Button {
                        text: qsTr("删除")
                        enabled: root.selectedProfile !== null
                        onClicked: {
                            AppCentral.automationProfiles.deleteProfile(root.selectedProfileId)
                            root.selectedProfileId = ""
                            root.refreshProfiles()
                        }
                    }
                }

                Text {
                    visible: root.profilesData.length === 0
                    color: Colors.proxy.textSecondaryColor
                    text: qsTr("尚未创建自动化配置文件。")
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            visible: root.selectedProfile !== null
            icon.name: "ic_fluent_branch_compare_20_regular"
            title: root.selectedProfile ? root.selectedProfile.name : qsTr("自动化配置")
            description: qsTr("关闭配置文件后，文件中的全部规则均不会执行。")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Switch {
                    id: profileEnabled
                    text: qsTr("启用此自动化配置文件")
                    checked: root.selectedProfile ? root.selectedProfile.enabled : false
                    onToggled: AppCentral.automationProfiles.setProfileEnabled(root.selectedProfileId, checked)
                }

                TextField {
                    id: profileName
                    Layout.fillWidth: true
                    placeholderText: qsTr("配置文件名称")
                    text: root.selectedProfile ? root.selectedProfile.name : ""
                    onEditingFinished: AppCentral.automationProfiles.updateProfile(
                        root.selectedProfileId, text
                    )
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            visible: root.selectedProfile !== null
            icon.name: "ic_fluent_flowchart_20_regular"
            title: qsTr("自动化规则")
            description: qsTr("每条规则均可单独关闭，可配置多个触发条件对应的动作。")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: qsTr("添加自动化")
                    onClicked: AppCentral.automationProfiles.addRule(root.selectedProfileId)
                }

                Repeater {
                    model: root.selectedProfile ? root.selectedProfile.rules : []

                    delegate: Frame {
                        required property var modelData
                        readonly property var rule: modelData
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Switch {
                                    id: ruleEnabled
                                    checked: rule.enabled
                                    onToggled: AppCentral.automationProfiles.setRuleEnabled(
                                        root.selectedProfileId, rule.id, checked
                                    )
                                }

                                TextField {
                                    id: ruleName
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("自动化名称")
                                    text: rule.name
                                    onEditingFinished: AppCentral.automationProfiles.updateRule(
                                        root.selectedProfileId, rule.id, text,
                                        triggerType.automationValue, processName.text,
                                        cooldown.value
                                    )
                                }

                                Button {
                                    text: qsTr("删除规则")
                                    onClicked: AppCentral.automationProfiles.deleteRule(root.selectedProfileId, rule.id)
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text { text: qsTr("当") }
                                ComboBox {
                                    id: triggerType
                                    Layout.fillWidth: true
                                    model: root.triggerNames
                                    currentIndex: root.indexFor(root.triggerKeys, rule.trigger.type)
                                    property string automationValue: root.triggerKeys[currentIndex]
                                    onActivated: AppCentral.automationProfiles.updateRule(
                                        root.selectedProfileId, rule.id, ruleName.text,
                                        automationValue, processName.text,
                                        cooldown.value
                                    )
                                }
                            }

                            TextField {
                                id: processName
                                Layout.fillWidth: true
                                visible: triggerType.automationValue === "process_started"
                                         || triggerType.automationValue === "process_running"
                                         || triggerType.automationValue === "process_exited"
                                placeholderText: qsTr("进程名，例如 PowerPoint.exe")
                                text: rule.trigger.process_name
                                onEditingFinished: AppCentral.automationProfiles.updateRule(
                                    root.selectedProfileId, rule.id, ruleName.text,
                                    triggerType.automationValue, text,
                                    cooldown.value
                                )
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text { text: qsTr("冷却时间") }
                                SpinBox {
                                    id: cooldown
                                    from: 0
                                    to: 86400
                                    value: rule.cooldown_seconds
                                    editable: true
                                    onValueModified: AppCentral.automationProfiles.updateRule(
                                        root.selectedProfileId, rule.id, ruleName.text,
                                        triggerType.automationValue, processName.text,
                                        value
                                    )
                                }
                                Text {
                                    text: qsTr("秒")
                                    color: Colors.proxy.textSecondaryColor
                                }
                                Item { Layout.fillWidth: true }
                            }

                            Text {
                                text: qsTr("执行以下动作：")
                                typography: Typography.BodyStrong
                            }

                            Button {
                                text: qsTr("添加动作")
                                onClicked: AppCentral.automationProfiles.addAction(root.selectedProfileId, rule.id)
                            }

                            Repeater {
                                model: rule.actions

                                delegate: Frame {
                                    required property var modelData
                                    readonly property var action: modelData
                                    Layout.fillWidth: true

                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            ComboBox {
                                                id: actionType
                                                Layout.fillWidth: true
                                                model: root.actionNames
                                                currentIndex: root.indexFor(root.actionKeys, action.type)
                                                property string automationValue: root.actionKeys[currentIndex]
                                                onActivated: AppCentral.automationProfiles.updateAction(
                                                    root.selectedProfileId, rule.id, action.id,
                                                    automationValue, actionTitle.text, actionMessage.text,
                                                    actionProgram.text, actionArguments.text, actionDuration.value
                                                )
                                            }

                                            Button {
                                                text: qsTr("删除动作")
                                                onClicked: AppCentral.automationProfiles.deleteAction(
                                                    root.selectedProfileId, rule.id, action.id
                                                )
                                            }
                                        }

                                        TextField {
                                            id: actionTitle
                                            Layout.fillWidth: true
                                            visible: actionType.automationValue === "notification"
                                            placeholderText: qsTr("提醒标题")
                                            text: action.title
                                            onEditingFinished: AppCentral.automationProfiles.updateAction(
                                                root.selectedProfileId, rule.id, action.id,
                                                actionType.automationValue, text, actionMessage.text,
                                                actionProgram.text, actionArguments.text, actionDuration.value
                                            )
                                        }

                                        TextArea {
                                            id: actionMessage
                                            Layout.fillWidth: true
                                            visible: actionType.automationValue === "notification"
                                            placeholderText: qsTr("提醒内容")
                                            text: action.message
                                            wrapMode: TextEdit.Wrap
                                            onFocusChanged: {
                                                if (!focus) {
                                                    AppCentral.automationProfiles.updateAction(
                                                        root.selectedProfileId, rule.id, action.id,
                                                        actionType.automationValue, actionTitle.text, text,
                                                        actionProgram.text, actionArguments.text, actionDuration.value
                                                    )
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            visible: actionType.automationValue === "notification"
                                            spacing: 8

                                            Text { text: qsTr("显示时长") }
                                            SpinBox {
                                                id: actionDuration
                                                from: 1000
                                                to: 60000
                                                stepSize: 1000
                                                value: action.duration_ms
                                                editable: true
                                                onValueModified: AppCentral.automationProfiles.updateAction(
                                                    root.selectedProfileId, rule.id, action.id,
                                                    actionType.automationValue, actionTitle.text, actionMessage.text,
                                                    actionProgram.text, actionArguments.text, value
                                                )
                                            }
                                            Text { text: qsTr("毫秒") }
                                            Item { Layout.fillWidth: true }
                                        }

                                        TextField {
                                            id: actionProgram
                                            Layout.fillWidth: true
                                            visible: actionType.automationValue !== "notification"
                                            placeholderText: qsTr("要运行的程序路径")
                                            text: action.program
                                            onEditingFinished: AppCentral.automationProfiles.updateAction(
                                                root.selectedProfileId, rule.id, action.id,
                                                actionType.automationValue, actionTitle.text, actionMessage.text,
                                                text, actionArguments.text, actionDuration.value
                                            )
                                        }

                                        TextField {
                                            id: actionArguments
                                            Layout.fillWidth: true
                                            visible: actionType.automationValue !== "notification"
                                            placeholderText: qsTr("程序参数；支持带引号的路径")
                                            text: action.arguments.join(" ")
                                            onEditingFinished: AppCentral.automationProfiles.updateAction(
                                                root.selectedProfileId, rule.id, action.id,
                                                actionType.automationValue, actionTitle.text, actionMessage.text,
                                                actionProgram.text, text, actionDuration.value
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_alert_20_regular"
            title: qsTr("状态与测试")
            description: qsTr("测试通知不会执行程序动作。")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    color: Colors.proxy.textSecondaryColor
                    wrapMode: Text.Wrap
                    text: AppCentral.automationProfiles.statusText
                }

                Button {
                    text: qsTr("发送测试提醒")
                    onClicked: AppCentral.automationProfiles.testNotification(
                        qsTr("自动化测试"), qsTr("这是一条自动化测试通知。")
                    )
                }
            }
        }
    }
}
