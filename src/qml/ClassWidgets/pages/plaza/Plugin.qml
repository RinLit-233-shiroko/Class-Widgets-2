import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    property string pluginId: ""

    topPadding: 72
    horizontalPadding: 0
    wrapperWidth: wideScreen ? width - 169 * 2 : width - 89 * 2

    readonly property string baseUrl: PlazaBridge.baseUrl
    property var manifest: null
    property string readme: ""
    property string readmeHtml: ""
    property var tagsMap: ({})
    property var otherPlugins: []
    property var ratings: []
    property bool manifestLoading: false
    property bool readmeLoading: false
    property bool tagsLoading: false
    property bool otherPluginsLoading: false
    property bool ratingsLoading: false
    property bool initialLoad: manifest === null && errorMessage.length === 0
    property string errorMessage: ""
    property string iconSource: pluginId ? resourceUrl(pluginId, "icon") : ""
    // 响应式窄窗口时侧栏折叠
    property bool wideLayout: width >= 1000
    property bool wideScreen: width >= 1350
    readonly property bool pluginInstalled: {
        var plugins = PluginManager.plugins || []
        for (var i = 0; i < plugins.length; ++i) {
            if (plugins[i].id === pluginId)
                return true
        }
        return false
    }

    // 评论对话框
    property bool commentsDialogOpen: false

    readonly property int ratingTotal: ratings instanceof Array ? ratings.length : 0
    readonly property real ratingAverage: {
        if (ratingTotal === 0)
            return 0
        var sum = 0
        for (var i = 0; i < ratings.length; i++)
            sum += Number(ratings[i].rating) || 0
        return sum / ratingTotal
    }
    readonly property color starColor: Theme.isDark() ? "#FFD780" : "#d39300"

    // 有文字评论的数量
    readonly property int totalWithComment: {
        var count = 0
        for (var i = 0; i < ratingTotal; i++) {
            if (ratings[i].comment)
                count++
        }
        return count
    }

    Component.onCompleted: {
        if (pluginId && !manifestLoading)
            loadPlugin()
    }
    onPluginIdChanged: {
        if (pluginId)
            loadPlugin()
    }

    function loadPlugin() {
        if (!pluginId)
            return

        manifest = null
        readme = ""
        readmeHtml = ""
        otherPlugins = []
        ratings = []
        errorMessage = ""
        iconSource = resourceUrl(pluginId, "icon")
        fetchManifest()
        fetchTags()
    }

    function apiUrl(path) {
        return baseUrl + path
    }

    function pluginApiUrl(pluginId, suffix) {
        return apiUrl("/api/plugins/" + encodeURIComponent(pluginId) + suffix)
    }

    function resourceUrl(pluginId, resource) {
        return pluginId ? pluginApiUrl(pluginId, "/resources/" + resource) : ""
    }

    function repoUrl() {
        return manifest ? (manifest.repo_url || manifest.url || "") : ""
    }

    function releasePageUrl() {
        return pluginId ? resourceUrl(pluginId, "release?format=cwplugin") : ""
    }

    function releaseZipUrl() {
        return pluginId ? resourceUrl(pluginId, "release?format=zip") : ""
    }

    function storePageUrl() {
        return pluginId ? baseUrl + "/plugins/" + encodeURIComponent(pluginId) : ""
    }

    function formatBytes(bytes) {
        var value = Number(bytes) || 0
        if (value < 1024)
            return qsTr("%1 B").arg(value)
        if (value < 1024 * 1024)
            return qsTr("%1 KB").arg((value / 1024).toFixed(1))
        return qsTr("%1 MB").arg((value / 1024 / 1024).toFixed(1))
    }

    function githubReleasesUrl() {
        var url = repoUrl()
        if (!url)
            return ""
        var match = url.match(/^https?:\/\/github\.com\/([^\/]+\/[^\/#?]+)/i)
        return match ? "https://github.com/" + match[1].replace(/\.git$/, "") + "/releases" : ""
    }

    function tagId(tag) {
        if (!tag)
            return ""
        if (typeof tag === "string")
            return tag
        return tag.id || tag.name || ""
    }

    function tagDisplayName(tag) {
        if (!tag)
            return ""
        if (typeof tag === "string")
            return tagName(tag)
        return tag.name || tagName(tag.id) || tag.id || ""
    }

    function tagKeyMap(tags) {
        var map = ({})
        if (!(tags instanceof Array))
            return map
        for (var i = 0; i < tags.length; i++) {
            var id = tagId(tags[i])
            var name = tagDisplayName(tags[i])
            if (id)
                map[id] = true
            if (name)
                map[name] = true
        }
        return map
    }

    function categoryText() {
        var tags = manifest && manifest.tags instanceof Array ? manifest.tags : []
        var names = []
        for (var i = 0; i < tags.length; i++) {
            var name = tagDisplayName(tags[i])
            if (name)
                names.push(name)
        }
        return names.join(", ")
    }

    function formatDate(value) {
        if (!value)
            return qsTr("No data")
        var date = new Date(value)
        if (isNaN(date.getTime()))
            return String(value)
        return date.toLocaleDateString(Qt.locale(), "yyyy/M/d")
    }

    function requestText(url, success, failure) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status >= 200 && xhr.status < 300) {
                    success(xhr.responseText)
                } else if (failure) {
                    failure(xhr.status + " " + xhr.statusText)
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function fetchManifest() {
        manifestLoading = true
        requestText(pluginApiUrl(pluginId, ""), function(text) {
            try {
                var response = JSON.parse(text)
                manifest = response && response.ok && response.data ? response.data : response
                manifestLoading = false
                fetchReadme()
                fetchOtherPlugins()
                fetchRatings()
            } catch (e) {
                manifestLoading = false
                errorMessage = qsTr("Failed to parse plugin information.")
            }
        }, function(error) {
            manifestLoading = false
            errorMessage = qsTr("Failed to load plugin information: ") + error
        })
    }

    function fetchReadme() {
        readmeLoading = true
        requestText(resourceUrl(pluginId, "readme"), function(text) {
            readme = preprocessReadme(text)
            readmeHtml = MarkdownRenderBridge.render(readme)
            readmeLoading = false
        }, function() {
            readme = "# " + qsTr("No description") + "\n" + qsTr("This plugin does not provide README content.")
            readmeHtml = MarkdownRenderBridge.render(readme)
            readmeLoading = false
        })
    }

    function fetchTags() {
        tagsLoading = true
        requestText(baseUrl + "/api/plugins/tags", function(text) {
            try {
                var response = JSON.parse(text)
                var map = ({})
                var tags = response && response.ok && response.data instanceof Array ? response.data : []
                for (var i = 0; i < tags.length; i++) {
                    if (tags[i] && tags[i].id)
                        map[tags[i].id] = tags[i].name || tags[i].id
                }
                tagsMap = map
            } catch (e) {
                tagsMap = ({})
            }
            tagsLoading = false
        }, function() {
            tagsMap = ({})
            tagsLoading = false
        })
    }

    function fetchOtherPlugins() {
        otherPluginsLoading = true
        requestText(baseUrl + "/api/plugins?per_page=50", function(text) {
            try {
                var response = JSON.parse(text)
                var list = response && response.data instanceof Array ? response.data : []
                otherPlugins = pickRelatedPlugins(list)
            } catch (e) {
                otherPlugins = []
            }
            otherPluginsLoading = false
        }, function() {
            otherPlugins = []
            otherPluginsLoading = false
        })
    }

    function fetchRatings() {
        ratingsLoading = true
        requestText(pluginApiUrl(pluginId, "/comments"), function(text) {
            try {
                var response = JSON.parse(text)
                ratings = response && response.ok && response.data instanceof Array ? response.data : []
            } catch (e) {
                ratings = []
            }
            ratingsLoading = false
        }, function() {
            ratings = []
            ratingsLoading = false
        })
    }

    function pickRelatedPlugins(list) {
        var result = []
        var tags = manifest && manifest.tags instanceof Array ? manifest.tags : []
        var currentTags = tagKeyMap(tags)

        for (var i = 0; i < list.length; i++) {
            var plugin = list[i]
            if (!plugin || plugin.id === pluginId)
                continue

            var pluginTags = plugin.tags instanceof Array ? plugin.tags : []
            var matched = tags.length === 0
            for (var j = 0; j < pluginTags.length && !matched; j++) {
                var id = tagId(pluginTags[j])
                var name = tagDisplayName(pluginTags[j])
                matched = (id && currentTags[id]) || (name && currentTags[name])
            }

            if (matched)
                result.push(plugin)

            if (result.length >= 6)
                break
        }
        return result
    }

    function preprocessReadme(text) {
        var result = text || ""
        result = result.replace(/\$\{__web_page_repo__\}/g, repoUrl())
        result = result.replace(/\$\{__web_page_stars_badge__\}/g, "")
        result = result.replace(/\$\{__web_page_downloads_badge__\}/g, "")
        result = result.replace(/\$\{__web_page_license_badge__\}/g, "")
        result = result.replace(/\$\{__web_page_link:(https?:\/\/[^}]+)__\}/g, "$1")
        result = result.replace(/\$\{__web_page_badge:(https?:\/\/[^}]+)__\}/g, "")
        return result
    }

    function tagName(id) {
        if (!id)
            return ""
        var tag = tagsMap ? tagsMap[id] : null
        return tag || id
    }

    function openPlugin(plugin) {
        if (!plugin || !plugin.id)
            return
        navigationView.safePush(Qt.resolvedUrl("Plugin.qml"), true, false, { pluginId: plugin.id })
    }

    function openUrl(url) {
        if (url)
            Qt.openUrlExternally(url)
    }

    // 应用内跳转插件分类页（与 TagShowcase 的“查看全部”行为一致）
    function openTag(tag) {
        var id = tagId(tag)
        if (!id)
            return
        navigationView.push(Qt.resolvedUrl("Plugins.qml"), { initialTag: id })
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 24

        PlazaLoading {
            Layout.fillWidth: true
            visible: root.initialLoad
        }

        ErrorState {
            Layout.fillWidth: true
            visible: !root.initialLoad && root.errorMessage.length > 0
            title: qsTr("Load failed")
            description: root.errorMessage
            onRetryRequested: root.loadPlugin()
        }

        GridLayout {
            Layout.fillWidth: true
            visible: !root.initialLoad && root.errorMessage.length === 0
            columns: root.wideLayout ? 2 : 1
            columnSpacing: 40
            rowSpacing: 24

            // 主内容区：头部信息、说明、其他信息
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 20

                // 头部信息区：上半部分为图标和附加信息，下方为描述
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.wideLayout ? 20 : 14

                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 84
                            Layout.alignment: Qt.AlignTop
                            radius: root.wideLayout ? 24 : 18
                            color: Colors.proxy.backgroundColor
                            border.color: Colors.proxy.controlBorderColor
                            border.width: 1
                            clip: true

                            Skeleton {
                                anchors.fill: parent
                                radius: parent.radius
                                running: manifestLoading
                                visible: manifestLoading
                            }

                            Image {
                                id: pluginIcon
                                anchors.fill: parent
                                anchors.margins: 2
                                source: root.iconSource
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                visible: !manifestLoading

                                onStatusChanged: {
                                    if (status === Image.Error)
                                        root.iconSource = root.resourceUrl("default", "icon")
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                text: manifest && manifest.name ? manifest.name : qsTr("Loading plugin...")
                                typography: root.wideLayout ? Typography.Title : Typography.Subtitle
                                wrapMode: Text.Wrap
                            } // title

                            Text {
                                Layout.fillWidth: true
                                text: manifest && manifest.author ? manifest.author : qsTr("Unknown author")
                                typography: Typography.BodyStrong
                                color: Colors.proxy.primaryColor
                            }  // 作者

                            // 评级 + 标签行
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                visible: manifest !== null
                                Layout.leftMargin: root.ratingTotal ? 0 : -12

                                RowLayout {
                                    spacing: 6
                                    visible: root.ratingTotal > 0

                                    Text {
                                        text: root.ratingAverage.toFixed(1)
                                        typography: Typography.Body
                                        color: root.starColor
                                    }

                                    Icon {
                                        name: "ic_fluent_star_20_filled"
                                        size: 12
                                        color: root.starColor
                                    }

                                    ToolSeparator {
                                        // Layout.fillHeight:true
                                    }

                                    Text {
                                        text: qsTr("%1 Ratings").arg(root.ratingTotal)
                                        typography: Typography.Body
                                        color: Colors.proxy.textSecondaryColor
                                    }

                                    ToolSeparator {
                                        // Layout.fillHeight:true
                                        visible: manifest && manifest.tags && manifest.tags.length > 0
                                    }
                                }

                                Repeater {
                                    model: manifest && manifest.tags ? manifest.tags : []

                                    delegate: Hyperlink {
                                        text: root.tagDisplayName(modelData)
                                        onClicked: root.openTag(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // 描述（两行，宽度最大 600，超出省略）
                    Text {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 600
                        visible: text.length > 0
                        text: manifest && manifest.description ? manifest.description : ""
                        typography: Typography.Caption
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    // 操作按钮
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Button {
                            id: downloadButton
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 38
                            highlighted: true
                            readonly property bool isCurrentTransfer: PluginManager.installPluginId === root.pluginId
                            readonly property string transferStatus: isCurrentTransfer
                                                                  ? PluginManager.installStatus : "Idle"
                            icon.name: transferStatus === "Downloading"
                                       ? "ic_fluent_pause_20_regular"
                                       : transferStatus === "Paused"
                                         ? "ic_fluent_play_20_regular"
                                         : root.pluginInstalled
                                           ? "ic_fluent_checkmark_20_regular"
                                         : "ic_fluent_arrow_download_20_regular"
                            text: transferStatus === "Downloading"
                                  ? qsTr("Pause")
                                  : transferStatus === "Paused"
                                    ? qsTr("Resume")
                                    : transferStatus === "Installing"
                                      ? qsTr("Installing")
                                      : root.pluginInstalled
                                        ? qsTr("Installed")
                                      : qsTr("Get")
                            enabled: !!root.pluginId
                                     && (transferStatus === "Downloading"
                                         || transferStatus === "Paused"
                                         || (!root.pluginInstalled
                                             && !PluginManager.plazaInstallActive))
                            onClicked: {
                                if (transferStatus === "Downloading")
                                    PluginManager.pausePluginInstall()
                                else if (transferStatus === "Paused")
                                    PluginManager.resumePluginInstall()
                                else
                                    PluginManager.installFromPlaza(root.pluginId)
                            }
                        }

                        ProgressBar {
                            visible: downloadButton.isCurrentTransfer
                                     && (downloadButton.transferStatus === "Downloading"
                                         || downloadButton.transferStatus === "Paused"
                                         || downloadButton.transferStatus === "Installing")
                            Layout.preferredWidth: 125
                            value: PluginManager.installProgress / 100
                            indeterminate: downloadButton.transferStatus === "Installing"

                            ToolTip {
                                visible: parent.hovered
                                text: downloadButton.transferStatus === "Paused"
                                      ? qsTr("Paused")
                                      : PluginManager.installTotalBytes > 0
                                        ? qsTr("Downloaded: %1 / %2")
                                          .arg(root.formatBytes(PluginManager.installDownloadedBytes))
                                          .arg(root.formatBytes(PluginManager.installTotalBytes))
                                        : qsTr("Downloading")
                            }
                        }

                        ToolButton {
                            flat: true
                            icon.name: "ic_fluent_more_horizontal_20_regular"
                            onClicked: downloadMenu.open()

                            Menu {
                                id: downloadMenu

                                // 每次菜单弹出前强制刷新“取消下载”的可见性，
                                // 避免依赖绑定求值在个别情况下未及时更新。
                                onAboutToShow: cancelDownloadItem.refreshVisibility()

                                MenuItem {
                                    icon.name: "ic_fluent_open_20_regular"
                                    text: qsTr("Open in Web")
                                    enabled: !!root.storePageUrl()
                                    onTriggered: root.openUrl(root.storePageUrl())
                                }
                                MenuItem {
                                    icon.name: "ic_fluent_copy_20_regular"
                                    text: qsTr("Copy link")
                                    enabled: !!root.storePageUrl()
                                    onTriggered: {
                                        if (UtilsBackend.copyToClipboard(root.storePageUrl())) {
                                            floatLayer.createInfoBar({
                                                severity: Severity.Success,
                                                text: qsTr("Link copied"),
                                            })
                                        }
                                    }
                                }
                                MenuSeparator {
                                    visible: cancelDownloadItem.visible
                                }
                                MenuItem {
                                    id: cancelDownloadItem
                                    icon.name: "ic_fluent_dismiss_20_regular"
                                    text: qsTr("Cancel download")
                                    visible: !!PluginManager
                                             && PluginManager.installPluginId === root.pluginId
                                             && (PluginManager.installStatus === "Downloading"
                                                 || PluginManager.installStatus === "Paused")

                                    function refreshVisibility() {
                                        visible = Qt.binding(function() {
                                            return !!PluginManager
                                                   && PluginManager.installPluginId === root.pluginId
                                                   && (PluginManager.installStatus === "Downloading"
                                                       || PluginManager.installStatus === "Paused")
                                        })
                                    }

                                    onTriggered: PluginManager.cancelPluginInstall()
                                }
                            }

                            ToolTip {
                                visible: parent.hovered
                                text: qsTr("More options")
                            }
                        }
                    }
                }

                // 说明
                Frame {
                    Layout.fillWidth: true
                    padding: 24

                    ColumnLayout {
                        width: parent.width
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Description")
                            typography: Typography.BodyLarge
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Colors.proxy.controlBorderColor
                        }

                        MarkdownViewer {
                            Layout.fillWidth: true
                            html: root.readmeHtml
                            loading: root.readmeLoading
                            onLinkActivated: function(link) {
                                root.openUrl(link)
                            }
                        }
                    }
                }

                // 其他信息
                Frame {
                    Layout.fillWidth: true
                    padding: 24
                    visible: root.manifest !== null

                    ColumnLayout {
                        width: parent.width
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Other information")
                            typography: Typography.BodyLarge
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Colors.proxy.controlBorderColor
                        }

                        PluginMeta {
                            Layout.fillWidth: true
                            minimumColumnWidth: 220
                            items: [
                                { icon: "ic_fluent_tag_20_regular", label: qsTr("Plugin ID"), value: manifest && manifest.id ? manifest.id : pluginId },
                                { icon: "ic_fluent_info_20_regular", label: qsTr("Version"), value: manifest && manifest.version ? manifest.version : qsTr("Unknown") },
                                { icon: "ic_fluent_code_20_regular", label: qsTr("API version"), value: manifest && manifest.api_version ? manifest.api_version : qsTr("Unknown") },
                                { icon: "ic_fluent_branch_20_regular", label: qsTr("Branch"), value: manifest && manifest.branch ? manifest.branch : "main" },
                                { icon: "ic_fluent_clock_20_regular", label: qsTr("Last updated"), value: root.formatDate(manifest ? (manifest.updated_at || manifest.updated) : "") },
                                { icon: "ic_fluent_link_20_regular", label: qsTr("Repository"), value: root.repoUrl() || qsTr("No data"), valueUrl: root.repoUrl() }
                            ]
                        }
                    }
                }
            }

            // 右侧栏：评分和评价、发现更多（窄窗口时折叠为主内容下方的全宽区块）
            ColumnLayout {
                Layout.fillWidth: !root.wideLayout
                Layout.preferredWidth: root.wideLayout ? 300 : -1
                Layout.alignment: Qt.AlignTop
                spacing: 20

                Frame {
                    Layout.fillWidth: true
                    padding: 24

                    ColumnLayout {
                        width: parent.width
                        spacing: 16

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Ratings and reviews")
                            typography: Typography.BodyLarge
                        }

                        PluginRating {
                            Layout.fillWidth: true
                            ratings: root.ratings
                            loading: root.ratingsLoading
                        }

                        Button {
                            flat: true
                            visible: root.ratingTotal > 0
                            text: qsTr("See all (%1)").arg(root.totalWithComment)
                            onClicked: root.commentsDialogOpen = true
                            highlighted: true
                        }
                    }
                }

                Frame {
                    Layout.fillWidth: true
                    padding: 24

                    ColumnLayout {
                        width: parent.width
                        spacing: 12

                        // 区块标题（原 SectionHeader 组件内联，此处为唯一使用方）
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Discover more")
                                typography: Typography.BodyLarge
                                wrapMode: Text.Wrap
                            }

                            Button {
                                flat: true
                                visible: manifest && manifest.tags && manifest.tags.length > 0
                                icon.name: "ic_fluent_chevron_right_20_regular"
                                onClicked: root.openTag(manifest.tags[0])
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Colors.proxy.controlBorderColor
                        }

                        PluginList {
                            Layout.fillWidth: true
                            visible: !otherPluginsLoading && otherPlugins.length > 0
                            plugins: root.otherPlugins
                            itemHeight: 96
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 160
                            visible: otherPluginsLoading

                            ProgressRing {
                                anchors.centerIn: parent
                                size: 38
                                indeterminate: true
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !otherPluginsLoading && otherPlugins.length === 0
                            text: qsTr("No recommendations")
                            horizontalAlignment: Text.AlignHCenter
                            color: Colors.proxy.textSecondaryColor
                        }
                    }
                }
            }
        }
    }

    // 查看全部评论对话框
    PluginCommentsDialog {
        id: commentsDialog
        parent: Overlay.overlay
        ratings: root.ratings
        loading: root.ratingsLoading
        visible: root.commentsDialogOpen
        onVisibleChanged: root.commentsDialogOpen = visible
    }
}
