import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import RinUI

Item {
    id: root

    width: 146
    height: 224
    implicitWidth: 146
    implicitHeight: 224

    property var plugin: ({})
    property bool showRating: false
    property bool navigationEnabled: true
    property url detailPage: Qt.resolvedUrl("../../pages/plaza/Plugin.qml")

    readonly property string pluginId: plugin && plugin.id ? plugin.id : ""
    readonly property string pluginName: plugin && plugin.name ? plugin.name : qsTr("Unknown plugin")
    readonly property string authorName: plugin
        ? (plugin.author || plugin.owner_name || plugin.owner_id || qsTr("Unknown author"))
        : qsTr("Unknown author")
    readonly property real ratingAverage: plugin ? Number(plugin.rating_average || 0) : 0
    readonly property int ratingCount: plugin ? Number(plugin.rating_count || 0) : 0
    // 无图标（加载失败或无 pluginId）时预览区显示纯色占位
    readonly property bool iconMissing: pluginIcon.status === Image.Error || root.pluginId.length === 0

    function resourceUrl(pluginId, resource) {
        return pluginId ? PlazaBridge.baseUrl + "/api/plugins/" + encodeURIComponent(pluginId) + "/resources/" + resource : ""
    }

    // ── 悬停上浮 + 阴影 ──
    property real liftY: card.hovered ? -2 : 0

    z: card.hovered ? 1 : 0
    transform: Translate { y: root.liftY }

    Behavior on liftY { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // 独立不透明圆角矩形作为阴影源（透明背景卡片无法直接对控件做 layer 阴影）
    Rectangle {
        id: shadowSource
        anchors.fill: parent
        radius: card.radius
        color: Colors.proxy.backgroundColor
        opacity: card.hovered ? 1 : 0

        layer.enabled: opacity > 0
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: "#333333"
            shadowOpacity: 0.1
            shadowVerticalOffset: 3
            shadowBlur: 0.6
        }
    }

    Clip {
        id: card
        anchors.fill: parent

        onClicked: {
            if (root.navigationEnabled && root.pluginId)
                navigationView.safePush(root.detailPage, true, false, { pluginId: root.pluginId })
        }

        background: Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: card.down ? Colors.proxy.controlPressedColor
                 : card.hovered ? Colors.proxy.controlFillColor
                 : card.backgroundColor
            border.color: Colors.proxy.controlBorderColor
            border.width: 1
        }

        Item {
            anchors.fill: parent

            Item {
                id: preview
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 128
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Item {
                        width: preview.width
                        height: preview.height

                        Rectangle {
                            anchors.fill: parent
                            radius: card.radius
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: card.radius
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Colors.proxy.controlAltSecondaryColor
                }

                Image {
                    // 模糊图                       //
                    id: blurredIcon
                    anchors.centerIn: parent
                    width: parent.width * 1.55
                    height: parent.height * 1.55
                    source: root.resourceUrl(root.pluginId, "icon")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: 1
                    visible: status === Image.Ready

                    layer.enabled: status === Image.Ready
                    layer.effect: FastBlur {
                        radius: 64
                        transparentBorder: false
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.isDark() ? "#28101820" : "#24FFFFFF"
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 48
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00FFFFFF" }
                        GradientStop { position: 1.0; color: Theme.isDark() ? "#24101820" : "#30FFFFFF" }
                    }
                }

                Image {
                    id: pluginIcon
                    anchors.centerIn: parent
                    width: 80
                    height: 80
                    source: root.resourceUrl(root.pluginId, "icon")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                }

                // 无图标时的纯色占位
                Rectangle {
                    anchors.fill: parent
                    color: "#ccc"
                    visible: root.iconMissing
                }
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: preview.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 7
                anchors.bottomMargin: 9
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    text: root.pluginName
                    typography: Typography.BodyStrong
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: root.authorName
                        typography: Typography.Caption
                        color: Colors.proxy.textSecondaryColor
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    RowLayout {
                        visible: root.showRating && root.ratingCount > 0
                        spacing: 2

                        Text {
                            text: root.ratingAverage.toFixed(1)
                            typography: Typography.Caption
                            color: Colors.proxy.textSecondaryColor
                        }

                        Icon {
                            icon: "ic_fluent_star_20_filled"
                            size: 12
                            color: Colors.proxy.textSecondaryColor
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.color: Colors.proxy.controlBorderColor
            border.width: 1
        }
    }
}
