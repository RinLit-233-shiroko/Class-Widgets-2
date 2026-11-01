import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../../Components/tutorial" as TutorialComponents

TutorialComponents.TutorialPage {
    id: root

    property var tutorial

    title: qsTr("Preferences")
    description: qsTr("Choose a few defaults before selecting plugins.")
    currentStep: 5
    totalSteps: 7
    // nextText: qsTr("Choose plugins")
    icon.source: PathManager.images("icons/cw2_settings.png")
    nextIcon: "ic_fluent_arrow_right_20_regular"

    onNextRequested: root.tutorial.goNext()

    ColumnLayout {
        width: parent.width
        spacing: 4

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_open_20_regular"
            title: qsTr("Run at Startup")
            description: qsTr("Open Class Widgets automatically when you sign in")

            Switch {
                enabled: !Configs.isKeyLocked("app.auto_startup") && UtilsBackend.autostartSupported
                onCheckedChanged: {
                    Configs.set("app.auto_startup", checked)
                    UtilsBackend.setAutostart(checked)
                }
                Component.onCompleted: {
                    if (!UtilsBackend.autostartEnabled()) {
                        checked = false
                        Configs.set("app.auto_startup", checked)
                        return
                    }
                    checked = Configs.data.app.auto_startup
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            visible: Qt.platform.os === "windows"
            icon.name: "ic_fluent_desktop_20_regular"
            title: qsTr("Create Desktop Shortcut")
            description: qsTr("Add a shortcut to your desktop after setup completes")

            Switch {
                checked: root.tutorial ? root.tutorial.createShortcutOnComplete : false
                onCheckedChanged: {
                    if (root.tutorial)
                        root.tutorial.createShortcutOnComplete = checked
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            enabled: !Configs.isKeyLocked("notifications.enabled")
            icon.name: "ic_fluent_alert_on_20_regular"
            title: qsTr("Enable Notifications")
            description: qsTr("Allow reminders, schedule updates, and plugin messages")

            Switch {
                onCheckedChanged: Configs.set("notifications.enabled", checked)
                Component.onCompleted: checked = Configs.data.notifications.enabled
            }
        }
    }
}
