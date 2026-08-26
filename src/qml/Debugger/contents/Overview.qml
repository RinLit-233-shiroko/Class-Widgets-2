import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

ColumnLayout {
    Layout.fillWidth: true
    Text {
        typography: Typography.BodyStrong
        text: qsTr("概览")
    }

    SettingExpander {
        Layout.fillWidth: true
        icon.name: "ic_fluent_alert_badge_20_regular"
        title: qsTr("通知")
        description: qsTr("调试")

        SettingItem {
            id: notificationTestItem
            title: qsTr("发送测试通知")
            property string notificationTestStatus: ""

            ColumnLayout {
                Layout.fillWidth: true
                ComboBox {
                    id: notificationLevel
                    Layout.fillWidth: true
                    model: [qsTr("信息"), qsTr("公告"), qsTr("警告"), qsTr("系统")]
                }
                TextField {
                    id: notificationTitle
                    Layout.fillWidth: true
                    placeholderText: qsTr("标题")
                }
                TextField {
                    id: notificationText
                    Layout.fillWidth: true
                    placeholderText: qsTr("内容")
                }

                Button {
                    highlighted: true
                    text: qsTr("发送")
                    onClicked: {
                        let provider = UtilsBackend.debugNotificationProvider
                        if (provider) {
                            provider.push(
                                notificationLevel.currentIndex,
                                notificationTitle.text || qsTr("调试"),
                                notificationText.text || qsTr("调试通知"),
                                4000,
                                true
                            )
                            notificationTestItem.notificationTestStatus = qsTr("测试通知已发送")
                        } else {
                            notificationTestItem.notificationTestStatus = qsTr("调试通知提供者不可用")
                        }
                    }
                    // onClicked: {
                    //     AppCentral.notification.push(
                    //         "ic_fluent_alert_20_regular",  // icon
                    //         notificationLevel.currentIndex,  // level
                    //         notificationTitle.text,  // title
                    //         notificationText.text  // text
                    //     )
                    // }
                }

                Text {
                    Layout.fillWidth: true
                    visible: notificationTestItem.notificationTestStatus !== ""
                    color: Colors.proxy.textSecondaryColor
                    text: notificationTestItem.notificationTestStatus
                }
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        icon.name: "ic_fluent_info_20_regular"
        title: qsTr("应用概览")
        description: "Class Widgets 2 | " + AppCentral.globalConfig.app.version

        SettingItem {
            title: qsTr("版本")
            // 此 SettingItem 没有描述
            Text {
                text: AppCentral.globalConfig.app.version
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        title: qsTr("应用主题")
        description: qsTr("选择要显示的应用主题")
        icon.name: "ic_fluent_paint_brush_20_regular"

        ComboBox {
            property var data: [Theme.mode.Light, Theme.mode.Dark, Theme.mode.Auto]
            model: ListModel {
                ListElement { text: qsTr("浅色") }
                ListElement { text: qsTr("深色") }
                ListElement { text: qsTr("跟随系统设置") }
            }
            currentIndex: data.indexOf(Theme.getTheme())
            onCurrentIndexChanged: {
                Theme.setTheme(data[currentIndex])
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_document_bullet_list_off_20_regular"
        title: qsTr("不保存日志")
        description: qsTr("不将日志保存到本地存储。")

        // Control placed on the right side via the 'content' default property
        Switch { // This Switch is assigned to the 'content' property
            checked: true
        }
    }
}