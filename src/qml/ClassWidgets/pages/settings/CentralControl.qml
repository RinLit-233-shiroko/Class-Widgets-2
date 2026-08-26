import QtQuick
import QtQuick.Controls
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
            icon.name: "ic_fluent_cloud_arrow_down_20_regular"
            title: qsTr("课程表下发地址")
            description: qsTr("填写 GitHub Pages 上的课程表清单地址（manifest.json）")

            TextField {
                id: manifestUrlField
                Layout.fillWidth: true
                placeholderText: "https://mmckb.github.io/Test/manifest.json"
                Component.onCompleted: text = AppCentral.centralControl.manifestUrl
                onEditingFinished: {
                    text = text.trim()
                    AppCentral.centralControl.setManifestUrl(text)
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_calendar_arrow_down_20_regular"
            title: qsTr("接收集控课程表")
            description: qsTr("手动下载、校验并应用课程表。下载失败时会保留当前本地课程表。")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    color: Colors.proxy.textSecondaryColor
                    text: AppCentral.centralControl.statusText
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: AppCentral.centralControl.lastAppliedName !== ""
                    color: Colors.proxy.textSecondaryColor
                    text: qsTr("当前集控课程表：%1（策略版本：%2）")
                        .arg(AppCentral.centralControl.lastAppliedName)
                        .arg(AppCentral.centralControl.lastPolicyVersion)
                    wrapMode: Text.WordWrap
                }

                Button {
                    text: AppCentral.centralControl.syncing
                          ? qsTr("正在检查…")
                          : qsTr("检查并应用课程表")
                    enabled: !AppCentral.centralControl.syncing
                    onClicked: AppCentral.centralControl.fetchAndApplySchedule()
                }
            }
        }
    }
}
