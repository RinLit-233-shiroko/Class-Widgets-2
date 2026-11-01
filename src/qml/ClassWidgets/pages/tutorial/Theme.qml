import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../../Components/tutorial" as TutorialComponents

TutorialComponents.TutorialPage {
    id: root

    property var tutorial
    title: qsTr("Choose your look")
    description: qsTr("Set the app appearance and an accent color that feels right to you.")
    currentStep: 3
    totalSteps: 7
    icon.source: PathManager.images("tutorial/cw2_personalization.png")

    readonly property var recommendedColors: [
        "#4099b2", "#0078d4", "#107c10", "#d83b01", "#c239b3", "#8764b8"
    ]

    ColumnLayout {
        width: parent.width
        spacing: 4

        SettingExpander {
            Layout.minimumHeight: 200

            Layout.fillWidth: true
            icon.name: "ic_fluent_dark_theme_20_regular"
            title: qsTr("Theme")
            description: qsTr("Select which app theme to display")
            expanded: true

            ButtonGroup {
                id: themeModeGroup
            }

            SettingItem {
                RowLayout {
                    id: themeOptionsRow
                    Layout.fillWidth: true
                    spacing: 12

                    Repeater {
                        model: [
                            {
                                "name": qsTr("Auto"),
                                "mode": Theme.mode.Auto,
                                "preview": "mode-auto.png"
                            },
                            {
                                "name": qsTr("Light"),
                                "mode": Theme.mode.Light,
                                "preview": "mode-light.png"
                            },
                            {
                                "name": qsTr("Dark"),
                                "mode": Theme.mode.Dark,
                                "preview": "mode-dark.png"
                            }
                        ]

                        delegate: ColumnLayout {
                            Layout.preferredWidth: (themeOptionsRow.width - themeOptionsRow.spacing * 2) / 3
                            Layout.minimumWidth: 0
                            spacing: 4

                            Image {
                                Layout.preferredWidth: parent.width
                                Layout.preferredHeight: 72
                                source: PathManager.images("tutorial/" + modelData.preview)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            RadioButton {
                                Layout.fillWidth: true
                                text: modelData.name
                                checked: Theme.getTheme() === modelData.mode
                                enabled: !Configs.isKeyLocked("preferences.current_theme")
                                ButtonGroup.group: themeModeGroup
                                onClicked: Theme.setTheme(modelData.mode)
                            }
                        }
                    }
                }
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_color_20_regular"
            title: qsTr("Accent Color")
            description: qsTr("Choose the color used for highlights and controls")
            expanded: true

            SettingItem {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.recommendedColors

                        delegate: Button {
                            required property string modelData
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            Layout.minimumWidth: 28
                            Layout.minimumHeight: 28
                            padding: 0
                            checkable: true
                            checked: Utils.primaryColor.toString().toLowerCase()
                                     === modelData.toLowerCase()
                            ToolTip.visible: hovered
                            ToolTip.text: modelData
                            onClicked: Theme.setThemeColor(modelData)

                            background: Rectangle {
                                radius: width / 2
                                color: parent.modelData
                                border.width: parent.checked ? 3 : 1
                                border.color: parent.checked ? Colors.proxy.textColor
                                                           : Colors.proxy.controlSolidColor
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    DropDownColorPicker {
                        position: Position.Left
                        color: Utils.primaryColor
                        onColorChanged: Theme.setThemeColor(color)
                    }
                }
            }
        }
    }
}
