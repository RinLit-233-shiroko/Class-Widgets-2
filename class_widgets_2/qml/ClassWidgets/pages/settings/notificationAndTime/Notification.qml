import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects


FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42*2

    title: qsTr("Notification")

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("General")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_alert_on_20_regular"
            title: qsTr("Enable notifications")
            description: qsTr("Turn on or off all notifications from the application")

            Switch {
                checked: UtilsBackend.getNotificationsEnabled()
                onCheckedChanged: UtilsBackend.setNotificationsEnabled(checked)
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_resize_20_regular"
            title: qsTr("Ringtone")
            description: qsTr("Configure sounds for different types of notifications")
            
            action: Slider {
                id: notificationVolumeSlider
                width: 150
                value: UtilsBackend.getGlobalVolume()
                stepSize: 0.05
                from: 0
                to: 1
                onValueChanged: UtilsBackend.setGlobalVolume(value)
            }

            SettingItem {
                title: qsTr("Information")
                description: qsTr("Notification sounds for general information")

                Text {
                    Layout.fillWidth: true
                    text: {
                        let soundPath = UtilsBackend.getGlobalLevelSound(0)
                        if (soundPath) {
                            return soundPath.split('/').pop().split('\\').pop() // 获取文件名
                        } else {
                            return qsTr("Default sound")
                        }
                    }
                    wrapMode: Text.NoWrap
                    elide: Text.ElideLeft
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                }

                ToolButton {
                    icon.name: "ic_fluent_play_20_regular"
                    flat: true
                    ToolTip {
                        text: qsTr("Play sound")
                        visible: parent.hovered
                    }
                    onClicked: UtilsBackend.playNotificationSoundLevel(0) // INFO level
                }
                Button {
                    icon.name: "ic_fluent_folder_open_20_regular"
                    text: qsTr("Select sound")
                    onClicked: {
                        let soundPath = UtilsBackend.selectNotificationSound()
                        if (soundPath) {
                            UtilsBackend.setGlobalLevelSound(0, soundPath)
                        }
                    }
                }
            }

            SettingItem {
                title: qsTr("Announcement")
                description: qsTr("Notification sounds for class and break announcements")

                Text {
                    Layout.fillWidth: true
                    text: {
                        let soundPath = UtilsBackend.getGlobalLevelSound(1)
                        if (soundPath) {
                            return soundPath.split('/').pop().split('\\').pop() // 获取文件名
                        } else {
                            return qsTr("Default sound")
                        }
                    }
                    wrapMode: Text.NoWrap
                    elide: Text.ElideLeft
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                }

                ToolButton {
                    icon.name: "ic_fluent_play_20_regular"
                    ToolTip {
                        text: qsTr("Play sound")
                        visible: parent.hovered
                    }
                    flat: true
                    onClicked: UtilsBackend.playNotificationSoundLevel(1) // ANNOUNCEMENT level
                }
                Button {
                    icon.name: "ic_fluent_folder_open_20_regular"
                    text: qsTr("Select sound")
                    onClicked: {
                        let soundPath = UtilsBackend.selectNotificationSound()
                        if (soundPath) {
                            UtilsBackend.setGlobalLevelSound(1, soundPath)
                        }
                    }
                }
            }

            SettingItem {
                title: qsTr("Warning")
                description: qsTr("Notification sounds for warnings and important alerts")

                Text {
                    Layout.fillWidth: true
                    text: {
                        let soundPath = UtilsBackend.getGlobalLevelSound(2)
                        if (soundPath) {
                            return soundPath.split('/').pop().split('\\').pop() // 获取文件名
                        } else {
                            return qsTr("Default sound")
                        }
                    }
                    wrapMode: Text.NoWrap
                    elide: Text.ElideLeft
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                }

                ToolButton {
                    icon.name: "ic_fluent_play_20_regular"
                    ToolTip {
                        text: qsTr("Play sound")
                        visible: parent.hovered
                    }
                    flat: true
                    onClicked: UtilsBackend.playNotificationSoundLevel(2) // WARNING level
                }
                Button {
                    icon.name: "ic_fluent_folder_open_20_regular"
                    text: qsTr("Select sound")
                    onClicked: {
                        let soundPath = UtilsBackend.selectNotificationSound()
                        if (soundPath) {
                            UtilsBackend.setGlobalLevelSound(2, soundPath)
                        }
                    }
                }
            }

            SettingItem {
                title: qsTr("System")
                description: qsTr("Notification sounds for system messages and updates")

                Text {
                    Layout.fillWidth: true
                    text: {
                        let soundPath = UtilsBackend.getGlobalLevelSound(3)
                        if (soundPath) {
                            return soundPath.split('/').pop().split('\\').pop() // 获取文件名
                        } else {
                            return qsTr("Default sound")
                        }
                    }
                    wrapMode: Text.NoWrap
                    elide: Text.ElideLeft
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                }

                ToolButton {
                    icon.name: "ic_fluent_play_20_regular"
                    ToolTip {
                        text: qsTr("Play sound")
                        visible: parent.hovered
                    }
                    flat: true
                    onClicked: UtilsBackend.playNotificationSoundLevel(3) // SYSTEM level
                }
                Button {
                    icon.name: "ic_fluent_folder_open_20_regular"
                    text: qsTr("Select sound")
                    onClicked: {
                        let soundPath = UtilsBackend.selectNotificationSound()
                        if (soundPath) {
                            UtilsBackend.setGlobalLevelSound(3, soundPath)
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Providers")
        }

        // Helper function 判断图标是否为URL
        function isIconUrl(icon) {
            return icon && (icon.startsWith("file://") || icon.startsWith("http://") || icon.startsWith("https://"))
        }

        Repeater {
            model: UtilsBackend.notificationProviders
            delegate: Clip {
                Layout.fillWidth: true
                Layout.minimumHeight: 70
                id: frame

                // Helper function 判断图标是否为URL
                function isIconUrl(icon) {
                    return icon && (icon.startsWith("file://") || icon.startsWith("http://") || icon.startsWith("https://"))
                }

                TapHandler {
                    onTapped: {
                        notificationDialog.open()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        color: Colors.proxy.backgroundColor
                        radius: 12
                        width: 48
                        height: 48
                        border.color: Colors.proxy.controlBorderColor
                        border.width: 1

                        Icon {
                            id: providerIcon
                            name: !isIconUrl(modelData.icon) ? modelData.icon : ""
                            source: isIconUrl(modelData.icon) ? modelData.icon : ""
                            anchors.fill: parent
                            size: isIconUrl(modelData.icon) ? 48 : 32
                            opacity: isIconUrl(modelData.icon) ? 1 : 0.85

                            // 如果是图片文件，使用圆角遮罩
                            layer.enabled: isIconUrl(modelData.icon)
                            layer.effect: OpacityMask {
                                anchors.fill: parent
                                maskSource: Rectangle {
                                    width: providerIcon.width
                                    height: providerIcon.height
                                    radius: 12
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: modelData.name ? modelData.name : "Unknown Provider"
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            typography: Typography.BodyStrong
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.id
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            typography: Typography.Caption
                            color: Colors.proxy.textSecondaryColor
                        }
                    }

                    // 右侧区域
                    Icon {
                        size: 24
                        name: "ic_fluent_chevron_right_20_regular"
                        color: Colors.proxy.textSecondaryColor
                    }
                }

                Dialog {
                    id: notificationDialog
                    title: modelData.name ? modelData.name : "Unknown Provider"
                    standardButtons: Dialog.Ok | Dialog.Cancel
                    modal: true

                    property bool dialogEnabled: modelData ? modelData.enabled : false
                    property bool dialogSystemNotify: modelData ? modelData.useSystemNotify : false
                    property bool dialogAppNotify: modelData ? modelData.useAppNotify : false

                    Component.onCompleted: {
                        dialogEnabled = modelData.enabled
                        dialogSystemNotify = modelData.useSystemNotify
                        dialogAppNotify = modelData.useAppNotify
                    }

                    onAccepted: {
                        // 应用设置
                        UtilsBackend.setNotificationProviderEnabled(modelData.id, dialogEnabled)
                        UtilsBackend.setNotificationProviderSystemNotify(modelData.id, dialogSystemNotify)
                        UtilsBackend.setNotificationProviderAppNotify(modelData.id, dialogAppNotify)
                    }

                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true

                        SettingCard {
                            Layout.fillWidth: true
                            title: qsTr("Enable notifications")
                            description: qsTr("Turn on or off notifications from this provider")

                            Switch {
                                checked: notificationDialog.dialogEnabled
                                onCheckedChanged: {
                                    notificationDialog.dialogEnabled = checked
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignCenter
                            spacing: 16
                            ColumnLayout {
                                Layout.maximumWidth: 250
                                Image {
                                    Layout.alignment: Qt.AlignCenter
                                    Layout.maximumWidth: 250
                                    source: PathManager.images(
                                        "settings/notification/dynamic-" + (Theme.isDark()? "dark" : "light") + ".png"
                                    )
                                    fillMode: Image.PreserveAspectFit
                                }
                                CheckBox {
                                    Layout.fillWidth: true
                                    text: qsTr("Use Dynamic Notification")
                                    checked: notificationDialog.dialogAppNotify
                                    onCheckedChanged: {
                                        notificationDialog.dialogAppNotify = checked
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.maximumWidth: 250
                                Image {
                                    Layout.alignment: Qt.AlignCenter
                                    Layout.maximumWidth: 250
                                    source: PathManager.images(
                                        "settings/notification/system" +
                                        (Qt.platform.os === "windows" ? "_windows" : "") +
                                        "-" + (Theme.isDark() ? "dark" : "light") +
                                        ".png"
                                    )
                                    fillMode: Image.PreserveAspectFit
                                }
                                CheckBox {
                                    Layout.fillWidth: true
                                    text: qsTr("Use System Notification")
                                    checked: notificationDialog.dialogSystemNotify
                                    onCheckedChanged: {
                                        notificationDialog.dialogSystemNotify = checked
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}