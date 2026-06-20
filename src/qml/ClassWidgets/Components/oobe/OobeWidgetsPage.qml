import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


ColumnLayout {
    spacing: 12

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
        expanded: true
        icon.name: "ic_fluent_text_font_20_regular"
        title: qsTr("Font")
        description: qsTr("Choose a font for the widgets")

        action: ComboBox {
            Layout.fillWidth: true
            Layout.preferredWidth: 200
            model: Qt.fontFamilies().sort()
            editable: true
            font.family: Configs.data.preferences.font

            onCurrentTextChanged: {
                if (Qt.fontFamilies().indexOf(currentText) === 0) return
                if (focus) Configs.set("preferences.font", currentText)
            }

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
                text: Math.round(weightSlider.value).toString()
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
                Component.onCompleted: value = Configs.data.preferences.font_weight || 400
                onMoved: if (focus) Configs.set("preferences.font_weight", parseInt(weightSlider.value))
            }
        }
    }

    Text {
        typography: Typography.BodyStrong
        text: qsTr("Window")
    }

    SettingExpander {
        Layout.fillWidth: true
        expanded: true
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
                Layout.preferredWidth: parent.width * 0.62
                Layout.preferredHeight: 200
                border.width: 8
                radius: 12
                color: "transparent"
                border.color: Colors.proxy.controlStrongStrokeColor

                ButtonGroup { id: anchorGroup }

                RadioButton { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 12; ButtonGroup.group: anchorGroup; checked: Configs.data.preferences.widgets_anchor === "top_left"; onClicked: Configs.set("preferences.widgets_anchor", "top_left") }
                RadioButton { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 12; ButtonGroup.group: anchorGroup; checked: Configs.data.preferences.widgets_anchor === "top_center"; onClicked: Configs.set("preferences.widgets_anchor", "top_center") }
                RadioButton { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12; ButtonGroup.group: anchorGroup; checked: Configs.data.preferences.widgets_anchor === "top_right"; onClicked: Configs.set("preferences.widgets_anchor", "top_right") }
                RadioButton { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 12; ButtonGroup.group: anchorGroup; checked: Configs.data.preferences.widgets_anchor === "bottom_left"; onClicked: Configs.set("preferences.widgets_anchor", "bottom_left") }
                RadioButton { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 12; ButtonGroup.group: anchorGroup; checked: Configs.data.preferences.widgets_anchor === "bottom_center"; onClicked: Configs.set("preferences.widgets_anchor", "bottom_center") }
                RadioButton { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 12; ButtonGroup.group: anchorGroup; checked: Configs.data.preferences.widgets_anchor === "bottom_right"; onClicked: Configs.set("preferences.widgets_anchor", "bottom_right") }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                spacing: 12

                Text { text: qsTr("X-axis offset") }
                SpinBox {
                    Layout.fillWidth: true
                    from: -1000
                    to: 1000
                    onValueChanged: if (focus) Configs.set("preferences.widgets_offset_x", value)
                    Component.onCompleted: value = Configs.data.preferences.widgets_offset_x || 0
                }

                Text { text: qsTr("Y-axis offset") }
                SpinBox {
                    Layout.fillWidth: true
                    from: -1000
                    to: 1000
                    onValueChanged: if (focus) Configs.set("preferences.widgets_offset_y", value)
                    Component.onCompleted: value = Configs.data.preferences.widgets_offset_y || 0
                }
            }
        }
    }
}