import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2
    title: qsTr("时间")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            text: AppCentral.timeService.currentTime
            font.pixelSize: 32
            font.weight: Font.DemiBold
        }

        Text {
            text: AppCentral.timeService.currentDate
            color: Colors.proxy.textSecondaryColor
            font.pixelSize: 14
        }

        Text {
            typography: Typography.BodyStrong
            text: qsTr("精确时间")
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("使用精确时间")
            description: AppCentral.timeService.preciseTimeAvailable
                         ? qsTr("当前正在使用已同步的 NTP 时间")
                         : qsTr("启用后优先使用 NTP 时间；同步失败时自动使用系统时间")
            icon.name: "ic_fluent_clock_20_regular"

            Switch {
                property bool initialized: false
                enabled: !Configs.isKeyLocked("time.use_precise_time")
                onCheckedChanged: {
                    if (initialized) {
                        AppCentral.timeService.setPreciseTimeEnabled(checked)
                    }
                }
                Component.onCompleted: {
                    checked = Configs.data.time.use_precise_time
                    initialized = true
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("NTP 服务器")
            description: qsTr("选择预设服务器，或在下方填写自定义服务器地址")
            icon.name: "ic_fluent_server_20_regular"

            ComboBox {
                id: ntpServerSelector
                Layout.preferredWidth: 260
                textRole: "text"
                valueRole: "value"
                enabled: !Configs.isKeyLocked("time.ntp_server")

                model: ListModel {
                    ListElement { text: "Cloudflare · time.cloudflare.com"; value: "time.cloudflare.com" }
                    ListElement { text: "NTP Pool · pool.ntp.org"; value: "pool.ntp.org" }
                    ListElement { text: "阿里云 · ntp.aliyun.com"; value: "ntp.aliyun.com" }
                    ListElement { text: "腾讯云 · ntp.tencent.com"; value: "ntp.tencent.com" }
                    ListElement { text: "Windows · time.windows.com"; value: "time.windows.com" }
                    ListElement { text: "自定义服务器"; value: "" }
                }

                Component.onCompleted: {
                    var server = Configs.data.time.ntp_server
                    for (var i = 0; i < model.count - 1; i++) {
                        if (model.get(i).value === server) {
                            currentIndex = i
                            return
                        }
                    }
                    currentIndex = model.count - 1
                }

                onActivated: function(index) {
                    var server = model.get(index).value
                    if (server.length === 0) {
                        customNtpServer.forceActiveFocus()
                        return
                    }
                    customNtpServer.text = server
                    Configs.set("time.ntp_server", server)
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("自定义 NTP 服务器")
            description: qsTr("填写域名或 IP 地址，例如 time.example.com")
            icon.name: "ic_fluent_edit_20_regular"

            TextField {
                id: customNtpServer
                Layout.preferredWidth: 260
                placeholderText: qsTr("NTP 服务器地址")
                enabled: !Configs.isKeyLocked("time.ntp_server")
                Component.onCompleted: text = Configs.data.time.ntp_server
                onEditingFinished: {
                    var server = text.trim()
                    if (server.length === 0) {
                        text = Configs.data.time.ntp_server
                        return
                    }
                    Configs.set("time.ntp_server", server)
                    for (var i = 0; i < ntpServerSelector.model.count - 1; i++) {
                        if (ntpServerSelector.model.get(i).value === server) {
                            ntpServerSelector.currentIndex = i
                            return
                        }
                    }
                    ntpServerSelector.currentIndex = ntpServerSelector.model.count - 1
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("同步时间")
            description: qsTr("立即从所选 NTP 服务器校时；失败后不会影响系统时间的使用")
            icon.name: "ic_fluent_arrow_sync_20_regular"

            ColumnLayout {
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: AppCentral.timeService.statusText
                    color: Colors.proxy.textSecondaryColor
                    wrapMode: Text.WordWrap
                }

                Button {
                    text: AppCentral.timeService.syncing ? qsTr("正在同步…") : qsTr("同步时间")
                    enabled: !AppCentral.timeService.syncing
                    onClicked: AppCentral.timeService.synchronizeTime()
                }
            }
        }

        Text {
            typography: Typography.BodyStrong
            text: qsTr("时间偏移")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_timer_20_regular"
            title: qsTr("时间偏移（秒）")
            description: qsTr("仅调整课程判断、倒计时与提醒时间；不会改变 NTP/系统真实时间或时间小组件显示")

            SpinBox {
                from: -86400
                to: 86400
                property bool initialized: false
                property string suffix: qsTr("秒")
                Layout.preferredWidth: 200
                enabled: !Configs.isKeyLocked("schedule.time_offset")
                onValueChanged: if (initialized) Configs.set("schedule.time_offset", value)
                Component.onCompleted: {
                    value = Configs.data.schedule.time_offset
                    initialized = true
                }
            }
        }
    }
}
