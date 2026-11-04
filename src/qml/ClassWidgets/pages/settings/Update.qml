import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42 * 2

    title: qsTr("Class Widgets Update")

    property string updaterLatestVersion: ""
    property string updaterLatestUrl: ""
    property string errorDetails: ""

    // 服务器地址由 Python 侧统一提供，QML 不再重复维护一份常量。
    readonly property var serverUrls: UpdaterBridge.releasesServers
    // { url: { state: "testing" | "success" | "error", text: "..." } }
    property var pingResults: ({})
    // 按下测试按钮期间抑制整行点击，避免 Button 的点击冒泡到 SettingItem。
    property bool suppressServerClick: false

    readonly property string activeServerId: {
        const server = String(Configs.data.network.releases_server || "");
        if (server === "custom" || serverUrl(server) !== "")
            return server;
        // 兼容没有 releases_server 字段的旧配置或手动修改的配置。
        return serverIdForUrl(Configs.data.network.releases_url);
    }

    function normalizeUrl(url) {
        return String(url || "").trim().replace(/\/+$/, "");
    }

    function serverUrl(serverId) {
        return String((serverUrls || {})[serverId] || "");
    }

    function serverIdForUrl(url) {
        const normalized = normalizeUrl(url);
        if (normalized === "")
            return "official";
        const servers = serverUrls || {};
        for (const serverId in servers) {
            if (normalizeUrl(servers[serverId]) === normalized)
                return serverId;
        }
        return "custom";
    }

    function isValidUrl(url) {
        return /^https?:\/\/\S+$/i.test(String(url || "").trim());
    }

    function serverLocked() {
        return Configs.isKeyLocked("network.releases_url") || Configs.isKeyLocked("network.releases_server") || Configs.isKeyLocked("network.custom_releases_url");
    }

    function selectServer(serverId) {
        if (root.suppressServerClick || root.serverLocked())
            return;
        const url = root.serverUrl(serverId);
        if (!url)
            return;
        Configs.set("network.releases_server", serverId);
        Configs.set("network.releases_url", url);
    }

    function selectCustomServer() {
        if (root.suppressServerClick || root.serverLocked())
            return;
        const url = String(customUrlField.text || "").trim();
        if (!root.isValidUrl(url)) {
            customUrlField.forceActiveFocus();
            return;
        }
        Configs.set("network.custom_releases_url", url);
        Configs.set("network.releases_server", "custom");
        Configs.set("network.releases_url", url);
    }

    function commitCustomUrl(text) {
        if (root.serverLocked())
            return;
        const url = String(text || "").trim();
        Configs.set("network.custom_releases_url", url);
        if (root.activeServerId !== "custom")
            return;
        if (root.isValidUrl(url)) {
            Configs.set("network.releases_url", url);
        } else {
            // 自定义地址被清空或无效时回退到官方，避免保存不可用的更新地址。
            Configs.set("network.releases_server", "official");
            Configs.set("network.releases_url", root.serverUrl("official"));
        }
    }

    function holdServerClick() {
        root.suppressServerClick = true;
    }

    function releaseServerClick() {
        Qt.callLater(function () {
            root.suppressServerClick = false;
        });
    }

    function pingResultKey(url) {
        return String(url || "").trim();
    }

    function setPingResult(url, state, text) {
        const key = pingResultKey(url);
        const results = Object.assign({}, pingResults);
        results[key] = {
            state: state,
            text: text
        };
        pingResults = results;
    }

    function pingState(url) {
        const result = pingResults[pingResultKey(url)];
        return result ? result.state : "";
    }

    function pingText(url) {
        const result = pingResults[pingResultKey(url)];
        return result ? result.text : "";
    }

    function pingColor(url) {
        switch (pingState(url)) {
        case "success":
            return Theme.currentTheme.colors.systemSuccessColor;
        case "error":
            return Theme.currentTheme.colors.systemCriticalColor;
        default:
            return Theme.currentTheme.colors.textSecondaryColor;
        }
    }

    function pingServer(url) {
        const target = String(url || "").trim();
        if (!root.isValidUrl(target)) {
            setPingResult(target, "error", qsTr("Enter a valid URL first."));
            return;
        }
        setPingResult(target, "testing", "");
        UpdaterBridge.pingServer(target);
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Image {
                Layout.preferredWidth: 84
                Layout.preferredHeight: 84
                source: {
                    switch (UpdaterBridge.status) {
                    case "UpToDate":
                        return PathManager.images("icons/cw2_up_to_date.png");
                    case "UpdateAvailable":
                        return PathManager.images("icons/cw2_update_available.png");
                    case "Downloading":
                        return PathManager.images("icons/cw2_update.png");
                    case "Downloaded":
                        return PathManager.images("icons/cw2_update.png");
                    case "Installing":
                        return PathManager.images("icons/cw2_settings.png");
                    case "Error":
                        return PathManager.images("icons/cw2_error.png");
                    default:
                        return PathManager.images("icons/cw2_update.png");
                    }
                }
                fillMode: Image.PreserveAspectFit
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    typography: Typography.BodyLarge
                    text: {
                        switch (UpdaterBridge.status) {
                        case "Checking":
                            return qsTr("Checking for updates...");
                        case "UpToDate":
                            return qsTr("You're up to date!");
                        case "UpdateAvailable":
                            return qsTr("New version available!");
                        case "Downloading":
                            return qsTr("Downloading update...");
                        case "Installing":
                            return qsTr("Installing update...");
                        case "Downloaded":
                            return qsTr("Update ready to install");
                        case "Error":
                            return qsTr("Update failed");
                        case "Cancelled":
                            return qsTr("Download cancelled");
                        default:
                            return qsTr("Check for updates");
                        }
                    }
                }

                Text {
                    id: details
                    Layout.fillWidth: true
                    color: Colors.proxy.textSecondaryColor
                    typography: Typography.Caption
                    text: {
                        switch (UpdaterBridge.status) {
                        case "Checking":
                            return qsTr("Waiting for response...");
                        case "UpToDate":
                            return qsTr("You're on the latest version");
                        case "UpdateAvailable":
                            return updaterLatestVersion ? qsTr("Latest version: %1").arg(updaterLatestVersion) : qsTr("New version available");
                        case "Downloading":
                            {
                                const percent = UpdaterBridge.progress.toFixed(1);
                                const speedKB = UpdaterBridge.speed / 1024;
                                const speedText = speedKB >= 1024 ? qsTr("%1 MB/s").arg((speedKB / 1024).toFixed(1)) : qsTr("%1 KB/s").arg(speedKB.toFixed(1));
                                return qsTr("Progress: %1% — %2").arg(percent).arg(speedText);
                            }
                        case "Installing":
                            return qsTr("Applying the update...");
                        case "Downloaded":
                            return qsTr("Ready to install now");
                        case "Error":
                            return root.errorDetails !== "" ? root.errorDetails : qsTr("Something went wrong!");
                        case "Cancelled":
                            return qsTr("Download was cancelled");
                        default:
                            return qsTr("Click \"Check for updates\" to search for updates");
                        }
                    }
                    wrapMode: Text.Wrap
                }
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            opacity: UpdaterBridge.status === "Downloading" || UpdaterBridge.status === "Installing" || UpdaterBridge.status === "Checking"
            value: UpdaterBridge.status === "Downloading" ? (UpdaterBridge.progress / 100) : 0
            indeterminate: UpdaterBridge.status !== "Downloading"
        }

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignRight

            // 检查更新
            Button {
                id: checkBtn
                text: qsTr("Check for updates")
                // icon.name: "ic_fluent_box_checkmark_20_regular"
                visible: {
                    switch (UpdaterBridge.status) {
                    case "Idle":
                    case "Error":
                    case "UpToDate":
                    case "Checking":
                    case "UpdateAvailable":
                        return true;
                    default:
                        return false;
                    }
                }
                highlighted: UpdaterBridge.status !== "UpdateAvailable" || (UpdaterBridge.status === "UpdateAvailable" && !downloadBtn.visible)
                enabled: UpdaterBridge.status !== "Checking"
                onClicked: {
                    root.errorDetails = "";
                    updaterLatestVersion = "";
                    updaterLatestUrl = "";
                    UpdaterBridge.checkUpdate();
                }
            }

            // 下载更新（只有有 url 时可见）
            Button {
                id: downloadBtn
                text: qsTr("Download")
                icon.name: "ic_fluent_arrow_download_20_regular"
                highlighted: true
                visible: UpdaterBridge.status === "UpdateAvailable" && updaterLatestUrl !== ""
                onClicked: {
                    root.errorDetails = "";
                    UpdaterBridge.startDownload();
                }
            }

            // 取消下载
            Button {
                id: cancelBtn
                icon.name: "ic_fluent_dismiss_20_regular"
                text: qsTr("Cancel")
                visible: UpdaterBridge.status === "Downloading"
                onClicked: {
                    UpdaterBridge.stopDownload();
                }
            }

            // 安装更新（重启以安装）
            Button {
                id: restartBtn
                highlighted: true
                icon.name: "ic_fluent_arrow_counterclockwise_20_regular"
                text: qsTr("Restart and Install")
                visible: UpdaterBridge.status === "Downloaded"
                onClicked: {
                    UpdaterBridge.startInstall();
                }
            }
        }
    }

    // “更多选项”
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("More options")
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_channel_20_regular"
            title: qsTr("Update Channel")
            description: qsTr("Choose which update channel to use")

            ComboBox {
                model: ListModel {
                    ListElement {
                        text: qsTr("Release")
                        value: "release"
                    }
                    ListElement {
                        text: qsTr("Alpha")
                        value: "alpha"
                    }
                }
                textRole: "text"
                valueRole: "value"
                enabled: !Configs.isKeyLocked("app.channel")
                onCurrentValueChanged: if (focus)
                    Configs.set("app.channel", currentValue)
                Component.onCompleted: {
                    switch (Configs.data.app.channel) {
                    case "release":
                        currentIndex = 0;
                        break;
                    case "alpha":
                        currentIndex = 1;
                        break;
                    default:
                        currentIndex = 0;
                        // TODO: check enabled: !Configs.isKeyLocked("app.channel")
                        Configs.set("app.channel", "release");
                        break;
                    }
                }
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_network_check_20_regular"
            title: qsTr("Use Mirror Source")
            description: qsTr("If GitHub is slow or unavailable in your region, use a mirror to download updates faster")

            action: Switch {
                enabled: !Configs.isKeyLocked("network.mirror_enabled")
                onCheckedChanged: Configs.set("network.mirror_enabled", checked)
                Component.onCompleted: checked = Configs.data.network.mirror_enabled
            }

            SettingItem {
                title: qsTr("Select Mirror")
                description: qsTr("Choose a mirror source for downloading updates")

                ComboBox {
                    id: mirrorCombo
                    Layout.fillWidth: true
                    model: Object.keys(Configs.data.network.mirrors)
                    textRole: ""

                    enabled: !Configs.isKeyLocked("network.current_mirror")
                    onCurrentTextChanged: if (focus)
                        Configs.set("network.current_mirror", currentText)
                    Component.onCompleted: {
                        for (var i = 0; i < model.count; i++) {
                            if (model.get(i) === Configs.data.network.current_mirror) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }

                    delegate: ItemDelegate {
                        text: modelData + " (" + Configs.data.network.mirrors[modelData] + ")"
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_arrow_sync_checkmark_20_regular"
            title: qsTr("Auto check for updates")
            description: qsTr("Automatically check for updates and download them when they are available \n" + "* Requires restart")

            Switch {
                enabled: !Configs.isKeyLocked("network.auto_check_updates")
                onCheckedChanged: Configs.set("network.auto_check_updates", checked)
                Component.onCompleted: checked = Configs.data.network.auto_check_updates
            }
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_cloud_link_20_regular"
            title: qsTr("Update Server")
            description: qsTr("Choose an update server.")

            SettingItem {
                title: qsTr("Official")
                description: qsTr("Use the official update server.")
                clickable: !root.serverLocked()
                actionIcon.name: root.activeServerId === "official" ? "ic_fluent_checkmark_circle_20_filled" : "ic_fluent_chevron_right_20_regular"
                actionIcon.color: root.activeServerId === "official" ? Theme.currentTheme.colors.primaryColor : Theme.currentTheme.colors.textSecondaryColor
                onClicked: root.selectServer("official")

                RowLayout {
                    spacing: 6

                    Text {
                        visible: text !== ""
                        text: root.pingText(root.serverUrl("official"))
                        color: root.pingColor(root.serverUrl("official"))
                        typography: Typography.Caption
                    }

                    Button {
                        flat: true
                        icon.name: "ic_fluent_network_check_20_regular"
                        enabled: root.pingState(root.serverUrl("official")) !== "testing"
                        onPressedChanged: {
                            if (pressed)
                                root.holdServerClick();
                            else
                                root.releaseServerClick();
                        }
                        onClicked: root.pingServer(root.serverUrl("official"))
                    }
                }
            }

            SettingItem {
                title: qsTr("Cloudflare R2 (WNAM)")
                description: qsTr("Use the Cloudflare R2 mirror in Western North America.")
                clickable: !root.serverLocked()
                actionIcon.name: root.activeServerId === "wnam" ? "ic_fluent_checkmark_circle_20_filled" : "ic_fluent_chevron_right_20_regular"
                actionIcon.color: root.activeServerId === "wnam" ? Theme.currentTheme.colors.primaryColor : Theme.currentTheme.colors.textSecondaryColor
                onClicked: root.selectServer("wnam")

                RowLayout {
                    spacing: 6

                    Text {
                        visible: text !== ""
                        text: root.pingText(root.serverUrl("wnam"))
                        color: root.pingColor(root.serverUrl("wnam"))
                        typography: Typography.Caption
                    }

                    Button {
                        flat: true
                        icon.name: "ic_fluent_network_check_20_regular"
                        enabled: root.pingState(root.serverUrl("wnam")) !== "testing"
                        onPressedChanged: {
                            if (pressed)
                                root.holdServerClick();
                            else
                                root.releaseServerClick();
                        }
                        onClicked: root.pingServer(root.serverUrl("wnam"))
                    }
                }
            }

            SettingItem {
                title: qsTr("Cloudflare R2 (APAC)")
                description: qsTr("Use the Cloudflare R2 mirror in the Asia-Pacific region.")
                clickable: !root.serverLocked()
                actionIcon.name: root.activeServerId === "apac" ? "ic_fluent_checkmark_circle_20_filled" : "ic_fluent_chevron_right_20_regular"
                actionIcon.color: root.activeServerId === "apac" ? Theme.currentTheme.colors.primaryColor : Theme.currentTheme.colors.textSecondaryColor
                onClicked: root.selectServer("apac")

                RowLayout {
                    spacing: 6

                    Text {
                        visible: text !== ""
                        text: root.pingText(root.serverUrl("apac"))
                        color: root.pingColor(root.serverUrl("apac"))
                        typography: Typography.Caption
                    }

                    Button {
                        flat: true
                        icon.name: "ic_fluent_network_check_20_regular"
                        enabled: root.pingState(root.serverUrl("apac")) !== "testing"
                        onPressedChanged: {
                            if (pressed)
                                root.holdServerClick();
                            else
                                root.releaseServerClick();
                        }
                        onClicked: root.pingServer(root.serverUrl("apac"))
                    }
                }
            }

            SettingItem {
                visible: Configs.data.app.debug_mode
                title: qsTr("Custom URL")
                description: qsTr("Use a custom update server.")
                clickable: !root.serverLocked()
                actionIcon.name: root.activeServerId === "custom" ? "ic_fluent_checkmark_circle_20_filled" : "ic_fluent_chevron_right_20_regular"
                actionIcon.color: root.activeServerId === "custom" ? Theme.currentTheme.colors.primaryColor : Theme.currentTheme.colors.textSecondaryColor
                onClicked: root.selectCustomServer()

                RowLayout {
                    spacing: 4

                    TextField {
                        id: customUrlField
                        Layout.preferredWidth: 220
                        Layout.minimumWidth: 120
                        Layout.maximumWidth: 280
                        placeholderText: qsTr("https://example.com/releases.json")
                        enabled: !root.serverLocked()
                        text: Configs.data.network.custom_releases_url || ""
                        onEditingFinished: root.commitCustomUrl(text)
                    }

                    Text {
                        visible: text !== ""
                        text: root.pingText(customUrlField.text)
                        color: root.pingColor(customUrlField.text)
                        typography: Typography.Caption
                    }

                    Button {
                        flat: true
                        icon.name: "ic_fluent_wifi_20_regular"
                        text: root.pingState(customUrlField.text) === "testing" ? qsTr("Testing...") : qsTr("Test latency")
                        enabled: root.pingState(customUrlField.text) !== "testing"
                        onPressedChanged: {
                            if (pressed)
                                root.holdServerClick();
                            else
                                root.releaseServerClick();
                        }
                        onClicked: root.pingServer(customUrlField.text)
                    }
                }
            }
        }
    }

    // 连接 Python 信号
    Connections {
        target: UpdaterBridge

        function onUpdateAvailable(version, url) {
            root.updaterLatestVersion = version;
            root.updaterLatestUrl = url || "";
        }

        // 当 errorDetails 属性改变时触发（bridge 发 errorDetailsChanged）
        function onErrorDetailsChanged(message) {
            root.errorDetails = message;
        }

        // 也监听后端的 errorOccurred 信号（如果后端发这个）
        function onErrorOccurred(message) {
            root.errorDetails = message;
        }

        function onPingFinished(url, success, latency, error) {
            if (success) {
                root.setPingResult(url, "success", qsTr("%1 ms").arg(Math.round(latency)));
            } else {
                root.setPingResult(url, "error", qsTr("Failed"));
            }
        }

        // 下载完成准备安装
        function onInstallReady(version) {
            // backend 会发 installReady(version) -> 切换到 Downloaded 状态
            root.updaterLatestVersion = version;
        }
    }
}
