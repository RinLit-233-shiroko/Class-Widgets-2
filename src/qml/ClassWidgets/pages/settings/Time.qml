import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects


FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42*2

    title: qsTr("Notification & Time")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Time")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_timer_20_regular"
            title: qsTr("Time Offset (minutes)")
            description: qsTr(
                "Adjust schedule time to match your school's broadcast. " +
                "Increase the offset to compensate for early bells, decrease to compensate for late bells."
            )

            SpinBox {
                from: -86400
                to: 86400
                property string suffix: qsTr("minutes")
                onValueChanged: Configs.set("schedule.time_offset", value)
                Component.onCompleted: value = Configs.data.schedule.time_offset
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_clock_arrow_download_20_regular"
            title: qsTr("Auto Time Offset")
            description: qsTr(
                "Automatically adjust time offset daily by a specified amount. " +
                "This can help compensate for gradual timing drift in school schedules."
            )

            RowLayout {
                spacing: 8
                
                SpinBox {
                    id: autoOffsetValue
                    visible: autoOffsetSwitch.checked
                    from: -86400
                    to: 86400
                    property string suffix: qsTr("seconds/day")
                    onValueChanged: {
                        Configs.set("schedule.auto_time_offset_value", value)
                    }
                    Component.onCompleted: value = Configs.data.schedule.auto_time_offset_value
                }
                
                Item {
                    Layout.fillWidth: true
                }
                
                Switch {
                    id: autoOffsetSwitch
                    onCheckedChanged: Configs.set("schedule.auto_time_offset_enabled", checked)
                    Component.onCompleted: checked = Configs.data.schedule.auto_time_offset_enabled
                }
            }
        }
    }
}