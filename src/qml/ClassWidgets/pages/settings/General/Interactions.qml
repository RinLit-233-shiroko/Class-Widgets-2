import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentPage {
    title: qsTr("Interactions & Actions")
    // id: generalPage

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Widgets")
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
                onCheckedChanged: Configs.set("interactions.hover_fade", checked)
                Component.onCompleted: checked = Configs.data.interactions.hover_fade
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_tap_single_20_regular"
            title: qsTr("Tap to hide")
            description: qsTr(
                "Click on the widget to hide it, click it again to bring it back"
            )
            Switch {
                id: tapToHideSwitch
                onCheckedChanged: Configs.set("interactions.hide.clicked", checked)
                Component.onCompleted: checked = Configs.data.interactions.hide.clicked
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            title: qsTr("More hide behavior")
            icon.name: "ic_fluent_slide_hide_20_regular"
            description: qsTr("Choose whether widgets hide or switch to Mini Mode when triggered")

            action: ComboBox {
                id: modeSelector
                Layout.preferredWidth: 180
                model: ListModel {
                    ListElement { text: qsTr("Hide Widgets"); value: false }
                    ListElement { text: qsTr("Switch to mini mode"); value: true }
                }
                textRole: "text"
                valueRole: "value"
                onCurrentValueChanged: if (focus) Configs.set("interactions.hide.mini_mode", currentValue) // !important "focus"!!!
                Component.onCompleted: {
                    console.log(Configs.data.interactions.hide.mini_mode + "123")
                    currentIndex = Configs.data.interactions.hide.mini_mode
                }
            }

            SettingItem {
                ColumnLayout {
                    Layout.fillWidth: true
                    CheckBox {
                        Layout.fillWidth: true
                        text: qsTr("Hide when in class")
                        onCheckedChanged: Configs.set("interactions.hide.in_class", checked)
                        Component.onCompleted: checked = Configs.data.interactions.hide.in_class
                    }
                    CheckBox {
                        Layout.fillWidth: true
                        text: qsTr("Hide when a window is maximized")
                        onCheckedChanged: Configs.set("interactions.hide.maximized", checked)
                        Component.onCompleted: checked = Configs.data.interactions.hide.maximized
                        enabled: Qt.platform.os === "windows"
                    }
                    CheckBox {
                        Layout.fillWidth: true
                        text: qsTr("Hide when a window enters fullscreen")
                        onCheckedChanged: Configs.set("interactions.hide.fullscreen", checked)
                        Component.onCompleted: checked = Configs.data.interactions.hide.fullscreen
                        enabled: Qt.platform.os === "windows"
                    }
                }
            }
        }
    }
}