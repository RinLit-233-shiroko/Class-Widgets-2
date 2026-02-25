import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    title: qsTr("Class Widgets Update")

    property string updaterLatestVersion: ""
    property string updaterLatestUrl: ""
    property string errorDetails: ""

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Image {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                source: {
                    switch (UpdaterBridge.status) {
                        case "UpToDate":
                            return PathManager.images("icons/cw2_up_to_date.png")
                        case "UpdateAvailable":
                            return PathManager.images("icons/cw2_update_available.png")
                        case "Downloading":
                            return PathManager.images("icons/cw2_update.png")
                        case "Downloaded":
                            return PathManager.images("icons/cw2_update.png")
                        case "Installing":
                            return PathManager.images("icons/cw2_settings.png")
                        case "Error":
                            return PathManager.images("icons/cw2_error.png")
                        default:
                            return PathManager.images("icons/cw2_update.png")
                    }
                }
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    typography: Typography.BodyLarge
                    text: {
                        switch (UpdaterBridge.status) {
                            case "Checking":
                                return qsTr("Checking for updates...")
                            case "UpToDate":
                                return qsTr("You're up to date!")
                            case "UpdateAvailable":
                                return qsTr("New version available!")
                            case "Downloading":
                                return qsTr("Downloading update...")
                            case "Installing":
                                return qsTr("Installing update...")
                            case "Downloaded":
                                return qsTr("Update ready to install")
                            case "Error":
                                return qsTr("Update failed")
                            case "Cancelled":
                                return qsTr("Download cancelled")
                            default:
                                return qsTr("Check for updates")
                        }
                    }
                }

                Text {
                    id: details
                    Layout.fillWidth: true
                    color: Colors.proxy.textSecondaryColor
                    typography: Typography.Caption
                    text: {
                        switch (UpdaterBridge.status) {
                            case "Checking":
                                return qsTr("Waiting for response...")
                            case "UpToDate":
                                return qsTr("You're on the latest version")
                            case "UpdateAvailable":
                                return updaterLatestVersion ? qsTr("Latest version: %1").arg(updaterLatestVersion) : qsTr("New version available")
                            case "Downloading": {
                                const percent = UpdaterBridge.progress.toFixed(1)
                                const speedKB = UpdaterBridge.speed / 1024
                                const speedText = speedKB >= 1024
                                    ? qsTr("%1 MB/s").arg((speedKB / 1024).toFixed(1))
                                    : qsTr("%1 KB/s").arg(speedKB.toFixed(1))
                                return qsTr("Progress: %1% — %2").arg(percent).arg(speedText)
                            }
                            case "Installing":
                                return qsTr("Applying the update...")
                            case "Downloaded":
                                return qsTr("Ready to install now")
                            case "Error":
                                return root.errorDetails !== "" ? root.errorDetails : qsTr("Something went wrong!")
                            case "Cancelled":
                                return qsTr("Download was cancelled")
                            default:
                                return qsTr("Click \"Check for updates\" to search for updates")
                        }
                    }
                    wrapMode: Text.Wrap
                }
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            opacity: UpdaterBridge.status === "Downloading" || UpdaterBridge.status === "Installing" || UpdaterBridge.status === "Checking"
            value: UpdaterBridge.status === "Downloading" ? (UpdaterBridge.progress / 100) : 0
            indeterminate: UpdaterBridge.status !== "Downloading"
        }

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignRight

            // 检查更新
            Button {
                id: checkBtn
                text: qsTr("Check for updates")
                // icon.name: "ic_fluent_box_checkmark_20_regular"
                visible: {
                    switch (UpdaterBridge.status) {
                        case "Idle":
                        case "Error":
                        case "UpToDate":
                        case "Checking":
                        case "UpdateAvailable":
                            return true
                        default:
                            return false
                    }
                }
                highlighted: UpdaterBridge.status !== "UpdateAvailable"
                    || (UpdaterBridge.status === "UpdateAvailable" && !downloadBtn.visible)
                enabled: UpdaterBridge.status !== "Checking"
                onClicked: {
                    root.errorDetails = ""
                    updaterLatestVersion = ""
                    updaterLatestUrl = ""
                    UpdaterBridge.checkUpdate()
                }
            }

            // 下载更新（只有有 url 时可见）
            Button {
                id: downloadBtn
                text: qsTr("Download")
                icon.name: "ic_fluent_arrow_download_20_regular"
                highlighted: true
                visible: UpdaterBridge.status === "UpdateAvailable" && updaterLatestUrl !== ""
                onClicked: {
                    root.errorDetails = ""
                    UpdaterBridge.startDownload()
                }
            }

            // 取消下载
            Button {
                id: cancelBtn
                icon.name: "ic_fluent_dismiss_20_regular"
                text: qsTr("Cancel")
                visible: UpdaterBridge.status === "Downloading"
                onClicked: {
                    UpdaterBridge.stopDownload()
                }
            }

            // 安装更新（重启以安装）
            Button {
                id: restartBtn
                highlighted: true
                icon.name: "ic_fluent_arrow_counterclockwise_20_regular"
                text: qsTr("Restart and Install")
                visible: UpdaterBridge.status === "Downloaded"
                onClicked: {
                    UpdaterBridge.startInstall()
                }
            }
        }
    }

    // “更多选项”
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("More options")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_channel_20_regular"
            title: qsTr("Update Channel")
            description: qsTr("Choose which update channel to use")

            ComboBox {
                model: ListModel {
                    ListElement { text: qsTr("Release"); value: "release" }
                    ListElement { text: qsTr("Alpha"); value: "alpha" }
                }
                textRole: "text"
                valueRole: "value"
                onCurrentValueChanged: if (focus) Configs.set("app.channel", currentValue)
                Component.onCompleted: {
                    switch (Configs.data.app.channel) {
                        case "release": currentIndex = 0; break
                        case "alpha": currentIndex = 1; break
                        default:
                            currentIndex = 0
                            Configs.set("app.channel", "release")
                            break
                    }
                }
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_network_check_20_regular"
            title: qsTr("Use Mirror Source")
            description: qsTr("If GitHub is slow or unavailable in your region, use a mirror to download updates faster")

            action: Switch {
                onCheckedChanged: Configs.set("network.mirror_enabled", checked)
                Component.onCompleted: checked = Configs.data.network.mirror_enabled
            }

            SettingItem {
                title: qsTr("Select Mirror")
                description: qsTr("Choose a mirror source for downloading updates")

                ComboBox {
                    Layout.fillWidth: true
                    id: mirrorCombo
                    model: Object.keys(Configs.data.network.mirrors)
                    textRole: ""

                    onCurrentTextChanged: if (focus) Configs.set("network.current_mirror", currentText)
                    Component.onCompleted: {
                        for (var i = 0; i < model.count; i++) {
                            if (model.get(i) === Configs.data.network.current_mirror) {
                                currentIndex = i
                                break
                            }
                        }
                    }

                    delegate: ItemDelegate {
                        text: modelData + " (" + Configs.data.network.mirrors[modelData] + ")"
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_arrow_sync_checkmark_20_regular"
            title: qsTr("Auto check for updates")
            description: qsTr(
                "Automatically check for updates and download them when they are available \n" +
                "* Requires restart"
            )

            Switch {
                onCheckedChanged: Configs.set("network.auto_check_updates", checked)
                Component.onCompleted: checked = Configs.data.network.auto_check_updates
            }
        }
    }

    ColumnLayout {
        visible: Configs.data.app.debug_mode

        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Advanced")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_cloud_link_20_regular"
            title: qsTr("Updater Server URL")
            description: qsTr(
                "Set a custom URL to use for the updater server"
            )

            RowLayout {
                spacing: 4
                ToolButton {
                    icon.name: "ic_fluent_arrow_reset_20_regular"
                    onClicked: {
                        urlField.text = "https://classwidgets.rinlit.cn/2/releases.json/"
                        Configs.set("network.releases_url", "https://classwidgets.rinlit.cn/2/releases.json/")
                    }

                    ToolTip {
                        text: qsTr("Reset to default")
                        visible: parent.hovered
                    }
                }

                TextField {
                    id: urlField
                    Layout.fillWidth: true
                    placeholderText: qsTr("https://example.com/releases.json/")
                    onTextChanged: if (focus) Configs.set("network.releases_url", text)
                    Component.onCompleted: text = Configs.data.network.releases_url
                }
            }
        }
    }

    // 连接 Python 信号
    Connections {
        target: UpdaterBridge

        function onUpdateAvailable(version, url) {
            root.updaterLatestVersion = version
            root.updaterLatestUrl = url || ""
        }

        // 当 errorDetails 属性改变时触发（bridge 发 errorDetailsChanged）
        function onErrorDetailsChanged(message) {
            root.errorDetails = message
        }

        // 也监听后端的 errorOccurred 信号（如果后端发这个）
        function onErrorOccurred(message) {
            root.errorDetails = message
        }

        // 下载完成准备安装
        function onInstallReady(version) {
            // backend 会发 installReady(version) -> 切换到 Downloaded 状态
            root.updaterLatestVersion = version
        }
    }
}
