import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    id: root

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_text_case_title_20_regular"
        title: qsTr("Display content")
        description: qsTr("Choose whether to display the custom title, subject, or alternate between both.")

        ComboBox {
            id: displayModeComboBox
            property bool initialized: false
            property var modes: ["title", "subject", "alternate"]

            model: ListModel {
                ListElement { text: qsTr("Title") }
                ListElement { text: qsTr("Subject") }
                ListElement { text: qsTr("Alternate") }
            }
            textRole: "text"

            Component.onCompleted: {
                var index = modes.indexOf(settings.display_mode)
                currentIndex = index >= 0 ? index : 2
                initialized = true
            }
            onCurrentIndexChanged: {
                if (initialized && currentIndex >= 0) {
                    settings.display_mode = modes[currentIndex]
                }
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_timer_20_regular"
        title: qsTr("Alternate interval")
        description: qsTr("Set how often the custom title and subject alternate.")

        SpinBox {
            id: intervalSpinBox
            property bool initialized: false
            from: 2
            to: 10
            value: 3
            enabled: displayModeComboBox.currentIndex === 2

            Component.onCompleted: {
                var interval = Number(settings.alternate_interval)
                value = isNaN(interval) ? 3 : Math.max(from, Math.min(to, interval))
                initialized = true
            }
            onValueChanged: {
                if (initialized) settings.alternate_interval = value
            }
        }
    }

    Text {
        Layout.topMargin: 8
        Layout.leftMargin: 4
        typography: Typography.Caption
        color: Theme.currentTheme.colors.textSecondaryColor
        text: qsTr("Custom status texts")
    }

    component StatusTextField: TextField {
        property var settingsOwner
        property string settingKey
        property string defaultValue
        property bool initialized: false

        Layout.preferredWidth: 180
        Layout.minimumWidth: 180
        Layout.maximumWidth: 180
        onTextChanged: {
            if (!initialized || !settingsOwner)
                return
            // settings is a var holding a QVariantMap: mutating the object read from it
            // only changes a copy, so assign a fresh object back to the property.
            var updated = Object.assign({}, settingsOwner.settings)
            updated[settingKey] = text
            settingsOwner.settings = updated
        }
        Component.onCompleted: {
            var current = settingsOwner && settingsOwner.settings
                ? settingsOwner.settings[settingKey] : ""
            text = current ? current : defaultValue
            initialized = true
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_shifts_activity_20_filled"
        title: qsTr("Break text")
        description: qsTr("Text shown during a break.")

        StatusTextField {
            settingsOwner: root
            settingKey: "break_text"
            defaultValue: qsTr("Take a break")
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_hourglass_half_20_regular"
        title: qsTr("Preparation text")
        description: qsTr("Text shown when the next activity is about to start.")

        StatusTextField {
            settingsOwner: root
            settingKey: "preparation_text"
            defaultValue: qsTr("Starting soon")
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_clock_dismiss_20_regular"
        title: qsTr("Free time text")
        description: qsTr("Text shown when there is nothing scheduled.")

        StatusTextField {
            settingsOwner: root
            settingKey: "free_text"
            defaultValue: qsTr("Nothing right now")
        }
    }
}
