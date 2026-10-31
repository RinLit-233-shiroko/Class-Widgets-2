import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_arrow_sync_20_regular"
        title: qsTr("Digit Animation")
        description: qsTr("Animate the clock digits when the time updates. Turn off to display them statically.")

        Switch {
            id: animationSwitch
            onCheckedChanged: settings.digit_animation = animationSwitch.checked
            Component.onCompleted: animationSwitch.checked = settings.digit_animation !== false
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_timer_20_regular"
        title: qsTr("Show Seconds")
        description: qsTr("Display seconds after the hour and minute.")

        Switch {
            id: secondsSwitch
            onCheckedChanged: settings.show_seconds = secondsSwitch.checked
            Component.onCompleted: secondsSwitch.checked = settings.show_seconds !== false
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_calendar_20_regular"
        title: qsTr("Show Date")
        description: qsTr("Display the date below the clock. Turn off to hide all date parts.")

        Switch {
            id: dateSwitch
            onCheckedChanged: settings.show_date = dateSwitch.checked
            Component.onCompleted: dateSwitch.checked = settings.show_date !== false
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_calendar_ltr_20_regular"
        title: qsTr("Date Content")
        description: qsTr("Choose which parts of the date to display.")

        enabled: dateSwitch.checked

        RowLayout {
            spacing: 16

            ColumnLayout {
                spacing: 2
                Switch {
                    id: yearSwitch
                    onCheckedChanged: settings.show_year = yearSwitch.checked
                    Component.onCompleted: yearSwitch.checked = settings.show_year !== false
                }
                Text {
                    text: qsTr("Year")
                    typography: Typography.Caption
                }
            }

            ColumnLayout {
                spacing: 2
                Switch {
                    id: monthSwitch
                    onCheckedChanged: settings.show_month = monthSwitch.checked
                    Component.onCompleted: monthSwitch.checked = settings.show_month !== false
                }
                Text {
                    text: qsTr("Month")
                    typography: Typography.Caption
                }
            }

            ColumnLayout {
                spacing: 2
                Switch {
                    id: daySwitch
                    onCheckedChanged: settings.show_day = daySwitch.checked
                    Component.onCompleted: daySwitch.checked = settings.show_day !== false
                }
                Text {
                    text: qsTr("Day")
                    typography: Typography.Caption
                }
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_calendar_week_start_20_regular"
        title: qsTr("Show Weekday")
        description: qsTr("Display the weekday below the clock.")

        Switch {
            id: weekdaySwitch
            onCheckedChanged: settings.show_weekday = weekdaySwitch.checked
            Component.onCompleted: weekdaySwitch.checked = settings.show_weekday !== false
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_text_align_center_20_regular"
        title: qsTr("Date and Weekday Layout")
        description: qsTr("Show the date and weekday side by side, or alternate between them.")

        ComboBox {
            id: layoutComboBox
            property bool initialized: false
            property var modes: ["side_by_side", "alternate"]

            model: ListModel {
                ListElement { text: qsTr("Side by side") }
                ListElement { text: qsTr("Alternate") }
            }
            textRole: "text"

            Component.onCompleted: {
                var index = modes.indexOf(settings.title_mode)
                currentIndex = index >= 0 ? index : 0
                initialized = true
            }
            onCurrentIndexChanged: {
                if (initialized && currentIndex >= 0)
                    settings.title_mode = modes[currentIndex]
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_timer_20_regular"
        title: qsTr("Alternate Interval")
        description: qsTr("Set how long each of the date and weekday stays visible.")

        SpinBox {
            id: intervalSpinBox
            property bool initialized: false
            from: 500
            to: 10000
            stepSize: 100
            editable: true
            enabled: layoutComboBox.currentIndex === 1

            Component.onCompleted: {
                var value = Number(settings.alternate_interval)
                intervalSpinBox.value = isNaN(value) ? 3000 : Math.max(from, Math.min(to, value))
                initialized = true
            }
            onValueChanged: {
                if (initialized) settings.alternate_interval = value
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_arrow_rotate_clockwise_20_regular"
        title: qsTr("Alternate Animation")
        description: qsTr("Fade between the date and weekday instead of switching instantly.")

        Switch {
            id: alternateAnimSwitch
            enabled: layoutComboBox.currentIndex === 1
            onCheckedChanged: settings.alternate_animation = alternateAnimSwitch.checked
            Component.onCompleted: alternateAnimSwitch.checked = settings.alternate_animation === true
        }
    }
}
