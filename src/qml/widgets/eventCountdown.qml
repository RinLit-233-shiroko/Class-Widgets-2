import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme
import Qt5Compat.GraphicalEffects

Widget {
    id: root
    text: {
        AppCentral.translator.language
        return qsTr("Remaining")
    }
    property var countdown: AppCentral.scheduleRuntime.remainingTime || { "minute": 0, "second": 0 }

    readonly property bool animated: !settings || settings.digit_animation !== false

    // 统一布局，用 RowLayout 并根据 miniMode 控制内部排列
    RowLayout {
        anchors.centerIn: parent
        spacing: miniMode ? 12 : 0

        ProgressRing {
            // miniMode 下进度环
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignCenter
            value: AppCentral.scheduleRuntime.progress
            visible: miniMode
            strokeWidth: 4
            backgroundColor: Qt.alpha(Colors.proxy.controlStrongColor, 0.2)
            primaryColor: progressBar.primaryColor
        }

        // 左侧：文字 + 时间
        ColumnLayout {
            id: countdownLayout
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 0
                Layout.topMargin: miniMode ? 0 : -4
                Layout.alignment: Qt.AlignHCenter

                // 「按分钟」精度：只显示模糊分钟数
                Loader {
                    visible: Configs.data.preferences.countdown_precision === "minute"
                    sourceComponent: root.animated ? fuzzyMinuteAnimated : fuzzyMinuteStatic
                }
                Title {
                    visible: Configs.data.preferences.countdown_precision === "minute"
                    text: qsTr(" min")
                }

                // 「分:秒」精度
                Loader {
                    visible: Configs.data.preferences.countdown_precision !== "minute"
                    sourceComponent: root.animated ? minuteAnimated : minuteStatic
                }
                Title {
                    visible: Configs.data.preferences.countdown_precision !== "minute"
                    Layout.bottomMargin: font.pixelSize * 0.1
                    text: ":"
                }
                Loader {
                    visible: Configs.data.preferences.countdown_precision !== "minute"
                    sourceComponent: root.animated ? secondAnimated : secondStatic
                }
            }

            // 进度条仅在非 miniMode 下显示在下方
            ProgressBar {
                id: progressBar
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Configs.data.preferences.countdown_precision === "minute" ?
                    (countdownLayout.implicitWidth - 16) : 82
                // Layout.preferredHeight: 4
                value: AppCentral.scheduleRuntime.progress
                visible: !miniMode
                primaryColor: {
                    switch (AppCentral.scheduleRuntime.currentStatus) {
                        case "free": case "break": return Theme.isDark()? "#46CEA3" : "#2eaa76"
                        case "class": return Theme.isDark()? "#e4a274" : "#dd986f"
                        default: return "#605ed2"
                    }
                }
            }
        }
    }

    // —— 四个数字显示变体：动画 / 静态，各两种精度 ——
    Component {
        id: fuzzyMinuteAnimated
        AnimatedDigits {
            value: String(Math.ceil((countdown.minute * 60 + countdown.second) / 60))
        }
    }
    Component {
        id: fuzzyMinuteStatic
        Title {
            text: String(Math.ceil((countdown.minute * 60 + countdown.second) / 60))
        }
    }
    Component {
        id: minuteAnimated
        AnimatedDigits {
            value: countdown.minute || "00"
        }
    }
    Component {
        id: minuteStatic
        Title {
            text: countdown.minute || "00"
        }
    }
    Component {
        id: secondAnimated
        AnimatedDigits {
            value: (countdown.second + "").padStart(2, "0") || "00"
        }
    }
    Component {
        id: secondStatic
        Title {
            text: (countdown.second + "").padStart(2, "0") || "00"
        }
    }
}
