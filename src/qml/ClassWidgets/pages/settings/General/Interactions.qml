import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentPage {
    id: root
    title: qsTr("Interactions & Actions")

    function hidePreviewSource(name) {
        return PathManager.images("tutorial/" + name + (Theme.isDark() ? "-dark.png" : "-light.png"))
    }

    // ---- “永不自动隐藏的课程”（在弹窗中勾选，按课程名称全局生效） ----
    // Configs.data 里的列表在 QML 侧不一定是 JS 数组（Array.isArray 为 false），
    // 需按“类数组”安全展开；读取 Configs.data 也让计数随配置变更刷新。
    readonly property int exemptCount: {
        const a = Configs.data.interactions.hide.no_hide_subjects
        if (Array.isArray(a)) return a.length
        let count = 0
        if (a && typeof a.length === "number") {
            for (let i = 0; i < a.length; i++) {
                if (String(a[i] || "").trim()) count++
            }
        }
        return count
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Widgets")
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_tap_single_20_regular"
            title: qsTr("Tap Action")
            description: qsTr("Choose whether tapping a widget hides it, switches to mini mode, or opens a floating widget")
            expanded: true

            action: Switch {
                id: tapToHideSwitch
                enabled: !Configs.isKeyLocked("interactions.hide.clicked") && !hoverFadeSwitch.checked
                onCheckedChanged: Configs.set("interactions.hide.clicked", checked)
                Component.onCompleted: checked = Configs.data.interactions.hide.clicked
            }

            ButtonGroup {
                id: hideModeGroup
            }

            SettingItem {
                enabled: tapToHideSwitch.checked && !hoverFadeSwitch.checked
                RowLayout {
                    // Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: [
                            {
                                "name": qsTr("Hide"),
                                "value": "hide",
                                "preview": "hide_default"
                            },
                            {
                                "name": qsTr("Mini Mode"),
                                "value": "mini_mode",
                                "preview": "hide_mini"
                            },
                            {
                                "name": qsTr("Floating Widget"),
                                "value": "floating_widget",
                                "preview": "hide_floating"
                            }
                        ]

                        delegate: ColumnLayout {
                            // Layout.fillWidth: true
                            spacing: 4

                            Image {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 128
                                source: root.hidePreviewSource(modelData.preview)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            RadioButton {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                checked: Configs.data.interactions.tapped_action === modelData.value
                                enabled: !Configs.isKeyLocked("interactions.tapped_action")
                                ButtonGroup.group: hideModeGroup
                                onClicked: Configs.set("interactions.tapped_action", modelData.value)
                            }
                        }
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Hover fade")
            description: qsTr(
                "Hover to make the widget transparent and let clicks go through, move away to bring it back"
            )
            icon.name: "ic_fluent_cursor_20_regular"

            Switch {
                id: hoverFadeSwitch
                enabled: !Configs.isKeyLocked("interactions.hover_fade")
                onCheckedChanged: Configs.set("interactions.hover_fade", checked)
                Component.onCompleted: checked = Configs.data.interactions.hover_fade
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Automations")
        }

        SettingExpander {
            Layout.fillWidth: true
            title: qsTr("Automatic hide behavior")
            icon.name: "ic_fluent_slide_hide_20_regular"
            description: qsTr("Choose what happens when an automatic hide rule is triggered")

            action: ComboBox {
                id: modeSelector
                Layout.preferredWidth: 180
                model: ListModel {
                    ListElement { text: qsTr("Hide Widgets"); value: "hide" }
                    ListElement { text: qsTr("Switch to mini mode"); value: "mini_mode" }
                    ListElement { text: qsTr("Floating widget"); value: "floating_widget" }
                }
                textRole: "text"
                valueRole: "value"
                enabled: !Configs.isKeyLocked("interactions.hide.action")
                onCurrentValueChanged: if (focus) Configs.set("interactions.hide.action", currentValue) // !important "focus"!!!
                Component.onCompleted: currentIndex = indexOfValue(Configs.data.interactions.hide.action)
            }

            SettingItem {
                ColumnLayout {
                    Layout.fillWidth: true
                    CheckBox {
                        Layout.fillWidth: true
                        text: qsTr("Hide when in class")
                        enabled: !Configs.isKeyLocked("interactions.hide.in_class")
                        onCheckedChanged: Configs.set("interactions.hide.in_class", checked)
                        Component.onCompleted: checked = Configs.data.interactions.hide.in_class
                    }
                    CheckBox {
                        Layout.fillWidth: true
                        text: qsTr("Hide when a window is maximized")
                        enabled: !Configs.isKeyLocked("interactions.hide.maximized") && Qt.platform.os === "windows"
                        onCheckedChanged: Configs.set("interactions.hide.maximized", checked)
                        Component.onCompleted: checked = Configs.data.interactions.hide.maximized
                    }
                    CheckBox {
                        Layout.fillWidth: true
                        text: qsTr("Hide when a window enters fullscreen")
                        enabled: !Configs.isKeyLocked("interactions.hide.fullscreen") && Qt.platform.os === "windows"
                        onCheckedChanged: Configs.set("interactions.hide.fullscreen", checked)
                        Component.onCompleted: checked = Configs.data.interactions.hide.fullscreen
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_class_20_regular"
            title: qsTr("永不自动隐藏这些课程")
            description: qsTr("从课表中挑选课程。它们永远不会被自动隐藏（无论是上课、窗口最大化还是全屏触发）。")

            Button {
                id: exemptButton
                text: root.exemptCount > 0
                    ? qsTr("选择课程（%1）").arg(root.exemptCount)
                    : qsTr("选择课程")
                enabled: !Configs.isKeyLocked("interactions.hide.no_hide_subjects")
                onClicked: exemptPopup.open()
            }
        }
    }

    NeverHideCoursesPopup {
        id: exemptPopup
    }
}
