import QtQuick
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    title: qsTr("Search")
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    // 由导航 push 传入的搜索关键词
    property string query: ""
    // 页内搜索框当前输入（提交后才更新 query）
    property string pendingQuery: query

    readonly property string baseUrl: PlazaBridge.baseUrl
    property var plugins: []
    property var tags: []
    property string activeTag: ""
    property string sort: "relevance"
    property int page: 1
    property int perPage: 12
    property int total: 0
    property int totalPages: 1
    property bool loading: false
    property string errorMessage: ""

    readonly property bool hasQuery: query.trim().length > 0

    onQueryChanged: pendingQuery = query

    function request(url, callback, failure) {
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (xhr.status >= 200 && xhr.status < 300) {
                try { callback(JSON.parse(xhr.responseText)) }
                catch (error) { failure(qsTr("Invalid server response.")) }
            } else {
                failure(xhr.status + " " + xhr.statusText)
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function search(nextPage) {
        if (!hasQuery) {
            plugins = []
            total = 0
            totalPages = 1
            return
        }
        page = nextPage || 1
        loading = true
        errorMessage = ""
        var params = "?q=" + encodeURIComponent(query.trim())
            + "&page=" + page + "&per_page=" + perPage
            + "&sort=" + encodeURIComponent(sort)
        if (activeTag) params += "&tag=" + encodeURIComponent(activeTag)
        request(baseUrl + "/api/plugins/search" + params, function(response) {
            if (response.ok === false) {
                plugins = []
                total = 0
                totalPages = 1
                errorMessage = response.error || qsTr("The plaza rejected the request.")
            } else {
                plugins = response.data instanceof Array ? response.data : []
                total = response.meta && response.meta.total !== undefined ? response.meta.total : plugins.length
                totalPages = response.meta && response.meta.total_pages ? response.meta.total_pages : 1
            }
            loading = false
        }, function(error) {
            plugins = []
            total = 0
            totalPages = 1
            errorMessage = qsTr("Unable to search plugins: ") + error
            loading = false
        })
    }

    function loadTags() {
        request(baseUrl + "/api/plugins/tags", function(response) {
            tags = response.data instanceof Array ? response.data : []
        }, function() { tags = [] })
    }

    function submitSearch() {
        var next = pendingQuery.trim()
        activeTag = ""
        query = next
        search(1)
    }

    function selectTag(tagId) {
        activeTag = tagId
        search(1)
    }

    function selectSort(value) {
        sort = value
        search(1)
    }

    Component.onCompleted: { loadTags(); search(1) }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        // 搜索框（页内可再次搜索）
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: qsTr("Search plugins, authors, descriptions or tags")
                text: root.pendingQuery
                enabled: !root.loading
                onTextChanged: root.pendingQuery = text
                onAccepted: root.submitSearch()
            }

            Button {
                highlighted: true
                text: qsTr("Search")
                enabled: !root.loading
                onClicked: root.submitSearch()
            }
        }

        // 头部：标题（左）+ 排序（右），下方标签筛选
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: root.hasQuery

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: "\u201C" + root.query + "\u201D"
                    typography: Typography.Title
                    elide: Text.ElideRight
                }

                DropDownButton {
                    Layout.alignment: Qt.AlignRight
                    enabled: !root.loading
                    text: root.sort === "relevance" ? qsTr("Relevance")
                        : root.sort === "name" ? qsTr("Name")
                        : root.sort === "rating" ? qsTr("Rating")
                        : root.sort === "downloads" ? qsTr("Downloads")
                        : qsTr("Latest")
                    icon.name: "ic_fluent_arrow_sort_20_regular"

                    MenuItem { text: qsTr("Relevance"); onTriggered: root.selectSort("relevance") }
                    MenuItem { text: qsTr("Latest"); onTriggered: root.selectSort("latest") }
                    MenuItem { text: qsTr("Name"); onTriggered: root.selectSort("name") }
                    MenuItem { text: qsTr("Rating"); onTriggered: root.selectSort("rating") }
                    MenuItem { text: qsTr("Downloads"); onTriggered: root.selectSort("downloads") }
                }
            }

            Segmented {
                enabled: !root.loading

                SegmentedItem {
                    text: qsTr("All")
                    checked: root.activeTag === ""
                    onClicked: root.selectTag("")
                }

                Repeater {
                    model: root.tags instanceof Array ? root.tags.slice(0, 5) : []

                    delegate: SegmentedItem {
                        required property var modelData
                        readonly property string tagId: modelData.id || modelData.name || ""
                        text: modelData.name || modelData.id || ""
                        checked: root.activeTag === tagId
                        onClicked: root.selectTag(tagId)
                    }
                }
            }
        }

        PlazaLoading {
            Layout.fillWidth: true
            visible: root.hasQuery && root.loading
        }

        PluginGrid {
            Layout.fillWidth: true
            visible: root.hasQuery && !root.loading && root.errorMessage.length === 0 && root.plugins.length > 0
            plugins: root.plugins
            loading: false
        }

        ErrorState {
            Layout.fillWidth: true
            visible: root.hasQuery && !root.loading && root.errorMessage.length > 0
            title: qsTr("Could not search plugins")
            description: root.errorMessage
            onRetryRequested: root.search(root.page)
        }

        EmptyState {
            Layout.fillWidth: true
            visible: !root.hasQuery
            iconName: "ic_fluent_search_24_regular"
            title: qsTr("Search the plaza")
            description: qsTr("Enter keywords to search plugins.")
        }

        EmptyState {
            Layout.fillWidth: true
            visible: root.hasQuery && !root.loading && root.errorMessage.length === 0 && root.plugins.length === 0
            iconName: "ic_fluent_search_info_24_regular"
            title: qsTr("No plugins found")
            description: qsTr("Try another search or category.")
        }

        Pagination {
            Layout.alignment: Qt.AlignHCenter
            visible: root.hasQuery && !root.loading && root.errorMessage.length === 0 && root.totalPages > 1
            currentPage: root.page
            totalPages: root.totalPages
            onPageRequested: function(value) { root.search(value) }
        }
    }
}
