import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../../Components/plaza" as PlazaComponents
import "../../Components/tutorial" as TutorialComponents

TutorialComponents.TutorialPage {
    id: root

    property var tutorial
    property var installQueue: []
    property var failedInstallations: []
    property var successfulInstallations: []
    property var selectedPluginIdsState: []
    property int installIndex: 0
    property string currentInstallingId: ""
    property bool installingSelection: false
    property bool currentInstallFinished: false
    readonly property var recommendationsBridge: typeof TutorialRecommendationsBridge !== "undefined"
                                                  ? TutorialRecommendationsBridge : null
    readonly property var recommendations: root.recommendationsBridge
                                           ? (root.recommendationsBridge.recommendations || []) : []
    readonly property bool recommendationsLoading: root.recommendationsBridge
                                                   ? root.recommendationsBridge.loading : false
    readonly property string recommendationsError: root.recommendationsBridge
                                                   ? (root.recommendationsBridge.error || "") : ""
    readonly property string recommendationsBaseUrl: root.recommendationsBridge
                                                    ? (root.recommendationsBridge.baseUrl || "") : ""

    title: qsTr("Recommended plugins")
    description: qsTr("Pick certified plugins from Plugin Plaza to install with your first setup.")
    currentStep: 7
    totalSteps: 7
    fillOperationHeight: true
    managesNextNavigation: true
    nextText: installingSelection
              ? qsTr("Installing plugins")
              : selectedPluginIds().length === 0
                ? qsTr("Finish")
                : failedInstallations.length > 0
                  ? qsTr("Skip")
                  : qsTr("Finish & Install")
    nextIcon: "ic_fluent_checkmark_20_regular"
    allowNext: !root.installingSelection
    footerSecondaryVisible: !root.installingSelection
                            && root.selectedFailedPluginIds().length > 0
    footerSecondaryEnabled: !PluginManager.plazaInstallActive
    footerSecondaryText: qsTr("Retry")
    footerSecondaryIcon: "ic_fluent_arrow_clockwise_20_regular"
    icon.source: PathManager.images("icons/cw2_plugin.png")

    Timer {
        id: installQueueContinueTimer
        interval: 120
        repeat: false
        onTriggered: root.continueInstallQueue()
    }

    Timer {
        id: installFailureSettleTimer
        interval: 800
        repeat: false
        onTriggered: root.finishCurrentInstallItem()
    }

    Component.onCompleted: {
        if (root.recommendationsBridge)
            root.recommendationsBridge.fetchRecommendations()
    }

    Connections {
        target: root.recommendationsBridge

        function onRecommendationsChanged() {
            root.initializeSelectionState()
        }
    }

    function isInstalled(pluginId) {
        var plugins = PluginManager.plugins || []
        for (var i = 0; i < plugins.length; ++i) {
            if (plugins[i].id === pluginId)
                return true
        }
        var pending = PluginManager.pendingPluginOperations || []
        for (var j = 0; j < pending.length; ++j) {
            if (pending[j].plugin_id === pluginId && pending[j].type === "install")
                return true
        }
        return false
    }

    function pluginName(pluginId) {
        var plugins = root.recommendations
        for (var i = 0; i < plugins.length; ++i) {
            if (plugins[i].id === pluginId)
                return plugins[i].name || pluginId
        }
        return pluginId
    }

    function selectedPluginIds() {
        var result = []
        for (var i = 0; i < selectedPluginIdsState.length; ++i) {
            var pluginId = selectedPluginIdsState[i]
            if (!root.isInstalled(pluginId))
                result.push(pluginId)
        }
        return result
    }

    function selectedFailedPluginIds() {
        var result = []
        for (var i = 0; i < failedInstallations.length; ++i) {
            var pluginId = failedInstallations[i].id
            if (selectedPluginIdsState.indexOf(pluginId) >= 0)
                result.push(pluginId)
        }
        return result
    }

    function isSelected(pluginId) {
        if (!pluginId)
            return false
        return root.isInstalled(pluginId) || selectedPluginIdsState.indexOf(pluginId) >= 0
    }

    function setPluginSelected(pluginId, selected) {
        if (!pluginId || root.isInstalled(pluginId))
            return

        updatePluginSelection(pluginId, selected)
    }

    function updatePluginSelection(pluginId, selected) {
        if (!pluginId)
            return

        var next = selectedPluginIdsState.slice()
        var index = next.indexOf(pluginId)
        if (selected && index < 0)
            next.push(pluginId)
        if (!selected && index >= 0)
            next.splice(index, 1)
        selectedPluginIdsState = next
    }

    function initializeSelectionState() {
        var next = selectedPluginIdsState.slice()

        for (var j = next.length - 1; j >= 0; --j) {
            if (root.isInstalled(next[j]))
                next.splice(j, 1)
        }

        selectedPluginIdsState = next
    }

    function selectAllPlugins() {
        var next = []
        var recommendations = root.recommendations
        for (var i = 0; i < recommendations.length; ++i) {
            var pluginId = recommendations[i].id || ""
            if (pluginId.length > 0 && !root.isInstalled(pluginId))
                next.push(pluginId)
        }
        selectedPluginIdsState = next
    }

    function clearPluginSelection() {
        selectedPluginIdsState = []
    }

    function selectablePluginCount() {
        var count = 0
        var recommendations = root.recommendations
        for (var i = 0; i < recommendations.length; ++i) {
            if (recommendations[i].id && !root.isInstalled(recommendations[i].id))
                count++
        }
        return count
    }

    function installProgressText() {
        if (!root.installingSelection)
            return root.selectedPluginIds().length > 0
                   ? qsTr("%1 selected").arg(root.selectedPluginIds().length)
                   : qsTr("No plugins selected")

        return qsTr("%1/%2 plugins")
                .arg(Math.min(root.installIndex + 1, root.installQueue.length))
                .arg(root.installQueue.length)
    }

    function installProgressIndeterminate() {
        return root.installingSelection
                && PluginManager.installStatus !== "Downloading"
                && PluginManager.installStatus !== "Paused"
    }

    function addFailure(pluginId, message) {
        if (!pluginId)
            return

        var next = []
        for (var i = 0; i < failedInstallations.length; ++i) {
            if (failedInstallations[i].id !== pluginId)
                next.push(failedInstallations[i])
        }
        next.push({
            "id": pluginId,
            "name": pluginName(pluginId),
            "message": message || qsTr("Installation failed")
        })
        failedInstallations = next
        setPluginSelected(pluginId, true)
    }

    function removeFailure(pluginId) {
        var next = []
        for (var i = 0; i < failedInstallations.length; ++i) {
            if (failedInstallations[i].id !== pluginId)
                next.push(failedInstallations[i])
        }
        failedInstallations = next
    }

    function addSuccess(pluginId) {
        var next = successfulInstallations.slice()
        if (next.indexOf(pluginId) < 0)
            next.push(pluginId)
        successfulInstallations = next
        removeFailure(pluginId)
        updatePluginSelection(pluginId, false)
    }

    function installSingle(pluginId) {
        if (!pluginId || root.isInstalled(pluginId))
            return false
        // Tutorial installs are enabled for the first load after restart.
        PluginManager.setPluginEnabled(pluginId, true)
        if (!PluginManager.installFromPlaza(pluginId)) {
            PluginManager.setPluginEnabled(pluginId, false)
            return false
        }
        return true
    }

    function startInstallQueue(ids) {
        installQueue = ids.slice()
        installIndex = 0
        currentInstallingId = ""
        currentInstallFinished = false
        installingSelection = installQueue.length > 0
        continueInstallQueue()
    }

    function finishCurrentInstallItem() {
        if (!installingSelection || currentInstallFinished)
            return

        installFailureSettleTimer.stop()
        currentInstallFinished = true
        currentInstallingId = ""
        installIndex++
        installQueueContinueTimer.restart()
    }

    function continueInstallQueue() {
        if (!installingSelection)
            return

        while (installIndex < installQueue.length && root.isInstalled(installQueue[installIndex])) {
            PluginManager.setPluginEnabled(installQueue[installIndex], true)
            installIndex++
        }

        if (installIndex >= installQueue.length) {
            installingSelection = false
            currentInstallingId = ""
            if (failedInstallations.length === 0)
                tutorial.goNext()
            return
        }

        if (PluginManager.plazaInstallActive) {
            installQueueContinueTimer.restart()
            return
        }

        currentInstallingId = installQueue[installIndex]
        currentInstallFinished = false
        if (!installSingle(currentInstallingId)) {
            addFailure(currentInstallingId, qsTr("Unable to start installation"))
            finishCurrentInstallItem()
        }
    }

    onNextRequested: {
        if (failedInstallations.length > 0) {
            tutorial.goNext()
            return
        }

        var ids = selectedPluginIds()
        if (ids.length === 0) {
            tutorial.goNext()
            return
        }
        startInstallQueue(ids)
    }

    onFooterSecondaryRequested: root.startInstallQueue(root.selectedFailedPluginIds())

    Connections {
        target: PluginManager

        function onPluginInstallSucceeded(pluginId, version) {
            if (!root.installingSelection || pluginId !== root.currentInstallingId)
                return
            // Installation is deferred, but tutorial-selected plugins should
            // be enabled for the first load after restart.
            PluginManager.setPluginEnabled(pluginId, true)
            root.addSuccess(pluginId)
        }

        function onPluginInstallFailed(message) {
            if (!root.installingSelection || root.currentInstallingId.length === 0)
                return
            PluginManager.setPluginEnabled(root.currentInstallingId, false)
            root.addFailure(root.currentInstallingId, message)
            installFailureSettleTimer.restart()
        }

        function onPluginInstallCancelled(pluginId) {
            if (!root.installingSelection || (pluginId && pluginId !== root.currentInstallingId))
                return
            PluginManager.setPluginEnabled(pluginId || root.currentInstallingId, false)
            root.addFailure(pluginId || root.currentInstallingId, qsTr("Installation cancelled"))
            installFailureSettleTimer.restart()
        }

        function onPluginInstallSettled() {
            if (!root.installingSelection)
                return
            root.finishCurrentInstallItem()
        }
    }

    ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: 4

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: 6
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.minimumHeight: 40
                spacing: 8

                ColumnLayout {
                    Layout.preferredWidth: 160
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        opacity: root.installingSelection ? 1 : 0
                        text: root.installProgressText()
                        typography: Typography.Caption
                        color: Colors.proxy.textSecondaryColor
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }

                    ProgressBar {
                        Layout.preferredWidth: 160
                        opacity: root.installingSelection ? 1 : 0
                        value: root.installingSelection ? PluginManager.installProgress / 100 : 0
                        indeterminate: root.installProgressIndeterminate()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    flat: true
                    highlighted: true
                    text: qsTr("Select all")
                    enabled: !root.installingSelection
                             && root.selectedPluginIds().length < root.selectablePluginCount()
                    onClicked: root.selectAllPlugins()
                }

                Button {
                    flat: true
                    highlighted: true
                    text: qsTr("Clear selection")
                    enabled: !root.installingSelection && root.selectedPluginIds().length > 0
                    onClicked: root.clearPluginSelection()
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: pluginGrid
                    anchors.fill: parent
                    anchors.rightMargin: 6
                    anchors.bottomMargin: failureCard.visible ? failureCard.height + 4 : 0
                    visible: !root.recommendationsLoading
                             && root.recommendations.length > 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    readonly property int minimumCardWidth: 260
                    readonly property int cardHeight: 82
                    readonly property int cellSpacing: 4
                    readonly property int columns: Math.max(1, Math.floor((width + cellSpacing) /
                                                                           (minimumCardWidth + cellSpacing)))

                    cellWidth: (width - cellSpacing * (columns - 1)) / columns
                    cellHeight: cardHeight + cellSpacing
                    model: root.recommendationsLoading
                           ? []
                           : root.recommendations

                    delegate: TutorialComponents.TutorialPluginCard {
                        width: pluginGrid.cellWidth - pluginGrid.cellSpacing
                        height: pluginGrid.cardHeight
                        x: pluginGrid.cellSpacing / 2
                        y: pluginGrid.cellSpacing / 2
                        plugin: modelData
                        selected: root.isSelected(pluginId)
                        installed: !!modelData.id && root.isInstalled(modelData.id)
                        baseUrl: root.recommendationsBaseUrl
                        installActive: root.installingSelection && root.currentInstallingId === pluginId
                        installStatus: PluginManager.installPluginId === pluginId
                                       ? PluginManager.installStatus
                                       : "Installing"
                        installProgress: PluginManager.installPluginId === pluginId
                                         ? PluginManager.installProgress
                                         : 0
                        installDownloadedBytes: PluginManager.installPluginId === pluginId
                                                ? PluginManager.installDownloadedBytes
                                                : 0
                        installTotalBytes: PluginManager.installPluginId === pluginId
                                           ? PluginManager.installTotalBytes
                                           : 0

                        Component.onCompleted: {
                            if (installed)
                                PluginManager.setPluginEnabled(pluginId, true)
                        }

                        onSelectionToggled: function(checked) {
                            root.setPluginSelected(pluginId, checked)
                        }
                    }
                }

                ProgressRing {
                    anchors.centerIn: parent
                    visible: root.recommendationsLoading
                    indeterminate: true
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, 420)
                    spacing: 4
                    visible: !root.recommendationsLoading
                             && root.recommendations.length === 0

                    PlazaComponents.EmptyState {
                        Layout.fillWidth: true
                        title: root.recommendationsError.length > 0
                               ? qsTr("Could not load recommendations")
                               : qsTr("No recommendations available")
                        description: root.recommendationsError.length > 0
                                     ? root.recommendationsError
                                     : qsTr("You can browse Plugin Plaza after setup.")
                        icon.name: root.recommendationsError.length > 0
                                   ? "ic_fluent_cloud_error_20_regular"
                                   : "ic_fluent_plug_disconnected_20_regular"
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: root.recommendationsError.length > 0
                        text: qsTr("Retry")
                        icon.name: "ic_fluent_arrow_sync_20_regular"
                        onClicked: {
                            if (root.recommendationsBridge)
                                root.recommendationsBridge.fetchRecommendations()
                        }
                    }
                }

                SettingCard {
                    id: failureCard
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 6
                    visible: !root.installingSelection && root.failedInstallations.length > 0
                    icon.name: "ic_fluent_warning_20_regular"
                    title: qsTr("Some plugins were not installed")
                    description: qsTr("%1 installed, %2 failed. Retry the failed plugins or continue without them.")
                                 .arg(root.successfulInstallations.length)
                                 .arg(root.failedInstallations.length)
                }
            }
        }
    }
}
