import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


ApplicationWindow {
    id: mainWindow
    title: qsTr("ClassWidgets 调试器")
    // x: Screen.width/2 - width/2
    // y:600
    width: 900
    height: 800
    minimumWidth: 425
    minimumHeight: 400
    // visible: true

    // color: {
    //     if (Theme.isDark()) {
    //         return "#333"
    //     } else {
    //         return "#eee"
    //     }
    // }

    // notification signal from AppCentral.notification.notify
    Item {
        id: notificationLayer
        property var level: [Severity.Info, Severity.Success, Severity.Warning, Severity.Error]

        Connections {
            target: AppCentral.notification
            onNotify: (icon, level, title, message) => {
                floatLayer.createInfoBar({
                    severity: notificationLayer.level[level],
                    title: title,
                    text: message
                })
            }
        }
    }


    FluentPage {
        anchors.fill: parent
        title: qsTr("ClassWidgets 调试器")

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            Text {
                Layout.alignment: Qt.AlignHCenter
                typography: Typography.Subtitle
                text: qsTr("当前时间：") + AppCentral.scheduleRuntime.currentTime
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                property var date: AppCentral.scheduleRuntime.currentDate
                typography: Typography.Caption
                Layout.fillWidth: true
                text: (
                    qsTr("当前日期：") + date.year + "-" + date.month + "-" + date.day + "\n" +
                    qsTr("（时间信息来自 ClassWidgets → AppCentral.scheduleRuntime）")
                )
            }
        }

        // 面板
        Dashboard {}

        // 概览
        Overview {}


    }

    // fix
    onClosing: function(event) {
        event.accepted = false
        mainWindow.hide()
    }
}
