import QtQuick
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    title: qsTr("Plugins")
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    readonly property string baseUrl: PlazaBridge.baseUrl
    property var plugins: []
    property var tags: []
    property string initialTag: ""
    property string activeTag: initialTag
    property string sort: "latest"
    property int page: 1
    property int perPage: 12
    property int total: 0
    property int totalPages: 1
    property bool loading: false
    property bool initialLoad: true
    property string errorMessage: ""

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

    function loadPlugins(nextPage) {
        page = nextPage || 1
        loading = true
        errorMessage = ""
        var endpoint = activeTag ? "/api/plugins/category" : "/api/plugins"
        var params = "?page=" + page + "&per_page=" + perPage + "&sort=" + encodeURIComponent(sort)
        if (activeTag) params += "&tag=" + encodeURIComponent(activeTag)
        request(baseUrl + endpoint + params, function(response) {
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
            initialLoad = false
        }, function(error) {
            plugins = []
            total = 0
            totalPages = 1
            errorMessage = qsTr("Unable to load plugins: ") + error
            loading = false
            initialLoad = false
        })
    }

    function loadTags() {
        request(baseUrl + "/api/plugins/tags", function(response) {
            tags = response.data instanceof Array ? response.data : []
        }, function() { tags = [] })
    }

    function selectTag(tagId) {
        activeTag = tagId
        loadPlugins(1)
    }

    function selectSort(value) {
        sort = value
        loadPlugins(1)
    }

    Component.onCompleted: { loadPlugins(1); loadTags() }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 16

        FilterToolbar {
            Layout.fillWidth: true
            visible: !root.initialLoad
            tags: root.tags
            selectedTag: root.activeTag
            sortValue: root.sort
            busy: root.loading
            onTagSelected: function(tagId) { root.selectTag(tagId) }
            onSortSelected: function(value) { root.selectSort(value) }
        }

        PlazaLoading {
            Layout.fillWidth: true
            visible: root.initialLoad
        }

        PluginGrid {
            Layout.fillWidth: true
            visible: !root.initialLoad && root.errorMessage.length === 0 && root.plugins.length > 0
            plugins: root.plugins
            loading: false
        }

        ErrorState {
            Layout.fillWidth: true
            visible: !root.initialLoad && root.errorMessage.length > 0
            title: qsTr("Could not load plugins")
            description: root.errorMessage
            onRetryRequested: root.loadPlugins(root.page)
        }

        EmptyState {
            Layout.fillWidth: true
            visible: !root.initialLoad && !root.loading && root.errorMessage.length === 0 && root.plugins.length === 0
            iconName: "ic_fluent_search_info_24_regular"
            title: qsTr("No plugins found")
            description: root.activeTag ? qsTr("Try another category.") : qsTr("The plaza is empty right now.")
        }

        Pagination {
            Layout.alignment: Qt.AlignHCenter
            visible: !root.initialLoad && !root.loading && root.errorMessage.length === 0 && root.totalPages > 1
            currentPage: root.page
            totalPages: root.totalPages
            onPageRequested: function(value) { root.loadPlugins(value) }
        }
    }
}
