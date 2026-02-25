import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentPage {
    id: root
    title: qsTr("Plugins")

    InfoBar {
        Layout.fillWidth: true
        title: qsTr("Warning")
        text: qsTr(
            "The plugin system is still under development. "
        )
        severity: Severity.Warning
    }

    function uninstallPlugin(pluginId) {
        if (PluginManager.uninstallPlugin(pluginId)) {
            floatLayer.createInfoBar({
                title: qsTr("Success"),
                text: qsTr(
                    "The plugin has been uninstalled successfully. " +
                    "Restart to take effect."
                ),
                severity: Severity.Success,
                timeout: 5000,
            })
        } else {
            floatLayer.createInfoBar({
                title: qsTr("Uninstall Failed"),
                text: qsTr("Failed to uninstall the plugin. Please try again later."),
                severity: Severity.Error,
                timeout: 5000,
            })
        }
    }

    function showPluginReplaceDialog(pluginData, callback) {
        pluginReplaceDialog.pluginName = pluginData.name || ""
        pluginReplaceDialog.pluginId = pluginData.id || ""
        pluginReplaceDialog.newVersion = pluginData.version || ""
        pluginReplaceDialog.existingVersion = pluginData.existing_version || ""
        pluginReplaceDialog.isUpdate = pluginData.version !== pluginData.existing_version
        
        pluginReplaceDialog.open()
        
        var acceptHandler = function() {
            if (callback) callback(true)
        }
        var rejectHandler = function() {
            if (callback) callback(false)
        }
        pluginReplaceDialog.accepted.connect(acceptHandler)
        pluginReplaceDialog.rejected.connect(rejectHandler)
    }

    function importPluginWithConflictCheck() {
        // 调用后端打开文件对话框并检查冲突
        var conflicts = PluginManager.importPlugin()
        
        if (conflicts.length > 0) {
            // 有冲突，显示确认对话框
            var conflict = conflicts[0]  // 暂时只处理第一个冲突
            showPluginReplaceDialog(conflict, function(confirmed) {
                if (confirmed) {
                    // 从冲突信息中获取zip路径
                    if (conflict.zip_path) {
                        performImport(conflict.zip_path)
                    }
                }
            })
        }
        // 如果没有冲突，后端已经在importPlugin中处理了导入
    }

    function proceedWithImport(zip_path) {
        if (!zip_path) {
            return
        }

        // 检查插件冲突
        var conflicts = PluginManager.checkPluginConflicts(zip_path)
        
        if (conflicts.length > 0) {
            // 有冲突，显示确认对话框
            var conflict = conflicts[0]  // 暂时只处理第一个冲突
            showPluginReplaceDialog(conflict, function(confirmed) {
                if (confirmed) {
                    performImport(zip_path)
                }
            })
        } else {
            // 没有冲突，直接导入
            performImport(zip_path)
        }
    }

    function performImport(zip_path) {
        if (PluginManager.importPluginWithPath(zip_path)) {
            floatLayer.createInfoBar({
                title: qsTr("Importing"),
                text: qsTr("Importing the selected plugin. Please wait..."),
                severity: Severity.Info
            })
        }
    }

    PluginReplaceConfirmDialog {
        id: pluginReplaceDialog
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Your plugins")
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Get Plugins")
            description: qsTr("Find and install plugins from the Extension Plaza (WEB)")

            Hyperlink {
                text: qsTr("Go to Extension Plaza")
                // enabled: false
                openUrl: "https://plaza.cw.rinlit.cn"
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            TextField {
                Layout.maximumWidth: 300
                Layout.fillWidth: true
                id: searchField
                placeholderText: qsTr("Search for plugins")
            }

            Item { Layout.fillWidth: true }

            Connections {
                target: PluginManager

                function onPluginImportSucceeded() {
                    floatLayer.createInfoBar({
                        title: qsTr("Success"),
                        text: qsTr("The plugin has been imported successfully."),
                        severity: Severity.Success,
                        timeout: 5000,
                    })
                }

                function onPluginImportFailed(msg) {
                    floatLayer.createInfoBar({
                        title: qsTr("Import Failed"),
                        text: qsTr("The selected plugin could not be imported.\n") + msg,
                        severity: Severity.Error,
                        timeout: 5000,
                    })
                }
            }

            Button {
                icon.name: "ic_fluent_add_20_regular"
                text: qsTr("Import")
                onClicked: {
                    importPluginWithConflictCheck()
                }
            }
        }

        Segmented {
            id: segmented
            Layout.fillWidth: true

            SegmentedItem {
                text: qsTr("All")
            }
            SegmentedItem {
                text: qsTr("Enabled")
            }
            SegmentedItem {
                text: qsTr("Disabled")
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                /// 搜索功能
                model: PluginManager.plugins.filter(function(plugin) {
                    // 关键字搜索
                    var kw = searchField.text.trim().toLowerCase();
                    if (kw !== "") {
                        var tagsText = (plugin.tags ? plugin.tags.join(" ") : "").toLowerCase();
                        if (
                            plugin.name.toLowerCase().indexOf(kw) === -1 &&
                            plugin.author.toLowerCase().indexOf(kw) === -1 &&
                            // plugin.id.toLowerCase().indexOf(kw) === -1 &&
                            tagsText.indexOf(kw) === -1
                        ) {
                            return false;
                        }
                    }

                    // 启用/禁用过滤
                    var enabled = PluginManager.isPluginEnabled(plugin.id);
                    if (segmented.currentIndex === 1 && !enabled) return false; // 只显示启用
                    if (segmented.currentIndex === 2 && enabled) return false;  // 只显示禁用

                    return true
                })

                delegate: Clip {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 70
                    id: frame

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            color: Colors.proxy.backgroundColor
                            radius: 12
                            width: 48
                            height: 48
                            border.color: Colors.proxy.controlBorderColor
                            border.width: 1

                            Icon {
                                id: pluginIcon
                                name: !source ? "ic_fluent_apps_add_in_20_filled" : ""
                                source: "icon" in modelData ? modelData.icon : ""
                                anchors.fill: parent
                                size: "icon" in modelData ? 48 : 32
                                opacity: "icon" in modelData ? 1 : 0.5

                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    anchors.fill: parent
                                    maskSource: Rectangle {
                                        width: pluginIcon.width
                                        height: pluginIcon.height
                                        radius: 12
                                    }
                                }
                            }
                        }
                        ColumnLayout {
                            RowLayout {
                                Layout.fillWidth: true
                                InfoBadge {
                                    visible: modelData._type === "builtin"
                                    text: qsTr("Built-in")
                                    severity: Severity.Info
                                    solid: false
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    wrapMode: Text.NoWrap
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.author
                                wrapMode: Text.NoWrap
                                elide: Text.ElideRight
                                typography: Typography.Caption
                                color: Colors.proxy.textSecondaryColor
                            }
                        }

                        // 右侧区域
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 18

                            // 兼容警告
                            Icon {
                                size: 24
                                color: Colors.proxy.systemCriticalColor
                                name: "ic_fluent_warning_20_filled"
                                visible: !PluginManager.isPluginCompatible(modelData.id)
                                opacity: compatibilityHoverHandler.hovered ? 0.8 : 1

                                TapHandler {
                                    onTapped: {
                                        compatibilityFlyout.open()
                                    }
                                }

                                HoverHandler {
                                    id: compatibilityHoverHandler
                                }

                                Flyout {
                                    id: compatibilityFlyout
                                    text: qsTr(
                                        "This plugin requires API version %1, but current API version is %2. \n" +
                                        "It's incompatible and may cause unexpected issues."
                                    ).arg(modelData.api_version).arg(PluginManager.getAPIVersion())
                                }

                            }

                            // 启用/禁用
                            Switch {
                                text: !checked? qsTr("Disabled") : qsTr("Enabled")
                                enabled: modelData._type === "builtin" ? Configs.data.app.debug_mode : true
                                onToggled: PluginManager.setPluginEnabled(modelData.id, checked)

                                Component.onCompleted: {
                                    checked = PluginManager.isPluginEnabled(modelData.id)
                                }
                            }

                            ToolButton {
                                flat: true
                                icon.name: "ic_fluent_more_horizontal_20_regular"
                                onClicked: {
                                    actionMenu.open()
                                }

                                Menu {
                                    id: actionMenu

                                    Menu {
                                        icon.name: "ic_fluent_open_20_regular"
                                        title: qsTr("Open In")
                                        MenuItem {
                                            icon.name: "ic_fluent_folder_open_20_regular"
                                            text: Qt.platform.os === "osx" ? qsTr("Finder") : qsTr("File Explorer")
                                            enabled: modelData._type !== "builtin"
                                            onTriggered: {
                                                if (!PluginManager.openPluginFolder(modelData.id)) {
                                                    floatLayer.createInfoBar({
                                                        title: qsTr("Open Failed"),
                                                        text: qsTr("Failed to open the plugin folder."),
                                                        severity: Severity.Error,
                                                        timeout: 5000,
                                                    })
                                                }
                                            }
                                        }
                                        MenuItem {
                                            icon.name: "ic_fluent_link_20_regular"
                                            text: qsTr("External Online Repository")
                                            enabled: "url" in modelData
                                            onTriggered: Qt.openUrlExternally(modelData.url)
                                        }
                                    }
                                    MenuSeparator { }
                                    MenuItem {
                                        icon.name: "ic_fluent_delete_20_regular"
                                        text: qsTr("Uninstall")
                                        enabled: modelData._type !== "builtin"
                                        onTriggered: {
                                            uninstallPlugin(modelData.id)     // 卸载插件
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}