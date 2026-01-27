import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes
import RinUI
import ClassWidgets.Components

Item {
    id: root
    width: 600
    height: 240

    property var plugins: []
    property var banners: []
    property bool loading: false

    property bool autoplayEnabled: true
    property int autoplayInterval: 4000
    property int currentIndex: 0

    property var slides: []

    onPluginsChanged: rebuildSlides()
    onBannersChanged: rebuildSlides()
    Component.onCompleted: rebuildSlides()

    function seededRngFromDate() {
        var d = new Date()
        var seed = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate()
        var s = seed >>> 0 || 1
        return function() {
            s = (1664525 * s + 1013904223) >>> 0
            return s / 0xffffffff
        }
    }

    function seededPick(arr, count) {
        if (!arr || arr.length === 0) return []
        var rng = seededRngFromDate()
        var copy = arr.slice()
        for (var i = copy.length - 1; i > 0; i--) {
            var j = Math.floor(rng() * (i + 1))
            var t = copy[i]
            copy[i] = copy[j]
            copy[j] = t
        }
        return copy.slice(0, Math.min(count, copy.length))
    }

    function rebuildSlides() {
        var result = []

        if (plugins && plugins.length > 0) {
            var picked = seededPick(plugins, 6).map(function(p) {
                return {
                    id: p.id,
                    name: p.name,
                    icon: "https://plaza.cw.rinlit.cn/api/plugins/" + p.id + "/resources/icon"
                }
            })

            result.push({
                kind: "icons",
                title: "欢迎光临 Class Widgets 插件广场",
                subtitle: "使用插件和主题让课程表如虎添翼",
                plugins: picked
            })
        }

        var imgs = (banners && banners.length > 0)
            ? banners.slice(0, 2)
            : [{
                image: "https://plaza.cw.rinlit.cn/BannerWelcome.png",
                desc: "精选扩展与主题，提升你的使用体验。"
            }]

        for (var i = 0; i < imgs.length; i++) {
            var b = imgs[i]
            result.push({
                kind: "image",
                banner: b
            })
        }

        slides = result
        currentIndex = 0
    }

    Timer {
        interval: autoplayInterval
        repeat: true
        running: autoplayEnabled && slides.length > 1
        onTriggered: view.currentIndex =
            (view.currentIndex + 1) % slides.length
    }

    Rectangle {
        anchors.fill: parent
        // radius: 16
        color: Colors.proxy.backgroundColor
        border.color: Colors.proxy.controlBorderColor
        clip: true

        SwipeView {
            id: view
            anchors.fill: parent
            currentIndex: root.currentIndex
            interactive: slides.length > 1

            onCurrentIndexChanged: {
                if (root.currentIndex !== currentIndex)
                    root.currentIndex = currentIndex
            }

            Repeater {
                model: slides

                delegate: Item {
                    width: SwipeView.view.width
                    height: SwipeView.view.height

                    property var slideData: modelData

                    Item {
                        anchors.fill: parent
                        visible: slideData.kind === "icons"

                        // 亮色模式背景（linear to bottom-right）
                        Rectangle {
                            anchors.fill: parent
                            visible: !Theme.isDark()
                            gradient: LinearGradient {
                                x1: 0
                                y1: 0
                                x2: parent.width
                                y2: parent.height
                                GradientStop { position: 0.0; color: "#68C6E9" }
                                GradientStop { position: 1.0; color: "#62F9BD" }
                            }
                        }

                        // 暗色模式背景（radial at bottom-center）
                        Rectangle {
                            anchors.fill: parent
                            visible: Theme.isDark()
                            gradient: RadialGradient {
                                centerX: parent.width * 0.5
                                centerY: parent.height * 1.0
                                focalRadius: Math.max(parent.width, parent.height) * 0.9

                                GradientStop { position: 1.0; color: "#1CCFD5" }
                                GradientStop { position: 0.0; color: "#143E73" }
                            }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 32
                            spacing: 8

                            ColumnLayout {
                                spacing: 8
                                Text {
                                    text: slideData.title || ""
                                    typography: Typography.Subtitle
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    text: slideData.subtitle || ""
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            Flow {
                                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                                spacing: 12

                                Repeater {
                                    model: slideData.plugins ? slideData.plugins : [1, 2, 3, 4, 5, 6]

                                    delegate: Item {
                                        id: pluginIcon
                                        width: 54
                                        height: 54

                                        property var pluginData: slideData.plugins ? slideData.plugins[index] : null
                                        property bool iconLoaded: false

                                        // 插件图标容器
                                        Skeleton {
                                            anchors.fill: parent
                                            radius: 12
                                            running: !pluginData || !pluginData.icon || !iconLoaded
                                            visible: !pluginData || !pluginData.icon || !iconLoaded
                                        }

                                        // 插件图标
                                        Image {
                                            anchors.fill: parent
                                            source: pluginData && pluginData.icon ? pluginData.icon : ""
                                            fillMode: Image.PreserveAspectFit
                                            visible: pluginData && pluginData.icon

                                            onStatusChanged: {
                                                if (status === Image.Ready) {
                                                    iconLoaded = true
                                                } else if (status === Image.Error) {
                                                    iconLoaded = true
                                                }
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

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: pluginData && pluginData.id
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: Qt.openUrlExternally(
                                                "https://plaza.cw.rinlit.cn/plugins/" + pluginData.id
                                            )
                                        }

                                        ToolTip {
                                            visible: hoverHandler.hovered
                                            text: pluginData && pluginData.name ? pluginData.name : ""
                                        }

                                        HoverHandler {
                                            id: hoverHandler
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: slideData.kind === "image"

                        Image {
                            anchors.fill: parent
                            source: slideData.banner && slideData.banner.image ? slideData.banner.image : ""
                            fillMode: Image.PreserveAspectCrop
                        }

                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.6; color: "transparent" }
                                GradientStop { position: 1.0; color: "#CC000000" }
                            }
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 24
                            width: parent.width - 100
                            text: slideData.banner && slideData.banner.desc ? slideData.banner.desc : ""
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        PageIndicator {
            id: pageIndiactor
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 8
            currentIndex: root.currentIndex
            visible: count > 1 && !loading
            interactive: true
            count: view.count
        }
    }
}
