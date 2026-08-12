import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Shapes
import RinUI
import ClassWidgets.Components

ColumnLayout {
    id: root
    width: 600
    height: 240

    property alias currentIndex: swipeView.currentIndex
    property alias count: swipeView.count

    property var plugins: []
    property var banners: []
    property bool loading: false

    property bool autoplayEnabled: true
    property int autoplayInterval: 4000

    property var slides: []

    Timer {
        id: autoplayTimer
        interval: root.autoplayInterval
        repeat: true
        running: root.autoplayEnabled && root.slides.length > 1
        onTriggered: root.currentIndex = (root.currentIndex + 1) % root.slides.length
    }

    function resourceUrl(pluginId, resource) {
        return pluginId ? PlazaBridge.baseUrl + "/api/plugins/" + encodeURIComponent(pluginId) + "/resources/" + resource : ""
    }

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
                    icon: resourceUrl(p.id, "icon")
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
                image: PlazaBridge.baseUrl + "/BannerWelcome.png",
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
        root.currentIndex = 0
        pageIndicator.currentIndex = root.currentIndex
    }

    // ── 幻灯片页面 ──
    // 注：SwipeView 的直接子对象都会被视为页面，因此 Repeater/Component 需声明在 delegate 内部
    SwipeView {
        id: swipeView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        interactive: root.slides.length > 1

        onCurrentIndexChanged: {
            if (root.slides.length > 0 && currentIndex >= root.slides.length) {
                currentIndex = root.slides.length - 1
                return
            }

            if (pageIndicator.currentIndex !== currentIndex)
                pageIndicator.currentIndex = currentIndex

            if (root.autoplayEnabled && root.slides.length > 1)
                autoplayTimer.restart()
        }

        Repeater {
            model: slides

            // 每个 delegate 只有一个内容子元素（Loader），避免多 Item 同时参与布局
            delegate: Loader {
                id: slideLoader
                // 直接引用 root 尺寸，避免初次加载时 SwipeView.view 尚未就绪导致排版错乱
                width: swipeView.width
                height: swipeView.height

                // 自动播放定时器：声明在 delegate 内（SwipeView 不允许非 Item 直接子对象），
                // 仅第一页的实例运行，避免多个 Timer 重复触发
                property var slideData: modelData || ({})
                sourceComponent: slideData.kind === "icons" ? iconsSlide : imageSlide

                    // 通过 onLoaded 显式传参，避免加载组件内跨作用域引用出错
                onLoaded: item.slideData = slideData

                // ── 页码指示器（叠加在每个页面底部，随 SwipeView 根控件化无法再外挂）──
                // ── 插件图标欢迎页 ──（声明在 delegate 内：SwipeView 的直接子对象均被视为页面）
                Component {
                    id: iconsSlide

                    Item {
                        property var slideData: ({})

                        // 亮色模式背景（linear to bottom-right）
                        Rectangle {
                            anchors.fill: parent
                            visible: !Theme.isDark()
                            gradient: LinearGradient {
                                x1: 0; y1: 0
                                x2: parent.width; y2: parent.height
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
                                    font.pixelSize: 28
                                    font.bold: true
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Text {
                                    text: slideData.subtitle || ""
                                    Layout.fillWidth: true
                                    font.pixelSize: 16
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

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 12
                                            color: "#B3FFFFFF"
                                            border.color: "#0D000000"
                                            border.width: 1
                                        }

                                        Skeleton {
                                            anchors.fill: parent
                                            radius: 12
                                            running: !pluginData || !pluginData.icon || !iconLoaded
                                            visible: !pluginData || !pluginData.icon || !iconLoaded
                                        }

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
                                            onClicked: navigationView.safePush(
                                                Qt.resolvedUrl("../../pages/plaza/Plugin.qml"),
                                                true,
                                                false,
                                                { pluginId: pluginData.id }
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
                }

                // ── 图片横幅页 ──
                Component {
                    id: imageSlide

                    Item {
                        property var slideData: ({})

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
                            text: slideData.banner ? (slideData.banner.subtitle || slideData.banner.desc || slideData.banner.title || "") : ""
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    PageIndicator {
        id: pageIndicator
        Layout.alignment: Qt.AlignHCenter
        Layout.bottomMargin: 8
        count: root.slides.length
        visible: count > 1 && !root.loading
        interactive: true

        onCurrentIndexChanged: {
            if (root.currentIndex !== currentIndex)
                root.currentIndex = currentIndex
        }
    }
}
