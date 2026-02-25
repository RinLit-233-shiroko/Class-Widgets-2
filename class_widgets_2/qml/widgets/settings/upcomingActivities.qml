 import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_subtitles_20_regular"
        title: qsTr("Marquee Title")
        description: qsTr("If enabled, the upcoming activities will scroll from left to right.")

        Switch {
            id: marqueeSwitch
            onCheckedChanged: {
                settings.marquee = marqueeSwitch.checked
            }
            Component.onCompleted: {
                marqueeSwitch.checked = settings.marquee
            }
        }
    }
    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_broad_activity_feed_20_regular"
        title: qsTr("Max number of activities")
        description: qsTr("Set the maximum number of activities to display in the upcoming activities view")

        SpinBox {
            id: maxActivitiesSpinBox
            onValueChanged: {
                settings.max_activities = maxActivitiesSpinBox.value
            }
            Component.onCompleted: {
                maxActivitiesSpinBox.value = settings.max_activities
            }
        }
    }
    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_text_case_title_20_regular"
        title: qsTr("Show full name of the activities")

        Switch {
            id: showFullNameSwitch
            onCheckedChanged: {
                settings.full_name = showFullNameSwitch.checked
            }
            Component.onCompleted: {
                showFullNameSwitch.checked = settings.full_name
            }
        }
    }
}