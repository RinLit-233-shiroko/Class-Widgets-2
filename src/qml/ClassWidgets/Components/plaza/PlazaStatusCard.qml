import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components
import RinUI

Clip {
    id: root

    property string pluginName: ""
    property string pluginAuthor: ""
    property string pluginIcon: ""

    property string middleText: ""
    property color middleTextColor: Colors.proxy.textSecondaryColor
    property bool showProgress: false
    property real progressValue: 0
    property bool progressIndeterminate: false
    property int progressWidth: 240

    property bool primaryActionVisible: false
    property bool primaryActionEnabled: true
    property string primaryActionText: ""
    property string primaryActionIcon: ""
    property bool cancelVisible: false

    signal primaryActionRequested()
    signal openStoreRequested()
    signal copyLinkRequested()
    signal cancelRequested()

    Layout.fillWidth: true
    Layout.minimumHeight: 82

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                Layout.alignment: Qt.AlignVCenter
                radius: 12
                color: statusIcon.iconFailed ? "#ccc" : Colors.proxy.backgroundColor
                border.color: Colors.proxy.controlBorderColor
                border.width: 1
                clip: true

                Skeleton {
                    anchors.fill: parent
                    radius: parent.radius
                    running: !!root.pluginIcon && !statusIcon.iconLoaded && !statusIcon.iconFailed
                    visible: running
                }

                Image {
                    id: statusIcon
                    anchors.fill: parent
                    source: root.pluginIcon
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    visible: iconLoaded

                    property bool iconLoaded: false
                    readonly property bool iconFailed: status === Image.Error || source === ""

                    onStatusChanged: {
                        if (status === Image.Ready)
                            iconLoaded = true
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        anchors.fill: statusIcon
                        maskSource: Rectangle {
                            width: statusIcon.width
                            height: statusIcon.height
                            radius: 12
                        }
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    visible: !root.pluginIcon || statusIcon.iconFailed
                    name: "ic_fluent_apps_20_regular"
                    size: 22
                    opacity: 0.65
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.pluginName
                    typography: Typography.BodyStrong
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    visible: !!root.pluginAuthor
                    text: root.pluginAuthor
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                    elide: Text.ElideRight
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 5

            Text {
                Layout.fillWidth: true
                Layout.maximumWidth: root.progressWidth
                Layout.alignment: Qt.AlignHCenter
                text: root.middleText
                // typography: Typography.Caption
                color: root.middleTextColor
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            ProgressBar {
                visible: root.showProgress
                Layout.fillWidth: true
                Layout.maximumWidth: root.progressWidth
                Layout.alignment: Qt.AlignHCenter
                value: root.progressValue
                indeterminate: root.progressIndeterminate
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.minimumWidth: 0
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 6

            Item {
                Layout.fillWidth: true
            }

            Button {
                visible: root.primaryActionVisible
                enabled: root.primaryActionEnabled
                text: root.primaryActionText
                icon.name: root.primaryActionIcon
                onClicked: root.primaryActionRequested()
            }

            ToolButton {
                flat: true
                icon.name: "ic_fluent_more_horizontal_20_regular"
                onClicked: moreMenu.open()

                ToolTip {
                    visible: parent.hovered
                    text: qsTr("More options")
                }

                Menu {
                    id: moreMenu

                    MenuItem {
                        icon.name: "ic_fluent_open_20_regular"
                        text: qsTr("Open in Plugin Plaza")
                        onTriggered: root.openStoreRequested()
                    }
                    MenuItem {
                        icon.name: "ic_fluent_copy_20_regular"
                        text: qsTr("Copy link")
                        onTriggered: root.copyLinkRequested()
                    }
                    MenuSeparator {
                        visible: root.cancelVisible
                    }
                    MenuItem {
                        visible: root.cancelVisible
                        icon.name: "ic_fluent_dismiss_20_regular"
                        text: qsTr("Cancel download")
                        onTriggered: root.cancelRequested()
                    }
                }
            }
        }
    }
}
