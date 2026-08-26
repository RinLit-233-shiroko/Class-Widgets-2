import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Debugger


ColumnLayout {
    Layout.fillWidth: true

    function formatBytes(bytes) {
        if (bytes < 1024)
            return bytes + " B"
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KiB"
        return (bytes / (1024 * 1024)).toFixed(2) + " MiB"
    }

    Text {
        typography: Typography.BodyStrong
        text: qsTr("仪表盘")
    }

    Frame {
        Layout.fillWidth: true

        ColumnLayout {
            anchors.fill: parent
            Layout.topMargin: 12
            Layout.bottomMargin: 12
            spacing: 8

            Text {
                text: "内存日志"
                typography: Typography.BodyStrong
            }

            Text {
                Layout.fillWidth: true
                color: Colors.proxy.textSecondaryColor
                wrapMode: Text.WordWrap
                text: "当前缓冲：%1 / %2 条，估算占用 %3；运行期峰值 %4。"
                    .arg(UtilsBackend.logCount)
                    .arg(UtilsBackend.maxLogLines)
                    .arg(formatBytes(UtilsBackend.logBufferBytes))
                    .arg(formatBytes(UtilsBackend.logBufferPeakBytes))
            }

            Text {
                Layout.fillWidth: true
                color: Colors.proxy.textSecondaryColor
                visible: UtilsBackend.logCount > 0
                text: "时间范围：%1 ～ %2"
                    .arg(UtilsBackend.logFirstTime)
                    .arg(UtilsBackend.logLastTime)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: logsList.autoScroll ? "暂停自动滚动" : "恢复自动滚动"
                    onClicked: {
                        logsList.autoScroll = !logsList.autoScroll
                        if (logsList.autoScroll)
                            logsList.positionViewAtEnd()
                    }
                }

                Button {
                    text: "复制全部"
                    enabled: UtilsBackend.logCount > 0
                    onClicked: {
                        if (UtilsBackend.copyToClipboard(JSON.stringify(UtilsBackend.logs, null, 2))) {
                            floatLayer.createInfoBar({
                                severity: Severity.Success,
                                text: "已复制内存日志"
                            })
                        }
                    }
                }

                Button {
                    text: "清空内存日志"
                    enabled: UtilsBackend.logCount > 0
                    onClicked: UtilsBackend.clearMemoryLogs()
                }
            }

            ListView {
                id: logsList
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                clip: true
                model: UtilsBackend.logs
                spacing: 0
                property bool autoScroll: true

                onCountChanged: {
                    if (autoScroll)
                        positionViewAtEnd()
                }

                delegate: Frame {
                    width: logsList.width
                    HoverHandler { id: logHoverHandler }
                    frameless: !logHoverHandler.hovered
                    leftPadding: 12
                    padding: 4

                    RowLayout {
                        width: parent.width
                        spacing: 10

                        Text {
                            Layout.preferredWidth: 90
                            text: modelData.time
                            color: Colors.proxy.textSecondaryColor
                        }

                        Text {
                            Layout.preferredWidth: 80
                            text: modelData.level
                            color: {
                                switch (modelData.level) {
                                    case "DEBUG": return Colors.proxy.systemNeutralColor
                                    case "INFO": return Colors.proxy.textColor
                                    case "WARNING": return Colors.proxy.systemCautionColor
                                    case "ERROR": return Colors.proxy.systemCriticalColor
                                    case "SUCCESS": return Colors.proxy.systemSuccessColor
                                    default: return Colors.proxy.textColor
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.message
                            color: {
                                switch (modelData.level) {
                                    case "DEBUG": return Colors.proxy.systemNeutralColor
                                    case "INFO": return Colors.proxy.textColor
                                    case "WARNING": return Colors.proxy.systemCautionColor
                                    case "ERROR": return Colors.proxy.systemCriticalColor
                                    case "SUCCESS": return Colors.proxy.systemSuccessColor
                                    default: return Colors.proxy.textColor
                                }
                            }
                            elide: Text.ElideRight
                        }

                        ToolButton {
                            flat: true
                            icon.name: "ic_fluent_copy_20_regular"
                            size: 18
                            onClicked: {
                                if (UtilsBackend.copyToClipboard(JSON.stringify(modelData))) {
                                    floatLayer.createInfoBar({
                                        severity: Severity.Success,
                                        text: "已复制日志条目"
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Expander {
        text: qsTr("运行时变量")
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 12

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("重新加载课程表文件")
                    onClicked: AppCentral.scheduleManager.reload()
                }
            }

            Text {
                typography: Typography.BodyStrong
                text: qsTr("课程表运行时")
            }

            VarStatus {
                Layout.fillWidth: true
                columns: 3
                Layout.preferredHeight: 350
                model: [
                    { name: qsTr("当前时间"), value: AppCentral.scheduleRuntime.currentTime },
                    { name: qsTr("当前日期"), value: JSON.stringify(AppCentral.scheduleRuntime.currentDate) },
                    { name: qsTr("当前星期"), value: AppCentral.scheduleRuntime.currentDayOfWeek },
                    { name: qsTr("当前周数"), value: AppCentral.scheduleRuntime.currentWeek },
                    { name: qsTr("周期周数"), value: AppCentral.scheduleRuntime.currentWeekOfCycle },
                    { name: qsTr("课表元数据"), value: JSON.stringify(AppCentral.scheduleRuntime.scheduleMeta) },
                    { name: qsTr("当天条目"), value: JSON.stringify(AppCentral.scheduleRuntime.currentDayEntries) },
                    { name: qsTr("当前条目"), value: JSON.stringify(AppCentral.scheduleRuntime.currentEntry) },
                    { name: qsTr("后续条目"), value: JSON.stringify(AppCentral.scheduleRuntime.nextEntries) },
                    { name: qsTr("剩余时间"), value: JSON.stringify(AppCentral.scheduleRuntime.remainingTime) },
                    { name: qsTr("当前状态"), value: AppCentral.scheduleRuntime.currentStatus },
                    { name: qsTr("当前学科"), value: JSON.stringify(AppCentral.scheduleRuntime.currentSubject) },
                    { name: qsTr("当前标题"), value: AppCentral.scheduleRuntime.currentTitle }
                ]
            }
        }
    }
}
