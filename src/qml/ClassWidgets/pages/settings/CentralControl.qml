import QtQuick
import QtQuick.Layouts
import RinUI


FluentPage {
    id: root
    title: qsTr("集控")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            typography: Typography.BodyStrong
            text: qsTr("集控")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_people_team_20_regular"
            title: qsTr("集控功能暂未启用")
            description: qsTr(
                "此页面已预留为独立的集控入口。后续将在此配置设备接入、统一策略与远程管理功能。"
            )
        }
    }
}
