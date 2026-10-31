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
        description: qsTr("Animate the minute and second digits when the countdown updates. Turn off to display them statically.")

        Switch {
            id: animationSwitch
            onCheckedChanged: {
                settings.digit_animation = animationSwitch.checked
            }
            Component.onCompleted: {
                animationSwitch.checked = settings.digit_animation !== false
            }
        }
    }
}
