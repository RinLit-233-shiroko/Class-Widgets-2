import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentPage {
    title: qsTr("Widgets")

    // Frame {
    //     Layout.fillWidth: true
    //     padding: 24
    //
    //     RowLayout {
    //         anchors.fill: parent
    //         spacing: 24
    //
    //         Image {
    //             Layout.alignment: Qt.AlignCenter
    //             Layout.maximumWidth: 200
    //             Layout.maximumHeight: 150
    //             fillMode: Image.PreserveAspectFit
    //             source: PathManager.images(
    //                 "settings/widgets/new_editor_widgets-" + (Theme.isDark()? "dark" : "light") + ".png"
    //             )
    //         }
    //
    //         ColumnLayout {
    //             Layout.fillWidth: true
    //             Layout.alignment: Qt.AlignHCenter
    //             spacing: 12
    //
    //             Text {
    //                 Layout.fillWidth: true
    //                 typography: Typography.BodyLarge
    //                 text: qsTr("The new way to edit widgets")
    //             }
    //             Text {
    //                 Layout.fillWidth: true
    //                 text: qsTr(
    //                     "Right-click or long press any widget, \n" +
    //                     "then tap \"Edit Widget Screen\" in the menu to experience it."
    //                 )
    //             }
    //             Button {
    //                 flat: true
    //                 highlighted: true
    //                 Layout.alignment: Qt.AlignRight
    //                 icon.name: "ic_fluent_arrow_right_20_regular"
    //                 text: qsTr("Edit Widgets Screen")
    //                 onClicked: AppCentral.toggleWidgetsEditMode()
    //             }
    //         }
    //     }
    // }
    Introduction {
        source:PathManager.images(
            "settings/widgets/new_editor_widgets-" + (Theme.isDark()? "dark" : "light") + ".png"
        )
        title: qsTr("The new way to edit widgets")
        description: qsTr(
            "Right-click or long press any widget, \n" +
            "then tap \"Edit Widget Screen\" in the menu to experience it."
        )
        Button {
            flat: true
            highlighted: true
            Layout.alignment: Qt.AlignRight
            icon.name: "ic_fluent_arrow_right_20_regular"
            text: qsTr("Edit Widgets Screen")
            onClicked: AppCentral.toggleWidgetsEditMode()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Appearances")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_resize_20_regular"
            title: qsTr("Widgets Scale")
            description: qsTr("Make widgets look bigger or stay compact")

            Slider {
                from: 0.5
                to: 2.0
                stepSize: 0.05
                tickmarks: true
                tickFrequency: 0.5
                onValueChanged: if (pressed) Configs.set("preferences.scale_factor", value)
                Component.onCompleted: value = Configs.data.preferences.scale_factor || 1.0
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_transparency_square_20_regular"
            title: qsTr("Opacity")
            description: qsTr("Change the opacity of the background of widgets")

            Slider {
                from: 0
                to: 1
                stepSize: 0.05
                tickmarks: true
                tickFrequency: 0.2
                onValueChanged: if (pressed) Configs.set("preferences.opacity", value)
                Component.onCompleted: value = Configs.data.preferences.opacity || 1.0
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_resize_20_regular"
            title: qsTr("Font")
            description: qsTr("Choose a font for the widgets")


            action: ComboBox {
                Layout.fillWidth: true
                Layout.preferredWidth: 200
                model: Qt.fontFamilies().sort()
                editable: true

                onCurrentTextChanged: {
                    if (Qt.fontFamilies().indexOf(currentText) === 0) {
                        return
                    }
                    console.log("currentText", currentText)
                    if (focus) Configs.set("preferences.font", currentText)
                }
                font.family: Configs.data.preferences.font

                Component.onCompleted: {
                    const saved = Configs.data.preferences.font
                    const i = model.indexOf(saved)
                    currentIndex = i >= 0 ? i : 0
                }
            }

            SettingItem {
                title: qsTr("Font weight")
                description: qsTr("Set the thickness of the font")

                Text {
                    text: {
                        switch (Math.round(weightSlider.value)) {
                            case 100: return qsTr("Thin")
                            case 200: return qsTr("Extra Light")
                            case 300: return qsTr("Light")
                            case 400: return qsTr("Regular")
                            case 500: return qsTr("Medium")
                            case 600: return qsTr("Semi Bold")
                            case 700: return qsTr("Bold")
                            case 800: return qsTr("Extra Bold")
                            case 900: return qsTr("Black")
                            default: return qsTr("Custom")
                        }
                    }
                }

                Slider {
                    id: weightSlider
                    from: 100
                    to: 900
                    stepSize: 100
                    snapMode: Slider.SnapAlways
                    tickmarks: true
                    tickFrequency: 100
                    Layout.fillWidth: true
                    showTooltip: false

                    // 初始化
                    Component.onCompleted: {
                        const saved = Configs.data.preferences.font_weight
                        value = saved > 0 ? saved : 400
                    }

                    // 更新
                    onMoved: {
                        let v = parseInt (weightSlider.value)
                        if (focus) Configs.set("preferences.font_weight", v)
                    }
                }
            }

            SettingItem {
                title: qsTr("Preview")
                TextArea {
                    textFormat: TextEdit.RichText
                    text: qsTr(
                        "The quick brown fox jumps over the lazy dog"
                    )
                    font: {
                        var f = AppCentral.getQFont(Configs.data.preferences.font, Utils.fontFamily)
                        f.weight = Configs.data.preferences.font_weight || 400
                        return f
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Window")
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_laptop_20_regular"
            title: qsTr("Display")
            description: qsTr("Set which screen to display widgets on, and adjust their position")

            action: ComboBox {
                Layout.fillWidth: true
                model: Qt.application.screens
                textRole: "name"
                onCurrentTextChanged: if (focus) Configs.set("preferences.display", currentText)
                Component.onCompleted: {
                    const saved = Configs.data.preferences.display
                    const screens = Qt.application.screens
                    const i = screens.findIndex(s => s.name === saved)
                    currentIndex = i >= 0 ? i : 0
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 24
                spacing: 12

                Rectangle {
                    // 屏幕边框
                    Layout.preferredWidth: parent.width * 0.65
                    Layout.preferredHeight: 200
                    // Layout.fillWidth: true
                    Layout.fillHeight: true
                    // Layout.preferredHeight: Math.min(width / 1.75, 350)
                    border.width: 8
                    radius: 12
                    color: "transparent"
                    border.color: "black"

                    property alias selectedAnchor: anchorGroup.checkedButton

                    // RadioButton Group
                    ButtonGroup {
                        id: anchorGroup
                    }

                    // 左上角
                    RadioButton {
                        id: topLeft
                        anchors.left: parent.left; anchors.top: parent.top
                        anchors.margins: 12
                        ButtonGroup.group: anchorGroup
                        checked: Configs.data.preferences.widgets_anchor === "top_left"
                        onClicked: Configs.set("preferences.widgets_anchor", "top_left")
                    }

                    // 顶部中
                    RadioButton {
                        id: topCenter
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top
                        anchors.topMargin: 12
                        ButtonGroup.group: anchorGroup
                        checked: Configs.data.preferences.widgets_anchor === "top_center"
                        onClicked: Configs.set("preferences.widgets_anchor", "top_center")
                    }

                    // 右上角
                    RadioButton {
                        id: topRight
                        anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 12
                        ButtonGroup.group: anchorGroup
                        checked: Configs.data.preferences.widgets_anchor === "top_right"
                        onClicked: Configs.set("preferences.widgets_anchor", "top_right")
                    }

                    // 左下角
                    RadioButton {
                        id: bottomLeft
                        anchors.left: parent.left; anchors.bottom: parent.bottom
                        anchors.margins: 12
                        ButtonGroup.group: anchorGroup
                        checked: Configs.data.preferences.widgets_anchor === "bottom_left"
                        onClicked: Configs.set("preferences.widgets_anchor", "bottom_left")
                    }

                    // 底部中
                    RadioButton {
                        id: bottomCenter
                        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        ButtonGroup.group: anchorGroup
                        checked: Configs.data.preferences.widgets_anchor === "bottom_center"
                        onClicked: Configs.set("preferences.widgets_anchor", "bottom_center")
                    }

                    // 右下角
                    RadioButton {
                        id: bottomRight
                        anchors.right: parent.right; anchors.bottom: parent.bottom
                        anchors.margins: 12
                        ButtonGroup.group: anchorGroup
                        checked: Configs.data.preferences.widgets_anchor === "bottom_right"
                        onClicked: Configs.set("preferences.widgets_anchor", "bottom_right")
                    }
                }

                // 左右侧偏移
                ColumnLayout {
                    Layout.alignment: Qt.AlignTop
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Text {
                            Layout.alignment: Qt.AlignLeft
                            text: qsTr("X-axis offset")
                        }
                        SpinBox {
                            Layout.fillWidth: true
                            from: -1000
                            to: 1000
                            stepSize: 1
                            onValueChanged: if (focus) Configs.set("preferences.widgets_offset_x", value)
                            Component.onCompleted: value = Configs.data.preferences.widgets_offset_x || 0
                        }
                    }
                    ColumnLayout {
                        Text {
                            Layout.alignment: Qt.AlignLeft
                            text: qsTr("Y-axis offset")
                        }
                        SpinBox {
                            Layout.fillWidth: true
                            from: -1000
                            to: 1000
                            stepSize: 1
                            onValueChanged: if (focus) Configs.set("preferences.widgets_offset_y", value)
                            Component.onCompleted: value = Configs.data.preferences.widgets_offset_y || 0
                        }
                    }
                }
            }
        }
    }
}