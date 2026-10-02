import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
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
}
