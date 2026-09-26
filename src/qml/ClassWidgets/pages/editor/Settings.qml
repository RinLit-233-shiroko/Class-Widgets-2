import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    title: qsTr("Settings")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_clock_bill_20_regular"
            title: qsTr("Select Default Duration")
            description: qsTr("Set the default duration for new classes, breaks, or activities.")
            expanded: true

            SettingItem {
                title: qsTr("Class")
                action: RowLayout {
                    SpinBox {
                        from: 1
                        to: 1440
                        stepSize: 5
                        value: Configs.data.schedule.default_duration.class_
                        onValueChanged: if (activeFocus) Configs.set("schedule.default_duration.class_", value)
                    }
                    Text { text: qsTr("minute(s)") }
                }
            }

            SettingItem {
                title: qsTr("Break")
                action: RowLayout {
                    SpinBox {
                        from: 1
                        to: 1440
                        value: Configs.data.schedule.default_duration.break_
                        onValueChanged: if (activeFocus) Configs.set("schedule.default_duration.break_", value)
                    }
                    Text { text: qsTr("minute(s)") }
                }
            }

            SettingItem {
                title: qsTr("Activity")
                action: RowLayout {
                    SpinBox {
                        from: 1
                        to: 1440
                        stepSize: 5
                        value: Configs.data.schedule.default_duration.activity
                        onValueChanged: if (activeFocus) Configs.set("schedule.default_duration.activity", value)
                    }
                    Text { text: qsTr("minute(s)") }
                }
            }
        }
    }
}
