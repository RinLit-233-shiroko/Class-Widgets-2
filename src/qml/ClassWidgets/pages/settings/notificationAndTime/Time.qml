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
            title: qsTr("Time Offset (Seconds)")
            description: qsTr(
                "Adjust schedule time to match your school's broadcast; " +
                "Increase the offset to compensate for early bells, decrease to compensate for late bells"
            )

            SpinBox {
                from: -86400
                to: 86400
                property string suffix: qsTr("Seconds")
                Layout.preferredWidth: 200
                enabled: !Configs.isKeyLocked("schedule.time_offset")
                onValueChanged: Configs.set("schedule.time_offset", value)
                Component.onCompleted: value = Configs.data.schedule.time_offset
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Preparation Bell")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_alert_20_regular"
            title: qsTr("Advance Time (Minutes)")
            description: qsTr("Minutes before class starts to ring the preparation bell")

            SpinBox {
                from: 1
                to: 60
                Layout.preferredWidth: 200
                enabled: !Configs.isKeyLocked("schedule.preparation_time")
                // 仅在用户操作时写回；构造阶段 from 钳制产生的误写(1)不会覆盖真实配置
                onValueChanged: if (focus) Configs.set("schedule.preparation_time", value)
                Component.onCompleted: value = Configs.data.schedule.preparation_time
            }
        }
    }
}
