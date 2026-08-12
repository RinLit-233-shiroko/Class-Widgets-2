import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentWindow {
    id: root
    icon: PathManager.assets("images/icons/cw2_plugin.png")
    title: qsTr("Plugin Plaza")
    width: Screen.width * 0.67
    height: Screen.height * 0.69
    minimumWidth: 900

    function formatBytes(bytes) {
        var value = Number(bytes) || 0
        if (value < 1024)
            return qsTr("%1 B").arg(value)
        if (value < 1024 * 1024)
            return qsTr("%1 KB").arg((value / 1024).toFixed(1))
        return qsTr("%1 MB").arg((value / 1024 / 1024).toFixed(1))
    }

    onClosing: function(event) {
        event.accepted = false
        WindowManager.closePlaza()
    }

    titleBarArea: RowLayout {
        anchors.fill: parent
        // spacing: 24


        // search field
        AutoSuggestBox {
            id: searchField
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: 600
            Layout.fillWidth: true
            placeholderText: qsTr("Search plugins...")
            suggestions: PlazaBridge.plugins || []
            textRole: "name"

            // 选中建议项或按回车：名称精确匹配则直达插件详情页，否则进入搜索页
            onAccepted: {
                var keyword = searchField.text.trim()
                if (!keyword)
                    return
                var plugins = PlazaBridge.plugins || []
                var matched = null
                for (var i = 0; i < plugins.length; i++) {
                    var p = plugins[i]
                    if (p && p.name && p.name.toLowerCase() === keyword.toLowerCase()) {
                        matched = p
                        break
                    }
                }
                if (matched && matched.id) {
                    navigationView.push(PathManager.qml("pages/plaza/Plugin.qml"), { pluginId: matched.id })
                } else {
                    navigationView.push(PathManager.qml("pages/plaza/Search.qml"), { query: keyword })
                }
            }
        }



        ToolButton {
            flat: true
            Layout.alignment: Qt.AlignRight
            icon.name: "ic_fluent_arrow_sync_20_regular"
            size: 18

            ToolTip {
                text: qsTr("Refresh")
                visible: parent.hovered
            }

            onClicked: {
                PlazaBridge.refreshAll()
            }

            ProgressRing {
                visible: PluginManager.plazaInstallActive
                // Layout.alignment: Qt.AlignVCenter
                strokeWidth: 3
                anchors {
                    right: parent.left
                    verticalCenter: parent.verticalCenter
                    rightMargin: 12
                }
                size: 20
                value: PluginManager.installProgress / 100
                backgroundColor: indeterminate ? "transparent" : Colors.proxy.controlAltTertiaryColor
                indeterminate: PluginManager.installStatus === "Installing"

                ToolTip {
                    visible: parent.hovered
                    text: PluginManager.installTotalBytes > 0
                            ? qsTr("Downloaded: %1 / %2")
                              .arg(root.formatBytes(PluginManager.installDownloadedBytes))
                              .arg(root.formatBytes(PluginManager.installTotalBytes))
                            : qsTr("Downloading")
                }
            }
        }
    }

    Component.onCompleted: {
        PlazaBridge.refreshAll()
    }

    Connections {
        target: PlazaBridge
        function onErrorOccurred(msg) {
            floatLayer.createInfoBar({
                title: qsTr("Error"),
                text: msg,
                severity: Severity.Error,
                timeout: 5000
            })
        }
    }

    Connections {
        target: PluginManager

        function pluginName(pluginId) {
            var plugins = PluginManager.plugins || []
            for (var index = 0; index < plugins.length; ++index) {
                if (plugins[index].id === pluginId)
                    return plugins[index].name || pluginId
            }
            return pluginId
        }

        function onPlazaTransferSucceeded(pluginId, version, kind) {
            var action = kind === "update" ? qsTr("Plugin updated") : qsTr("Plugin installed")
            floatLayer.createInfoBar({
                title: action,
                text: qsTr("%1 v%2 is ready to use.").arg(pluginName(pluginId)).arg(version),
                severity: Severity.Success,
                timeout: 5000
            })
        }

        function onPlazaTransferFailed(pluginId, message, kind) {
            var title = kind === "update" ? qsTr("Plugin update failed") : qsTr("Plugin installation failed")
            floatLayer.createInfoBar({
                title: title,
                text: message,
                severity: Severity.Error,
                timeout: -1
            })
        }

        function onPlazaTransferCancelled(pluginId) {
            floatLayer.createInfoBar({
                title: qsTr("Download cancelled"),
                text: qsTr("The download for %1 was cancelled.").arg(pluginName(pluginId)),
                severity: Severity.Info,
                timeout: 4000
            })
        }

        function onShowPlazaDownloadsRequested() {
            navigationView.push(PathManager.qml("pages/plaza/Downloads.qml"))
        }
    }

    navigationItems: [
        {
            title: qsTr("Home"),
            page: PathManager.qml("pages/plaza/Home.qml"),
            icon: "ic_fluent_home_20_regular",
        },
        {
            title: qsTr("Plugins"),
            page: PathManager.qml("pages/plaza/Plugins.qml"),
            icon: "ic_fluent_apps_list_20_regular",
        },
        {
            title: qsTr("Search"),
            page: PathManager.qml("pages/plaza/Search.qml"),
            icon: "ic_fluent_search_20_regular",
        },
        {
            title: qsTr("Downloads"),
            page: PathManager.qml("pages/plaza/Downloads.qml"),
            icon: "ic_fluent_cloud_arrow_down_20_regular",
            position: Position.Bottom
        }
    ]



    Watermark {
        anchors.centerIn: parent
    }
}
