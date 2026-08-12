import QtQuick
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    property var plugins: PlazaBridge.plugins || []
    property var banners: PlazaBridge.banners || []
    property bool initialLoad: plugins.length === 0
        && PlazaBridge.status !== "PluginsLoaded"
        && PlazaBridge.status !== "Error"
    property bool loading: initialLoad
        || PlazaBridge.status === "FetchingPlugins"
        || PlazaBridge.status === "FetchingBanners"

    function tagId(tag) { return typeof tag === "string" ? tag : (tag && (tag.id || tag.name) || "") }
    function tagName(tag) { return typeof tag === "string" ? tag : (tag && (tag.name || tag.id) || "") }

    function pluginsForTag(tag, count) {
        var result = []
        for (var i = 0; i < plugins.length; i++) {
            var pluginTags = plugins[i] && plugins[i].tags instanceof Array ? plugins[i].tags : []
            for (var j = 0; j < pluginTags.length; j++) {
                if (tagId(pluginTags[j]) === tag.id || tagName(pluginTags[j]) === tag.name) {
                    result.push(plugins[i])
                    break
                }
            }
            if (result.length >= count) break
        }
        return result
    }

    function featuredTags() {
        var counts = ({})
        var names = ({})
        for (var i = 0; i < plugins.length; i++) {
            var values = plugins[i] && plugins[i].tags instanceof Array ? plugins[i].tags : []
            for (var j = 0; j < values.length; j++) {
                var id = tagId(values[j])
                if (!id) continue
                counts[id] = (counts[id] || 0) + 1
                names[id] = tagName(values[j])
            }
        }
        var result = []
        for (var key in counts) result.push({ id: key, name: names[key], count: counts[key] })
        result.sort(function(a, b) { return b.count - a.count })
        return result.slice(0, 3)
    }

    contentHeader: Item {
        width: parent.width
        height: root.initialLoad ? 0 : (root.width >= 900 ? 320 : root.width >= 620 ? 256 : 224)
        visible: !root.initialLoad
        BannerCarousel { anchors.fill: parent; plugins: root.plugins; banners: root.banners; loading: root.loading }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 20

        PluginSection {
            Layout.fillWidth: true
            visible: !root.initialLoad
            title: qsTr("Recommended for you")
            plugins: root.plugins.slice(0, 6)
            loading: false
            pageSize: 6
        }

        Repeater {
            model: root.initialLoad ? [] : root.featuredTags()
            delegate: TagShowcase {
                Layout.fillWidth: true
                tagId: modelData.id
                title: modelData.name
                plugins: root.pluginsForTag(modelData, 6)
                total: modelData.count
                loading: false
                showRating: true
            }
        }

        PlazaLoading {
            Layout.fillWidth: true
            visible: root.initialLoad
        }

        ErrorState {
            Layout.fillWidth: true
            visible: !root.initialLoad && root.plugins.length === 0
            title: qsTr("The plaza is unavailable")
            description: qsTr("Check your connection and try loading the plaza again.")
            onRetryRequested: PlazaBridge.refreshAll()
        }
    }
}
