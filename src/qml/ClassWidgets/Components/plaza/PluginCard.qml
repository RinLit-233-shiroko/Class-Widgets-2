import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import RinUI
import ClassWidgets.Components

Item {
    id: root

    property var plugin: ({})
    property bool isLoading: false
    property bool transparent: false
    property bool navigationEnabled: true
    property bool showRating: false
    property bool showTags: true
    property url detailPage: Qt.resolvedUrl("../../pages/plaza/Plugin.qml")

    readonly property string pluginAuthor: plugin
        ? (plugin.author || plugin.owner_name || plugin.owner_id || qsTr("Unknown author"))
        : qsTr("Unknown author")
    readonly property real ratingAverage: plugin ? Number(plugin.rating_average || 0) : 0
    readonly property int ratingCount: plugin ? Number(plugin.rating_count || 0) : 0
    readonly property bool hasRating: ratingCount > 0
    readonly property string pluginDescription: plugin
        ? (plugin.description || plugin.desc || plugin.summary || "") : ""

    function resourceUrl(pluginId, resource) {
        return pluginId ? PlazaBridge.baseUrl + "/api/plugins/" + encodeURIComponent(pluginId) + "/resources/" + resource : ""
    }

    function tagName(tag) {
        if (typeof tag === "string") return tag
        return tag ? (tag.name || tag.id || "") : ""
    }

    // ── 悬停上浮 + 阴影 ──
    property real liftY: card.hovered && !root.isLoading ? -2 : 0

    z: card.hovered ? 1 : 0
    transform: Translate { y: root.liftY }

    Behavior on liftY { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    // 独立不透明圆角矩形作为阴影源（透明背景卡片无法直接对控件做 layer 阴影）
    Rectangle {
        id: shadowSource
        anchors.fill: parent
        radius: card.radius
        color: Colors.proxy.backgroundColor
        opacity: card.hovered && !root.isLoading ? 1 : 0

        // Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

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
            if (root.navigationEnabled && !root.isLoading && root.plugin && root.plugin.id)
                navigationView.safePush(root.detailPage, true, false, { pluginId: root.plugin.id })
        }

        background: Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: card.down ? Colors.proxy.controlPressedColor
                 : card.hovered ? Qt.alpha("white", 0.15)
                 : root.transparent ? "transparent" : card.backgroundColor
        }

        Loader {
            anchors.fill: parent
            anchors.margins: 12
            sourceComponent: root.isLoading ? skeletonComponent : contentComponent
        }
    }

    // ── 骨架屏 ──
    Component {
        id: skeletonComponent

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 16
                clip: true

                Skeleton {
                    anchors.fill: parent
                    radius: parent.radius
                    running: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 64
                            height: 64
                            radius: 16
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                Skeleton { Layout.fillWidth: true; Layout.preferredHeight: 18; radius: 6; running: true }
                Skeleton { Layout.preferredWidth: parent.width * 0.55; Layout.preferredHeight: 14; radius: 6; running: true }
                Skeleton { Layout.fillWidth: true; Layout.preferredHeight: 14; radius: 6; running: true }
            }
        }
    }

    // ── 内容 ──
    Component {
        id: contentComponent

        RowLayout {
            anchors.fill: parent
            spacing: 12

            // 图标
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                radius: 16
                // 无图标（加载失败或无来源）时显示纯色占位
                color: pluginIcon.iconFailed ? "#ccc" : Colors.proxy.backgroundColor
                border.color: Colors.proxy.controlBorderColor
                border.width: 1
                clip: true

                Skeleton {
                    anchors.fill: parent
                    radius: 16
                    running: !pluginIcon.iconLoaded && !pluginIcon.iconFailed
                    visible: !pluginIcon.iconLoaded && !pluginIcon.iconFailed

                    layer.enabled: visible
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: 64
                            height: 64
                            radius: 16
                        }
                    }
                }

                Image {
                    id: pluginIcon
                    anchors.fill: parent
                    source: root.resourceUrl(root.plugin && root.plugin.id ? root.plugin.id : "", "icon")
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: true
                    visible: pluginIcon.iconLoaded

                    property bool iconLoaded: false
                    readonly property bool iconFailed: status === Image.Error || source === ""

                    onStatusChanged: {
                        if (status === Image.Ready)
                            iconLoaded = true
                    }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        anchors.fill: pluginIcon
                        maskSource: Rectangle { width: pluginIcon.width; height: pluginIcon.height; radius: 16 }
                    }
                }
            }

            // 中间内容区
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                // 插件名
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 20
                    text: root.plugin && root.plugin.name ? root.plugin.name : qsTr("Unknown plugin")
                    typography: Typography.BodyStrong
                    lineHeight: 20
                    lineHeightMode: Text.FixedHeight
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                // 作者
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.preferredHeight: 20
                    text: root.pluginAuthor
                    typography: Typography.Caption
                    lineHeight: 20
                    lineHeightMode: Text.FixedHeight
                    verticalAlignment: Text.AlignVCenter
                    color: Colors.proxy.primaryColor
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                // 评分和分区：固定一行，分区内容超出时省略
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    visible: root.showRating && root.hasRating

                    RowLayout {
                        anchors.fill: parent
                        spacing: 8

                        RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                            Text {
                                text: root.ratingAverage.toFixed(1)
                                typography: Typography.Caption
                                lineHeightMode: Text.FixedHeight
                                color: Colors.proxy.textSecondaryColor
                            }

                            Icon {
                                name: "ic_fluent_star_20_filled"
                                size: 14
                                color: Colors.proxy.textSecondaryColor
                                // color: Theme.isDark() ? "#FFD780" : "#d39300"
                            }
                        }

                        ToolSeparator {
                            Layout.fillHeight: true
                            visible: tagText.text.length > 0
                        }

                        Text {
                            id: tagText
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: {
                                if (!root.showTags || !root.plugin || !(root.plugin.tags instanceof Array))
                                    return ""
                                var names = []
                                for (var i = 0; i < root.plugin.tags.length && names.length < 2; i++) {
                                    var name = root.tagName(root.plugin.tags[i])
                                    if (name) names.push(name)
                                }
                                return names.join("  ")
                            }
                            typography: Typography.Caption
                            lineHeight: 20
                            lineHeightMode: Text.FixedHeight
                            color: Colors.proxy.textSecondaryColor
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }

                // 无评分时保留描述
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.pluginDescription.length > 0 ? 32 : 0
                    visible: !(root.showRating && root.hasRating) && root.pluginDescription.length > 0

                    Text {
                        anchors.fill: parent
                        text: root.pluginDescription
                        typography: Typography.Caption
                        lineHeight: 16
                        lineHeightMode: Text.FixedHeight
                        color: Colors.proxy.textSecondaryColor
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                    }
                }
            }

        }
    }
}
