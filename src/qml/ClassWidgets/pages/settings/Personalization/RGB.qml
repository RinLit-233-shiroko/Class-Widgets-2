import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import RinUI
import ClassWidgets
import ClassWidgets.Theme


FluentPage {
    id: root
    title: qsTr("RGB Lighting Effects")

    // 当前是否为RGB主题
    property bool isRgbTheme: CWThemeManager.currentTheme === "com.classwidgets.rgb"

    // RGB效果管理器（从C++引擎获取）
    property var rgbEngine: null

    // 当前效果状态
    property bool effectEnabled: false
    property string currentEffect: "Static"
    property color primaryColor: "#ff0000"
    property color secondaryColor: "#0000ff"
    property real effectSpeed: 1.0
    property real effectBrightness: 1.0

    // 颜色选择对话框
    ColorDialog {
        id: primaryColorDialog
        title: qsTr("Select Primary Color")
        selectedColor: root.primaryColor
        onAccepted: {
            root.primaryColor = primaryColorDialog.selectedColor
            applySettings()
        }
    }

    ColorDialog {
        id: secondaryColorDialog
        title: qsTr("Select Secondary Color")
        selectedColor: root.secondaryColor
        onAccepted: {
            root.secondaryColor = secondaryColorDialog.selectedColor
            applySettings()
        }
    }

    // 应用设置到引擎
    function applySettings() {
        // TODO: 连接到C++引擎
        console.log("Applying RGB settings:", currentEffect, effectSpeed, effectBrightness)
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: root.width - root.leftPadding - root.rightPadding
            spacing: 16

            // 非RGB主题提示
            InfoBar {
                Layout.fillWidth: true
                visible: !isRgbTheme
                severity: Severity.Info
                title: qsTr("RGB Theme Required")
                text: qsTr("Please select the RGB theme in Personalization to use lighting effects.")
            }

            // 启用开关
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("Effect Settings")
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: qsTr("Enable RGB Effects")
                    description: qsTr("Widget colors will change dynamically with the selected effect")
                    icon.name: "ic_fluent_light_20_regular"
                    enabled: isRgbTheme

                    Switch {
                        id: enableSwitch
                        checked: effectEnabled
                        onToggled: {
                            effectEnabled = checked
                        }
                    }
                }
            }

            // 效果类型选择
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: effectEnabled && isRgbTheme

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("OpenRGB Standard Effects")
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Static", display: qsTr("Static") },
                            { name: "Breathing", display: qsTr("Breathing") },
                            { name: "Flashing", display: qsTr("Flashing") },
                            { name: "Spectrum Cycle", display: qsTr("Spectrum Cycle") },
                            { name: "Rainbow Wave", display: qsTr("Rainbow Wave") }
                        ]

                        delegate: Button {
                            text: modelData.display
                            checkable: true
                            checked: currentEffect === modelData.name
                            onClicked: {
                                currentEffect = modelData.name
                                applySettings()
                            }
                        }
                    }
                }
            }

            // 扩展效果
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: effectEnabled && isRgbTheme

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("Extended Effects")
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Running Light", display: qsTr("Running Light") },
                            { name: "Meteor", display: qsTr("Meteor") },
                            { name: "Gradient", display: qsTr("Gradient") },
                            { name: "Sparkle", display: qsTr("Sparkle") },
                            { name: "Heartbeat", display: qsTr("Heartbeat") }
                        ]

                        delegate: Button {
                            text: modelData.display
                            checkable: true
                            checked: currentEffect === modelData.name
                            onClicked: {
                                currentEffect = modelData.name
                                applySettings()
                            }
                        }
                    }
                }
            }

            // 预设效果
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: effectEnabled && isRgbTheme

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("Presets")
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Ocean", display: qsTr("Ocean"), effect: "Breathing", color: "#0064c8", speed: 0.5 },
                            { name: "Sunset", display: qsTr("Sunset"), effect: "Gradient", color: "#ff6400", speed: 0.3 },
                            { name: "Forest", display: qsTr("Forest"), effect: "Breathing", color: "#00b400", speed: 0.7 },
                            { name: "Aurora", display: qsTr("Aurora"), effect: "Rainbow Wave", color: "#00ff88", speed: 0.5 },
                            { name: "Fire", display: qsTr("Fire"), effect: "Meteor", color: "#ff3c00", speed: 2.0 },
                            { name: "Cyberpunk", display: qsTr("Cyberpunk"), effect: "Sparkle", color: "#ff00ff", speed: 5.0 }
                        ]

                        delegate: Chip {
                            text: modelData.display
                            onClicked: {
                                currentEffect = modelData.effect
                                primaryColor = modelData.color
                                effectSpeed = modelData.speed
                                applySettings()
                            }
                        }
                    }
                }
            }

            // 颜色设置
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: effectEnabled && isRgbTheme

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("Color Settings")
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: qsTr("Primary Color")
                    description: qsTr("Main color for the effect")
                    icon.name: "ic_fluent_color_20_regular"

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 4
                            color: primaryColor
                            border.width: 1
                            border.color: "#40000000"
                        }

                        Button {
                            text: qsTr("Select")
                            onClicked: primaryColorDialog.open()
                        }
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: qsTr("Secondary Color")
                    description: qsTr("Used for gradient effects")
                    icon.name: "ic_fluent_color_20_regular"
                    visible: currentEffect === "Gradient"

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 4
                            color: secondaryColor
                            border.width: 1
                            border.color: "#40000000"
                        }

                        Button {
                            text: qsTr("Select")
                            onClicked: secondaryColorDialog.open()
                        }
                    }
                }
            }

            // 参数调节
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                enabled: effectEnabled && isRgbTheme

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("Parameters")
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: qsTr("Speed")
                    description: qsTr("Effect animation speed")
                    icon.name: "ic_fluent_top_speed_20_regular"

                    RowLayout {
                        spacing: 8

                        Slider {
                            Layout.fillWidth: true
                            from: 0.1
                            to: 10.0
                            value: effectSpeed
                            onMoved: {
                                effectSpeed = value
                                applySettings()
                            }
                        }

                        Label {
                            text: effectSpeed.toFixed(1)
                            width: 30
                        }
                    }
                }

                SettingCard {
                    Layout.fillWidth: true
                    title: qsTr("Brightness")
                    description: qsTr("Effect brightness level")
                    icon.name: "ic_fluent_brightness_20_regular"

                    RowLayout {
                        spacing: 8

                        Slider {
                            Layout.fillWidth: true
                            from: 0.0
                            to: 1.0
                            value: effectBrightness
                            onMoved: {
                                effectBrightness = value
                                applySettings()
                            }
                        }

                        Label {
                            text: Math.round(effectBrightness * 100) + "%"
                            width: 30
                        }
                    }
                }
            }

            // 实时预览
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    typography: Typography.BodyStrong
                    text: qsTr("Preview")
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    radius: 12
                    color: primaryColor

                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 12
                        samples: 24
                        color: primaryColor
                        source: parent
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: qsTr("Color Preview")
                        color: Qt.luma(primaryColor) > 0.5 ? "#000000" : "#ffffff"
                        font.weight: Font.Bold
                    }
                }
            }
        }
    }

    // 保存设置
    Component.onCompleted: {
        // TODO: 从设置中加载保存的值
        loadSettings()
    }

    function loadSettings() {
        effectEnabled = _settings.value("rgb_enabled", false)
        currentEffect = _settings.value("rgb_effect", "Static")
        primaryColor = _settings.value("rgb_primary_color", "#ff0000")
        secondaryColor = _settings.value("rgb_secondary_color", "#0000ff")
        effectSpeed = _settings.value("rgb_speed", 1.0)
        effectBrightness = _settings.value("rgb_brightness", 1.0)
    }

    property var _settings: Configs.data.rgbEffects
}
