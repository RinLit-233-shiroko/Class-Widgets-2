import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Item {
    id: root
    transformOrigin: Item.Center

    property var tutorial
    property real pageTransitionOffset: 0
    property real visualTransitionOpacity: 1
    property bool completing: false

    function finishSetup() {
        if (completing)
            return

        completing = true
        UtilsBackend.setAutostart(Configs.data.app.auto_startup)
        UtilsBackend.setNotificationsEnabled(Configs.data.notifications.enabled)

        if (tutorial.createShortcutOnComplete && Qt.platform.os === "windows")
            UtilsBackend.createDesktopShortcut()

        tutorial.completeTutorial()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 64
        spacing: 42

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            spacing: 32

            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 92
                Layout.preferredHeight: 92
                source: PathManager.images("icons/cw2_up_to_date.png")
                fillMode: Image.PreserveAspectFit
            }

            Text {
                Layout.alignment: Qt.AlignCenter
                text: qsTr("Welcome to Class Widgets")
                typography: Typography.Title
            }

            // Text {
            //     Layout.alignment: Qt.AlignCenter
            //     Layout.maximumWidth: 440
            //     text: qsTr("Class Widgets is ready. Your selected plugins will be available after restart.")
            //     typography: Typography.Body
            //     horizontalAlignment: Text.AlignHCenter
            //     wrapMode: Text.WordWrap
            // }
        }

        Button {
            Layout.alignment: Qt.AlignCenter
            highlighted: true
            enabled: !root.completing
            // icon.name: "ic_fluent_checkmark_20_regular"
            text: qsTr("Get Started")
            onClicked: root.finishSetup()
        }
    }
}
