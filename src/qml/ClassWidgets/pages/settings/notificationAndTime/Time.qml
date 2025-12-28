import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects


FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42*2

    title: qsTr("Time")

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
                "Adjust schedule time to match your school's broadcast; " +
                "Increase the offset to compensate for early bells, decrease to compensate for late bells"
            )

            SpinBox {
                from: -86400
                to: 86400
                property string suffix: qsTr("minutes")
                Layout.preferredWidth: 200
                onValueChanged: Configs.set("schedule.time_offset", value)
                Component.onCompleted: value = Configs.data.schedule.time_offset
            }
        }
    }
}