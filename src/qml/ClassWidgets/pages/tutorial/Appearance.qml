import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../../Components/tutorial" as TutorialComponents

TutorialComponents.TutorialPage {
    id: root

    property var tutorial
    title: qsTr("Tune your widgets")
    description: qsTr("Adjust the size and finish of your widgets. The preview updates as you make changes.")
    currentStep: 4
    totalSteps: 7

    rightContent: TutorialComponents.TutorialVisual {
        anchors.fill: parent

        dynamicContent: Component {
            TutorialComponents.WidgetPreview {
                anchors.fill: parent
                clip: true
            }
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 4

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_resize_20_regular"
            title: qsTr("Widget Scale")
            description: qsTr("Make widgets look bigger or stay compact")

            Slider {
                id: scaleSlider
                Layout.fillWidth: true
                from: 0.5
                to: 2.0
                stepSize: 0.05
                tickmarks: true
                tickFrequency: 0.5
                enabled: !Configs.isKeyLocked("preferences.scale_factor")
                toolTip.text: Math.round(value * 100) + "%"

                Timer {
                    id: scalePreviewTimer
                    interval: 33
                    repeat: true
                    onTriggered: {
                        if (scaleSlider.pressed)
                            Configs.set("preferences.scale_factor", scaleSlider.value)
                        else
                            stop()
                    }
                }

                onPressedChanged: {
                    if (pressed) {
                        Configs.set("preferences.scale_factor", value)
                        scalePreviewTimer.start()
                    } else {
                        scalePreviewTimer.stop()
                        Configs.set("preferences.scale_factor", value)
                    }
                    // Configs.set("preferences.scale_factor", value)
                }
                Component.onCompleted: value = Configs.data.preferences.scale_factor || 1.0
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_transparency_square_20_regular"
            title: qsTr("Background Opacity")
            description: qsTr("Change the opacity of widget backgrounds")

            Slider {
                id: opacitySlider
                Layout.fillWidth: true
                from: 0
                to: 1
                stepSize: 0.05
                tickmarks: true
                tickFrequency: 0.2
                toolTip.text: Math.round(value * 100) + "%"
                enabled: !Configs.isKeyLocked("preferences.opacity")
                onValueChanged: if (pressed) Configs.set("preferences.opacity", value)
                Component.onCompleted: value = Configs.data.preferences.opacity || 1.0
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_shape_subtract_20_regular"
            title: qsTr("Corner Radius")
            description: qsTr("Set how rounded widget corners appear")

            Slider {
                id: cornerRadiusSlider
                Layout.fillWidth: true
                from: 0
                to: 50
                stepSize: 1
                tickmarks: true
                tickFrequency: 10
                toolTip.text: Math.round(value) + " px"
                enabled: !Configs.isKeyLocked("preferences.widget_corner_radius")
                onValueChanged: if (pressed)
                                    Configs.set("preferences.widget_corner_radius", value)
                Component.onCompleted: value = Configs.data.preferences.widget_corner_radius
            }
        }
    }
}
