import QtQuick

Loader {
    id: loader

    property string widgetSource: model.qmlPath
    property bool reloading: false
    property bool loadFailed: false
    property bool loadingErrorPlaceholder: false
    property int reloadSerial: 0
    property string errorWidgetSource: Qt.resolvedUrl("WidgetLoadError.qml")

    source: widgetSource
    asynchronous: true

    function cacheBustedUrl(url) {
        reloadSerial += 1
        var separator = url.indexOf("?") >= 0 ? "&" : "?"
        return url + separator + "t=" + Date.now() + "-" + reloadSerial
    }

    function retry() {
        var oldSource = widgetSource.toString()
        loadFailed = false
        loadingErrorPlaceholder = false
        reloading = true
        sourceComponent = null
        source = ""

        Qt.callLater(function() {
            var cacheBustedSource = cacheBustedUrl(oldSource)
            source = cacheBustedSource
        })
    }

    onStatusChanged: {
        if (status === Loader.Ready) {
            reloading = false

            if (loadingErrorPlaceholder) {
                reloading = false
                if (item && item.hasOwnProperty("widgetName"))
                    item.widgetName = model.name || model.typeId
                if (item && item.hasOwnProperty("editMode"))
                    item.editMode = widgetsContainer.editMode
                return
            }

            if (item && model.backendObj) {
                item.backend = model.backendObj
            }
            if (item && model.settings) {
                item.settings = model.settings
            }
            if (item && item.hasOwnProperty("instanceId")) {
                item.instanceId = model.instanceId
            }
            if (item && item.hasOwnProperty("widget_id")) {
                item.widget_id = model.widget_id
            }
            if (item && item.hasOwnProperty("editMode")) {
                item.editMode = widgetsContainer.editMode
            }
            anim.start()
        } else if (status === Loader.Error) {
            reloading = false

            if (loadingErrorPlaceholder) {
                console.error("Unable to load widget error placeholder:", errorWidgetSource)
                source = ""
                return
            }

            loadFailed = true
            loadingErrorPlaceholder = true
            console.error("Unable to load widget:", model.typeId, widgetSource)

            sourceComponent = null
            source = cacheBustedUrl(errorWidgetSource)
        }
    }

    Connections {
        target: WidgetsModel

        function onModelChanged() {
            if (loader.item && !loader.loadFailed && model.settings) {
                loader.item.settings = model.settings
            }
            if (loader.item && !loader.loadFailed && loader.item.hasOwnProperty("instanceId")) {
                loader.item.instanceId = model.instanceId
            }
            if (loader.item && !loader.loadFailed && loader.item.hasOwnProperty("widget_id")) {
                loader.item.widget_id = model.widget_id
            }
        }
    }

    Connections {
        target: widgetsContainer

        function onEditModeChanged() {
            if (loader.item && loader.item.hasOwnProperty("editMode")) {
                loader.item.editMode = widgetsContainer.editMode
            }
        }
    }

    function reloadErrorPlaceholder() {
        reloading = true
        loadingErrorPlaceholder = true
        sourceComponent = null
        source = ""

        // Use a unique URL so the placeholder re-imports the active theme.
        Qt.callLater(function() {
            source = cacheBustedUrl(errorWidgetSource)
        })
    }

    Connections {
        target: loader.item
        enabled: loader.loadFailed && loader.loadingErrorPlaceholder
        ignoreUnknownSignals: true

        function onRemoveRequested() {
            WidgetsModel.removeInstance(model.instanceId)
        }

        function onRetryRequested() {
            loader.retry()
        }
    }

    Connections {
        target: CWThemeManager

        function onWidgetsReadyToReload() {
            if (reloading)
                return

            if (loadFailed) {
                reloadErrorPlaceholder()
                return
            }

            reloading = true
            var oldSource = widgetSource.toString()
            source = ""

            Qt.callLater(function() {
                var cacheBustedSource = cacheBustedUrl(oldSource)
                source = cacheBustedSource
            })
        }
    }
}
