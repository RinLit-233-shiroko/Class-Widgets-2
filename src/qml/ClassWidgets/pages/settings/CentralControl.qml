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
            title: qsTr("集控地址")
            description: qsTr("填写 GitHub Pages 上的集控清单地址（manifest.json）；留空时不会拉取任何集控内容。")

            TextField {
                id: manifestUrlField
                Layout.fillWidth: true
                placeholderText: "https://example.github.io/repository/manifest.json"
                Component.onCompleted: text = AppCentral.centralControl.manifestUrl
                onEditingFinished: {
                    text = text.trim()
                    AppCentral.centralControl.setManifestUrl(text)
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_arrow_sync_20_regular"
            title: qsTr("拉取方式")
            description: qsTr("手动模式仅在点击检查按钮时拉取；自动模式会在启动后和指定间隔自动拉取。")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Switch {
                    id: autoFetchSwitch
                    text: qsTr("自动拉取集控内容")
                    checked: AppCentral.centralControl.autoFetchEnabled
                    onToggled: AppCentral.centralControl.setAutoFetchEnabled(checked)
                }

                RowLayout {
                    Layout.fillWidth: true
                    visible: autoFetchSwitch.checked
                    enabled: autoFetchSwitch.checked
                    spacing: 8

                    Text {
                        text: qsTr("检查间隔")
                    }

                    SpinBox {
                        id: autoFetchInterval
                        property bool initialized: false
                        from: 1
                        to: 1440
                        value: AppCentral.centralControl.autoFetchIntervalMinutes
                        editable: true
                        onValueChanged: {
                            if (initialized)
                                AppCentral.centralControl.setAutoFetchIntervalMinutes(value)
                        }
                        Component.onCompleted: initialized = true
                    }

                    Text {
                        text: qsTr("分钟")
                        color: Colors.proxy.textSecondaryColor
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_calendar_arrow_down_20_regular"
            title: qsTr("接收集控内容")
            description: qsTr("下载、校验并应用课程表；同一公告命令只会在本机执行一次。失败时保留当前本地课程表。")

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

                Text {
                    visible: AppCentral.centralControl.lastAnnouncementCount > 0
                    color: Colors.proxy.textSecondaryColor
                    text: qsTr("本次已处理 %1 条一次性公告命令。")
                        .arg(AppCentral.centralControl.lastAnnouncementCount)
                }

                Button {
                    text: AppCentral.centralControl.syncing
                          ? qsTr("正在检查…")
                          : qsTr("检查并应用集控内容")
                    enabled: !AppCentral.centralControl.syncing
                    onClicked: AppCentral.centralControl.fetchAndApplySchedule()
                }
            }
        }
    }
}
