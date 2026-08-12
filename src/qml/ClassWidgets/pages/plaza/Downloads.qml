import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    readonly property bool taskActive: PluginManager.plazaInstallActive
    readonly property bool hasUpdatesOrDownloads: taskActive || updateItems().length > 0

    Component.onCompleted: PluginManager.checkPlazaUpdates()

    function storeUrl(pluginId) {
        return PlazaBridge.baseUrl + "/plugins/" + encodeURIComponent(pluginId)
    }

    function openPlugin(pluginId) {
        if (pluginId)
            navigationView.push(Qt.resolvedUrl("Plugin.qml"), { pluginId: pluginId })
    }

    function copyStoreUrl(pluginId) {
        if (UtilsBackend.copyToClipboard(storeUrl(pluginId))) {
            floatLayer.createInfoBar({
                severity: Severity.Success,
                text: qsTr("Link copied"),
            })
        }
    }

    function formatBytes(bytes) {
        var value = Number(bytes) || 0
        if (value < 1024)
            return qsTr("%1 B").arg(value)
        if (value < 1024 * 1024)
            return qsTr("%1 KB").arg((value / 1024).toFixed(1))
        return qsTr("%1 MB").arg((value / 1024 / 1024).toFixed(1))
    }

    function formatSpeed(bytesPerSecond) {
        return qsTr("%1/s").arg(formatBytes(bytesPerSecond))
    }

    function updateItems() {
        var result = []
        var items = PluginManager.plazaPlugins || []
        for (var i = 0; i < items.length; ++i) {
            if (items[i].update_available)
                result.push(items[i])
        }
        result.sort(function(left, right) {
            return left.name.localeCompare(right.name)
        })
        return result
    }

    function installedPlazaItems() {
        var items = (PluginManager.plazaPlugins || []).slice()
        items.sort(function(left, right) {
            return left.name.localeCompare(right.name)
        })
        return items
    }

    function currentPlugin() {
        var pluginId = PluginManager.installPluginId
        var plugins = PluginManager.plugins || []
        for (var i = 0; i < plugins.length; ++i) {
            if (plugins[i].id === pluginId)
                return plugins[i]
        }
        var entries = PluginManager.plazaActivity || []
        for (var j = 0; j < entries.length; ++j) {
            if (entries[j].id === pluginId)
                return entries[j]
        }
        return { id: pluginId, name: pluginId, author: "", version: "", icon: "" }
    }

    function plazaIconUrl(pluginId, icon) {
        var value = String(icon || "")
        if (/^(?:https?:|file:|qrc:|data:)/i.test(value))
            return value
        return pluginId
               ? PlazaBridge.baseUrl + "/api/plugins/"
                 + encodeURIComponent(pluginId) + "/resources/icon"
               : ""
    }

    function activeStatusText() {
        switch (PluginManager.installStatus) {
        case "Paused":
            return qsTr("Paused")
        case "Installing":
            return qsTr("Installing")
        case "Downloading":
            if (PluginManager.installTotalBytes > 0) {
                var details = qsTr("Downloaded: %1 / %2")
                        .arg(formatBytes(PluginManager.installDownloadedBytes))
                        .arg(formatBytes(PluginManager.installTotalBytes))
                return PluginManager.installSpeed > 0
                       ? details + "  " + formatSpeed(PluginManager.installSpeed)
                       : details
            }
            return qsTr("Downloading")
        default:
            return PluginManager.installStatus
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 18

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.hasUpdatesOrDownloads
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Updates and downloads")
                    typography: Typography.Subtitle
                    font.pixelSize: 26
                }

                Button {
                    // flat: true
                    visible: !PluginManager.plazaUpdatesChecking
                    enabled: !PluginManager.plazaUpdatesChecking
                    icon.name: "ic_fluent_arrow_sync_20_regular"
                    text: qsTr("Check for updates")
                    highlighted: true
                    onClicked: PluginManager.checkPlazaUpdates()

                    // ToolTip {
                    //     visible: parent.hovered
                    //     text: qsTr("Check for updates")
                    // }
                }

                ProgressRing {
                    visible: PluginManager.plazaUpdatesChecking
                    Layout.alignment: Qt.AlignVCenter
                    strokeWidth: 2
                    size: 20
                    indeterminate: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                PlazaStatusCard {
                    visible: root.taskActive
                    pluginName: root.currentPlugin().name || PluginManager.installPluginId
                    pluginAuthor: root.currentPlugin().author || ""
                    pluginIcon: root.plazaIconUrl(
                                    PluginManager.installPluginId,
                                    root.currentPlugin().icon
                                )
                    middleText: root.activeStatusText()
                    showProgress: true
                    progressValue: PluginManager.installProgress / 100
                    progressIndeterminate: PluginManager.installStatus === "Installing"
                    primaryActionVisible: PluginManager.installStatus !== "Installing"
                    primaryActionEnabled: PluginManager.installStatus === "Downloading"
                                          || PluginManager.installStatus === "Paused"
                    primaryActionText: PluginManager.installStatus === "Paused"
                                       ? qsTr("Resume") : qsTr("Pause")
                    primaryActionIcon: PluginManager.installStatus === "Paused"
                                       ? "ic_fluent_play_20_regular"
                                       : "ic_fluent_pause_20_regular"
                    cancelVisible: PluginManager.installStatus === "Downloading"
                                   || PluginManager.installStatus === "Paused"

                    onPrimaryActionRequested: {
                        if (PluginManager.installStatus === "Paused")
                            PluginManager.resumePluginInstall()
                        else
                            PluginManager.pausePluginInstall()
                    }
                    onOpenStoreRequested: root.openPlugin(PluginManager.installPluginId)
                    onCopyLinkRequested: root.copyStoreUrl(PluginManager.installPluginId)
                    onCancelRequested: PluginManager.cancelPluginInstall()
                }

                Repeater {
                    model: root.updateItems()

                    delegate: PlazaStatusCard {
                        visible: !root.taskActive || modelData.id !== PluginManager.installPluginId
                        pluginName: modelData.name || modelData.id
                        pluginAuthor: modelData.author || qsTr("Unknown author")
                        pluginIcon: modelData.icon || ""
                        middleText: qsTr("v%1 -> v%2").arg(modelData.version).arg(modelData.latest_version)
                        primaryActionVisible: true
                        primaryActionEnabled: !PluginManager.plazaInstallActive
                        primaryActionText: qsTr("Update")
                        primaryActionIcon: "ic_fluent_arrow_sync_20_regular"

                        onPrimaryActionRequested: PluginManager.installPlazaUpdate(modelData.id)
                        onOpenStoreRequested: root.openPlugin(modelData.id)
                        onCopyLinkRequested: root.copyStoreUrl(modelData.id)
                    }
                }
            }
        }

        PlazaLoading {
            Layout.fillWidth: true
            visible: PluginManager.plazaUpdatesChecking && !root.taskActive
        }

        // Rectangle {
        //     Layout.fillWidth: true
        //     visible: !PluginManager.plazaUpdatesChecking
        //     Layout.topMargin: root.hasUpdatesOrDownloads ? 0 : 6
        //     Layout.bottomMargin: 2
        //     implicitHeight: 1
        //     color: Colors.proxy.controlBorderColor
        // }

        Text {
            Layout.fillWidth: true
            visible: !PluginManager.plazaUpdatesChecking
            text: qsTr("Installed Plugin Plaza plugins")
            typography: Typography.Subtitle
            font.pixelSize: 26
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !PluginManager.plazaUpdatesChecking
            spacing: 4

            Repeater {
                model: root.installedPlazaItems()

                delegate: PlazaStatusCard {
                    pluginName: modelData.name || modelData.id
                    pluginAuthor: modelData.author || qsTr("Unknown author")
                    pluginIcon: modelData.icon || ""
                    middleText: modelData.update_error
                                ? qsTr("Update check unavailable")
                                : modelData.update_available
                                  ? qsTr("v%1 -> v%2").arg(modelData.version).arg(modelData.latest_version)
                                  : qsTr("Updated at %1").arg(modelData.local_updated_at || qsTr("Unknown"))
                    middleTextColor: modelData.update_error
                                     ? Colors.proxy.systemCriticalColor
                                     : Colors.proxy.textColor
                    primaryActionVisible: modelData.update_available
                    primaryActionEnabled: !PluginManager.plazaInstallActive
                    primaryActionText: qsTr("Update")
                    primaryActionIcon: "ic_fluent_arrow_sync_20_regular"

                    onPrimaryActionRequested: PluginManager.installPlazaUpdate(modelData.id)
                    onOpenStoreRequested: root.openPlugin(modelData.id)
                    onCopyLinkRequested: root.copyStoreUrl(modelData.id)
                }
            }

            EmptyState {
                Layout.fillWidth: true
                visible: root.installedPlazaItems().length === 0
                iconName: "ic_fluent_apps_24_regular"
                title: qsTr("No installed Plugin Plaza plugins")
            }
        }
    }
}
