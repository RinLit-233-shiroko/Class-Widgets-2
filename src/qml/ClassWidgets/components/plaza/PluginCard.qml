import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI
import Qt5Compat.GraphicalEffects

Clip {
    id: root
    property var plugin: ({})
    property bool isLoading: false

    Loader {
        anchors.fill: parent
        anchors.margins: 12
        // anchors.fill: parent
        sourceComponent: root.isLoading ? skeletonComponent : contentComponent
    }

    Component {
        id: skeletonComponent
        RowLayout {
            width: root.width
            height: root.height
            anchors.margins: 12
            spacing: 12

            Rectangle {
                width: 56
                height: 56
                radius: 12
                color: Colors.proxy.controlBorderColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Rectangle {
                    width: parent.width
                    height: 16
                    radius: 4
                    color: Colors.proxy.controlBorderColor
                }

                Rectangle {
                    width: parent.width * 0.6
                    height: 14
                    radius: 4
                    color: Colors.proxy.controlBorderColor
                }

                Rectangle {
                    width: parent.width
                    height: 14
                    radius: 4
                    color: Colors.proxy.controlBorderColor
                }
            }
        }
    }

    Component {
        id: contentComponent
        RowLayout {
            width: root.width
            height: root.height
            anchors.margins: 12
            spacing: 12

            Rectangle {
                width: 56
                height: 56
                radius: 12
                color: Colors.proxy.backgroundColor
                border.color: Colors.proxy.controlBorderColor
                border.width: 1
                clip: true

                Image {
                    id: pluginIcon
                    anchors.fill: parent
                    anchors.margins: 1
                    source: root.plugin && root.plugin.id ? ("https://plaza.cw.rinlit.cn/api/plugins/" + root.plugin.id + "/resources/icon") : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true

                    onStatusChanged: {
                        if (status === Image.Error) {
                            source = "https://plaza.cw.rinlit.cn/api/plugins/default/resources/icon"
                        }
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        anchors.fill: pluginIcon
                        maskSource: Rectangle {
                            width: pluginIcon.width
                            height: pluginIcon.height
                            radius: 12
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.plugin && root.plugin.name ? root.plugin.name : qsTr("Unknown")
                    typography: Typography.BodyStrong
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.plugin ? (root.plugin.author) : qsTr("Unknown")
                    typography: Typography.Caption
                    color: Colors.proxy.primaryColor
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }  // author

                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    text: root.plugin ? (root.plugin.description || root.plugin.desc || root.plugin.summary || "") : ""
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            // Icon {
            //     Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            //     size: 20
            //     name: "ic_fluent_chevron_right_20_regular"
            //     color: Colors.proxy.textSecondaryColor
            // }
        }
    }
}
