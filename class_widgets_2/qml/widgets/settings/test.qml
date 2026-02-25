import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    SettingCard {
        Layout.fillWidth: true
        title: "Name"
        description: "Enter your name"

        TextField {
            id: textField
            text: settings.name

            onTextChanged: {
                settings.name = text
            }
        }
    }
}