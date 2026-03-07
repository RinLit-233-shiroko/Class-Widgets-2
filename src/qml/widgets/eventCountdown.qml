import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme
import Qt5Compat.GraphicalEffects

Widget {
    id: root
    text: qsTr("Remaining")
    property var countdown: AppCentral.scheduleRuntime.remainingTime || { "minutes": 0, "seconds": 0 }

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
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                spacing: 0
                Layout.topMargin: miniMode ? 0 : -4
                Layout.alignment: Qt.AlignHCenter

                AnimatedDigits {
                    id: minute
                    value: countdown.minute || "00"
                }
                Title {
                    Layout.bottomMargin: font.pixelSize * 0.1
                    text: ":"
                }
                AnimatedDigits {
                    id: second
                    value: (countdown.second + "").padStart(2, "0") || "00"
                }
            }

            // 进度条仅在非 miniMode 下显示在下方
            ProgressBar {
                id: progressBar
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 82
                Layout.preferredHeight: 4
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
}
