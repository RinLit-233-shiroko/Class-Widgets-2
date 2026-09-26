import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Theme

// 独立的单例内容组件。外壳直接复用当前主题的 Widget，主题只需覆盖
// ClassWidgets/theme/components/FloatingWidget.qml 即可定制浮窗内容。
Widget {
    id: root

    implicitWidth: (notificationActive ? notificationLayout.implicitWidth : floatingLayout.implicitWidth) + 48
    implicitHeight: (notificationActive ? notificationLayout.implicitHeight : floatingLayout.implicitHeight) + 32
    height: implicitHeight

    property bool notificationActive: false
    property string notificationTitle: ""
    property string notificationMessage: ""
    property string notificationIcon: ""
    property int notificationLevel: -1
    property int notificationDuration: Configs.data.notifications.default_duration || 8000

    readonly property int notificationTextLimit: 20

    function limitedText(value) {
        var text = value || ""
        if (text.length <= notificationTextLimit)
            return text
        return text.slice(0, notificationTextLimit - 3) + "..."
    }

    function isIconUrl(icon) {
        return icon && (icon.startsWith("file://") || icon.startsWith("http://") || icon.startsWith("https://"))
    }

    function notificationLevelColor(level) {
        switch (level) {
        case 1: return "#46CEA3"
        case 2: return "#D83B01"
        case 3: return "#0078D4"
        default: return Utils.primaryColor
        }
    }

    function closeNotification() {
        notificationTimer.stop()
        notificationActive = false
    }

    Connections {
        target: AppCentral.notification
        function onNotified(payload) {
            if (!payload)
                return

            notificationTitle = limitedText(payload.title)
            notificationMessage = limitedText(payload.message)
            notificationIcon = payload.icon || ""
            notificationLevel = payload.level ?? 0
            notificationDuration = payload.duration || Configs.data.notifications.default_duration || 8000
            notificationActive = true
            notificationTimer.restart()
        }
    }

    Timer {
        id: notificationTimer
        interval: root.notificationDuration
        repeat: false
        onTriggered: root.closeNotification()
    }

    property var countdown: AppCentral.scheduleRuntime.remainingTime || { "minute": 0, "second": 0 }
    property color currentColor: {
        if (AppCentral.scheduleRuntime.currentSubject.color)
            return AppCentral.scheduleRuntime.currentSubject.color
        switch (AppCentral.scheduleRuntime.currentStatus) {
        case "free":
        case "break":
            return "#46CEA3"
        case "class":
            return "#D28B59"
        case "preparation":
            return "#9151d8"
        default:
            return "#605ed2"
        }
    }

    backgroundArea: Item {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: root.notificationLevelColor(root.notificationLevel)
            opacity: 0.6
            visible: root.notificationActive
        }

        // 光效圆圈
        Rectangle {
            id: circle
            width: root.height * 0.4
            height: root.height * 0.4
            x: (parent.width - width) / 2
            y: (parent.height - height) * 0.67
            radius: height / 2
            color: currentColor
            visible: lightingEffect && !root.notificationActive

            layer.enabled: true
            layer.effect: FastBlur {
                anchors.fill: circle
                radius: 64
                opacity: 0.5
                transparentBorder: true
            }
        }
    }

    ColumnLayout {
        id: floatingLayout
        visible: !root.notificationActive
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            // indicator drag
            Layout.alignment: Qt.AlignHCenter
            color: Colors.proxy.dividerBorderColor
            width: 48
            height: 4
            radius: 2
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 16

            ProgressRing {
                id: rin
                Layout.alignment: Qt.AlignVCenter
                size: 46
                value: AppCentral.scheduleRuntime.currentStatus !== "free" ? AppCentral.scheduleRuntime.progress : 0
                backgroundColor: Colors.proxy.controlAltQuaternaryColor
                primaryColor: root.currentColor
                strokeWidth: 6
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                Title {
                    font.pixelSize: 28
                    Layout.alignment: Qt.AlignRight
                    text: AppCentral.scheduleRuntime.currentEntry.title
                        || AppCentral.scheduleRuntime.currentSubject.name
                        || (AppCentral.scheduleRuntime.currentStatus === "class"
                          ? qsTr("Class")
                            : AppCentral.scheduleRuntime.currentStatus === "activity"
                          ? qsTr("Activity")
                            : AppCentral.scheduleRuntime.currentStatus === "break"
                          ? qsTr("Take a break")
                            : AppCentral.scheduleRuntime.currentStatus === "preparation"
                          ? qsTr("Class starting soon")
                          : qsTr("Nothing right now"))
                }
                // 左侧：文字 + 时间
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 0
                    opacity: 0.6
                    visible: AppCentral.scheduleRuntime.currentStatus !== "free"
                        || countdown.minute !== 0
                        || countdown.second !== 0

                    // min
                    Text {
                        visible: Configs.data.preferences.countdown_precision === "minute"
                        text: qsTr("< ")
                        font.pixelSize: 16
                    }
                    AnimatedDigits {
                        id: fuzzyMinute
                        visible: Configs.data.preferences.countdown_precision === "minute"
                        font.pixelSize: 16
                        value: String(Math.ceil((countdown.minute * 60 + countdown.second) / 60))
                    }
                    Text {
                        visible: Configs.data.preferences.countdown_precision === "minute"
                        text: qsTr(" min")
                        font.pixelSize: 16
                    }

                    // sec
                    AnimatedDigits {
                        id: minute
                        visible: Configs.data.preferences.countdown_precision !== "minute"
                        font.pixelSize: 16
                        value: String(countdown.minute || "00")
                    }
                    Title {
                        visible: Configs.data.preferences.countdown_precision !== "minute"
                        font.pixelSize: 16
                        Layout.bottomMargin: font.pixelSize * 0.1
                        text: ":"
                    }
                    AnimatedDigits {
                        font.pixelSize: 16
                        id: second
                        visible: Configs.data.preferences.countdown_precision !== "minute"
                        value: String(countdown.second).padStart(2, "0")
                    }
                }
            }
        }
    }

    // 灵动通知

    ToolButton {
        anchors{
            right: parent.right
            top: parent.top
            margins: -6
        }
        visible: root.notificationActive
        flat: true
        icon.name: "ic_fluent_dismiss_20_regular"
        color: "#FFF"
        implicitWidth: 24
        implicitHeight: 22
        size: 16
        onClicked: root.closeNotification()
    }

    ColumnLayout {
        id: notificationLayout
        visible: root.notificationActive
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            color: Colors.dark.dividerBorderColor
            width: 48
            height: 4
            radius: 2
        }

        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 16

            Icon {
                id: notificationIconComponent
                Layout.alignment: Qt.AlignVCenter
                name: !root.isIconUrl(root.notificationIcon)
                    ? (root.notificationIcon || "ic_fluent_alert_badge_20_regular") : ""
                source: root.isIconUrl(root.notificationIcon) ? root.notificationIcon : ""
                size: 46
                color: "#FFF"
                opacity: root.isIconUrl(root.notificationIcon) ? 1 : 0.9
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                MarqueeTitle {
                    id: notificationTitleLabel
                    Layout.alignment: Qt.AlignRight
                    maximumWidth: 180
                    color: "#FFF"
                    font.pixelSize: 28
                    text: root.notificationTitle
                    speed: 100
                    visible: text
                }
                MarqueeTitle {
                    opacity: 0.6
                    id: notificationMessageLabel
                    maximumWidth: 180
                    font.pixelSize: 16
                    color: "#FFF"
                    text: root.notificationMessage
                    speed: 100
                    visible: text
                }
            }
        }
    }

    Component.onCompleted: {
        if (AppCentral && AppCentral.notification)
            AppCentral.notification.notifyQmlReady()
    }
}
