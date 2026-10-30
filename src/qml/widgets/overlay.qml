import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import RinUI
import ClassWidgets.Components
import ClassWidgets.Theme 1.0

Item {
    id: root
    clip: true

    property var backend: null
    property var settings: null
    property bool editMode: false
    property bool overlayListMode: false
    property string instanceId: ""

    signal addMemberRequested()
    signal doneRequested()

    onBackendChanged: {
        if (backend) Qt.callLater(function() { root.refresh() })
    }

    onInstanceIdChanged: {
        if (backend) Qt.callLater(function() { root.refresh() })
    }

    property bool classHideEnabled: backend && backend.classHideEnabled
    property string classHideDays: backend ? backend.classHideDays : ""
    property string classHideStart: backend ? backend.classHideStart : ""
    property string classHideEnd: backend ? backend.classHideEnd : ""
    property bool classHideInClass: false
    property bool scheduleInClass: typeof AppCentral !== "undefined"
        && AppCentral.scheduleRuntime && AppCentral.scheduleRuntime.currentStatus === "class"
    property bool notificationInClass: false
    property bool inClass: root.scheduleInClass || root.notificationInClass || root.classHideInClass

    function containsClassStart(txt) {
        return txt.indexOf(qsTr("Class starts")) >= 0 || txt.indexOf(qsTr("Class begins")) >= 0
    }

    function containsClassEnd(txt) {
        return txt.indexOf(qsTr("Class over")) >= 0 || txt.indexOf(qsTr("Class ends")) >= 0
            || txt.indexOf(qsTr("Class dismissed")) >= 0 || txt.indexOf(qsTr("Class finished")) >= 0
            || txt.indexOf(qsTr("End of class")) >= 0 || txt.indexOf(qsTr("Break")) >= 0
    }

    Connections {
        target: typeof AppCentral !== "undefined" && AppCentral.notification ? AppCentral.notification : null
        function onNotified(payload) {
            if (!payload) return
            var txt = String(payload.title || "") + " " + String(payload.message || "")
            if (root.containsClassStart(txt)) {
                root.notificationInClass = true
                notifRecoverTimer.restart()
            } else if (root.containsClassEnd(txt)) {
                root.notificationInClass = false
                notifRecoverTimer.stop()
            }
        }
    }

    Timer {
        id: notifRecoverTimer
        interval: 90 * 60 * 1000
        repeat: false
        onTriggered: root.notificationInClass = false
    }

    function parseTimeStr(t) {
        var m = /^(\d{1,2}):(\d{2})$/.exec(String(t || "").trim())
        if (!m) return -1
        return parseInt(m[1], 10) * 60 + parseInt(m[2], 10)
    }

    function computeInClass() {
        if (!root.classHideEnabled) return false
        var now = new Date()
        var wd = now.getDay()
        var day = wd === 0 ? 7 : wd
        if (root.classHideDays.indexOf(String(day)) < 0) return false
        var s = root.parseTimeStr(root.classHideStart)
        var e = root.parseTimeStr(root.classHideEnd)
        if (s < 0 || e < 0 || s >= e) return false
        var cur = now.getHours() * 60 + now.getMinutes()
        return cur >= s && cur < e
    }

    function updateClassState() { root.classHideInClass = root.computeInClass() }

    onClassHideEnabledChanged: root.updateClassState()
    onClassHideDaysChanged: root.updateClassState()
    onClassHideStartChanged: root.updateClassState()
    onClassHideEndChanged: root.updateClassState()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.updateClassState()
    }

    Connections {
        target: backend
        function onClassHideChanged() {
            root.updateClassState()
        }
    }

    property var members: []
    property int activeIndex: 0
    property var defs: WidgetsModel ? WidgetsModel.definitionsList : []
    property var sizeMap: ({})
    property int listSpacing: 10
    readonly property int maxW: root.maxSize().w
    readonly property int maxH: root.maxSize().h
    property string frameMode: (settings && settings.frame_mode) ? settings.frame_mode : "max"
    readonly property bool emptyState: root.members.length === 0
    readonly property int autoW: Math.max(root.overlayListMode ? 260 : (root.emptyState ? 200 : 96),
        (root.frameMode === "auto" ? root.activeSize().w : root.maxW) + root.switchBarSpace)
    readonly property int autoH: Math.max(root.emptyState ? 100 : 80,
        root.frameMode === "auto" ? root.activeSize().h : root.maxH)

    function maxSize() {
        var w = 0, h = 0
        for (var k in root.sizeMap) {
            w = Math.max(w, root.sizeMap[k].w)
            h = Math.max(h, root.sizeMap[k].h)
        }
        return { w: w, h: h }
    }

    function activeSize() {
        var m = root.members[root.activeIndex]
        var s = m ? root.sizeMap[m.key] : null
        return s ? s : { w: 96, h: 80 }
    }

    function reportSize(key, w, h) {
        var old = root.sizeMap[key]
        if (old && old.w === w && old.h === h) return
        var m = {}
        for (var k in root.sizeMap) m[k] = root.sizeMap[k]
        m[key] = { w: Math.max(0, w), h: Math.max(0, h) }
        root.sizeMap = m
    }

    property int switchBarSpace: root.showSwitchBar && root.members.length > 1 ? 48 : 0

    readonly property bool lyricGateActive: false
    property var contentMap: ({})

    function isGatedMember(typeId) {
        return typeId === "com.lyricsisland"
            || typeId === "com.seiraiharaguchi.mediawidgets"
    }

    function memberHasContent(key, typeId) {
        if (!root.isGatedMember(typeId)) return true
        var v = root.contentMap[key]
        return v === undefined ? true : v
    }

    function memberRotatable(m) {
        if (!root.lyricGateActive || !m) return true
        return root.memberHasContent(m.key, m.typeId)
    }

    function reportContent(key, val) {
        if (root.contentMap[key] === val) return
        var m = root.contentMap
        m[key] = val
        root.contentMap = m
    }

    function backendHasContent(item) {
        if (!item || !item.backend) return true
        var b = item.backend
        try {
            if (b.lyricStatus !== undefined) return String(b.lyricStatus) === "ok"
            if (b.hasLyrics !== undefined) return !!b.hasLyrics
            if (b.isPlaying !== undefined) return !!b.isPlaying
            if (b.hasMedia !== undefined) return !!b.hasMedia
            if (b.playing !== undefined) return !!b.playing
        } catch (e) {}
        return true
    }

    readonly property bool gateHide: {
        if (!root.lyricGateActive || root.members.length === 0) return false
        for (var i = 0; i < root.members.length; i++) {
            if (root.memberRotatable(root.members[i])) return false
        }
        return true
    }

    function pollContent() {
        for (var k = 0; k < memberRepeater.count; k++) {
            var obj = memberRepeater.itemAt(k)
            if (obj && obj.item) root.reportContent(obj.memberId, root.backendHasContent(obj.item))
        }
    }

    readonly property bool miniMode: Configs.data.preferences.mini_mode

    implicitWidth: root.gateHide ? 0 : root.autoW
    implicitHeight: root.gateHide
        ? 0
        : (root.overlayListMode ? Math.max(80, root.listTotalH())
                                : (root.miniMode ? 56 : root.autoH))
    width: implicitWidth
    height: implicitHeight
    Behavior on implicitWidth {
        enabled: !root.gateHide
        NumberAnimation { duration: 320; easing.type: Easing.InOutCubic }
    }
    Behavior on implicitHeight {
        enabled: !root.gateHide
        NumberAnimation { duration: 320; easing.type: Easing.InOutCubic }
    }
    visible: root.overlayListMode || !root.gateHide

    property int carouselInterval: settings && settings.interval_ms ? settings.interval_ms : 5000

    property bool showSwitchBar: settings && settings.show_switch_bar !== false

    Timer {
        id: carouselTimer
        interval: root.carouselInterval
        repeat: true
        running: root.members.length > 1 && !root.editMode && !root.overlayListMode
            && !Configs.data.interactions.hide.state
        onTriggered: {
            var n = root.members.length
            if (n === 0) return
            var i = root.activeIndex
            for (var k = 0; k < n; k++) {
                i = (i + 1) % n
                if (root.memberRotatable(root.members[i])) {
                    root.activeIndex = i
                    return
                }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.lyricGateActive
        onTriggered: root.pollContent()
    }

    Connections {
        target: backend
        function onMembersChanged() { root.refresh() }
    }

    function findDef(widgetId) {
        for (var i = 0; i < root.defs.length; i++) {
            if (root.defs[i].id === widgetId) return root.defs[i]
        }
        return null
    }

    function refresh() {
        if (!backend) return
        var list = backend.getMembers(root.instanceId)
        root.members = list
        if (root.activeIndex >= list.length) root.activeIndex = 0
    }

    readonly property bool listPlaceholderVisible: root.overlayListMode
    readonly property int listPlaceholderHeight: root.maxH > 0 ? root.maxH : (root.miniMode ? 56 : 100)

    function listHeaderHeight() {
        return root.listPlaceholderVisible ? root.listPlaceholderHeight + root.listSpacing : 0
    }

    readonly property int listActionHeight: 44

    function listY(i) {
        return root.listHeaderHeight() + i * (root.maxH + root.listSpacing)
    }

    function listActionY() {
        var n = root.members.length
        if (n <= 0) return root.listHeaderHeight()
        return root.listHeaderHeight() + n * root.maxH + (n - 1) * root.listSpacing + root.listSpacing
    }

    function listTotalH() {
        var n = root.members.length
        var h = root.listHeaderHeight()
        if (n > 0) h += n * root.maxH + (n - 1) * root.listSpacing
        return h + root.listSpacing + root.listActionHeight
    }

    function mergedMemberSettings(key, typeId) {
        var d = root.findDef(typeId)
        var defaults0 = d ? (d.default_settings || {}) : {}
        var saved0 = (root.backend && root.backend.getMemberSettings)
            ? (root.backend.getMemberSettings(root.instanceId, key) || {})
            : {}
        var merged = {}
        for (var k in defaults0) merged[k] = defaults0[k]
        for (var k2 in saved0) merged[k2] = saved0[k2]
        return merged
    }

    function nextMember() {
        if (root.members.length > 1) {
            root.activeIndex = (root.activeIndex + 1) % root.members.length
            if (carouselTimer.running) carouselTimer.restart()
        }
    }

    function nameOf(typeId) {
        var d = root.findDef(typeId)
        return d ? (d.name || typeId) : typeId
    }

    function removeMemberByKey(k) {
        if (root.backend) root.backend.removeMember(root.instanceId, k)
    }

    function openMemberSettings(i) {
        var m = root.members[i]
        if (!m) return
        var typeId = m.typeId
        var key = m.key
        var d = root.findDef(typeId)
        if (!d || !root.backend) return
        var sq = d.settingsQml || d.settings_qml || ""
        if (!sq) return
        var merged = root.mergedMemberSettings(key, typeId)
        memberSettingsDialog.currentMemberId = key
        memberSettingsDialog.currentMemberTypeId = typeId
        settingsLoader.setSource(sq, {
            "settings": merged,
            "instanceId": ""
        })
        memberSettingsDialog.open()
    }

    function applyMemberSettings(key, typeId) {
        var merged = root.mergedMemberSettings(key, typeId)
        for (var k = 0; k < memberRepeater.count; k++) {
            var obj = memberRepeater.itemAt(k)
            if (obj && obj.memberId === key && obj.item
                    && obj.item.settings !== undefined) {
                obj.item.settings = merged
            }
        }
    }

    Component.onCompleted: {
        if (backend) refresh()
        root.updateClassState()
    }

    Rectangle {
        id: emptyStateBox
        anchors.fill: parent
        anchors.margins: 4
        visible: root.members.length === 0 && !root.overlayListMode
        radius: Math.min(width, height, Configs.data.preferences.widget_corner_radius)
        color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
        border.width: 1
        border.color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)

        EmptyState {
            anchors.fill: parent
            anchors.margins: 6
            icon.size: 20
            title: qsTr("Stacked widget")
            description: qsTr("Right-click to add members")
        }
    }

    Rectangle {
        id: listPlaceholder
        visible: root.listPlaceholderVisible
        x: 4
        y: 4
        width: Math.max(0, root.width - 8)
        height: root.listPlaceholderHeight
        radius: Math.min(width, height, Configs.data.preferences.widget_corner_radius)
        color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.04)
        border.width: 1
        border.color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.12)

        EmptyState {
            anchors.fill: parent
            anchors.margins: 6
            icon.size: 20
            title: qsTr("Stacked widget")
            description: qsTr("This is the stacked widget itself. Deleting it removes the whole widget.")
        }
    }

    RowLayout {
        id: listActions
        visible: root.overlayListMode
        z: 2
        x: (root.width - width) / 2
        y: root.listActionY()
        height: root.listActionHeight
        spacing: 8

        Button {
            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("Add Member")
            onClicked: root.addMemberRequested()
        }
        Button {
            highlighted: true
            icon.name: "ic_fluent_checkmark_20_regular"
            text: qsTr("Done")
            onClicked: root.doneRequested()
        }
    }

    Repeater {
        id: memberRepeater
        anchors.fill: parent
        model: root.members

        Loader {
            id: memberLoader
            asynchronous: true
            z: index === root.activeIndex ? 1 : 0
            x: root.overlayListMode
                ? 0
                : (Math.max(0, parent.width - root.switchBarSpace - width)) / 2
            y: root.overlayListMode ? root.listY(index) : (parent.height - height) / 2
            opacity: root.overlayListMode
                ? 1
                : (index === root.activeIndex ? 1 : 0)
            scale: root.overlayListMode
                ? 1
                : (index === root.activeIndex ? 1 : 0.96)

            Behavior on opacity {
                NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
            }
            Behavior on scale {
                NumberAnimation { duration: 320; easing.type: Easing.InOutCubic }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                enabled: root.overlayListMode
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) root.openMemberSettings(index)
                }
            }

            ToolButton {
                visible: root.overlayListMode
                icon.name: "ic_fluent_line_horizontal_1_20_filled"
                size: 12
                width: 24
                height: 24
                anchors.top: parent.top
                anchors.left: parent.left
                onClicked: {
                    if (root.backend) root.backend.removeMember(root.instanceId, memberId)
                }
            }

            property string memberId: modelData.key
            property string memberTypeId: modelData.typeId
            source: {
                var d = root.findDef(memberTypeId)
                return d && d.qml_path ? d.qml_path : ""
            }

            onLoaded: {
                var d = root.findDef(memberTypeId)
                if (d) {
                    if (d.backend_obj && item) item.backend = d.backend_obj
                    if (item) {
                        if (item.hasOwnProperty("animateSize")) item.animateSize = false
                        item.settings = root.mergedMemberSettings(memberId, memberTypeId)
                    }
                }
                if (item) {
                    root.reportSize(memberId, item.implicitWidth, item.height)
                    Qt.callLater(function() {
                        if (memberLoader.item)
                            root.reportSize(memberId, memberLoader.item.implicitWidth,
                                            memberLoader.item.height)
                    })
                }
                root.reportContent(memberId, root.backendHasContent(item))
            }

            Connections {
                target: memberLoader.item
                ignoreUnknownSignals: true
                function onImplicitWidthChanged() {
                    if (memberLoader.item)
                        root.reportSize(memberLoader.memberId, memberLoader.item.implicitWidth,
                                        memberLoader.item.height)
                }
            }

            onHeightChanged: {
                if (!item) return
                Qt.callLater(function() {
                    var m = {}
                    for (var k = 0; k < memberRepeater.count; k++) {
                        var obj = memberRepeater.itemAt(k)
                        if (obj && obj.item) {
                            m[obj.memberId] = { w: obj.item.implicitWidth, h: obj.item.height }
                        }
                    }
                    root.sizeMap = m
                })
            }

            onStatusChanged: {
                if (status === Loader.Error && source !== "") {
                    console.error("[overlay] Failed to load member widget:", memberId, source)
                }
            }
        }
    }

    Rectangle {
        id: switchBar
        objectName: "switchBar"
        readonly property bool barVisible: root.showSwitchBar && root.members.length > 1
            && !root.overlayListMode
            && !Configs.data.interactions.hide.state && !root.inClass
        visible: opacity > 0.01
        opacity: barVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
        z: 5
        width: 36
        height: Math.min(120, Math.max(40, root.height))
        radius: Math.min(width, height, Configs.data.preferences.widget_corner_radius)
        x: root.width - 48
        y: (root.height - height) / 2
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: switchBar.radius
            color: Theme.isDark() ? Qt.alpha("#1E1D22", 0.65) : Qt.alpha("#FBFAFF", 0.7)
            opacity: Configs.data.preferences.opacity
            border.color: Theme.isDark() ? Qt.alpha("#ffffff", 0.4) : Qt.alpha("#ffffff", 1)
            border.width: 1
        }

        Icon {
            anchors.centerIn: parent
            name: "ic_fluent_chevron_right_20_regular"
            size: 16
            bold: true
            color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(0, 0, 0, 0.75)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            enabled: switchBar.barVisible
            onClicked: root.nextMember()
        }
    }

    Dialog {
        id: memberSettingsDialog
        objectName: "memberSettingsDialog"
        title: qsTr("Member Settings")
        modal: true
        width: Math.min(520, Screen.width * 0.6)
        height: 420
        property string currentMemberId: ""
        property string currentMemberTypeId: ""

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: settingsLoader.height
                clip: true

                Loader {
                    id: settingsLoader
                    width: parent.width
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                Rectangle {
                    width: 76
                    height: 32
                    radius: 8
                    color: cancelHovered
                        ? Qt.rgba(255, 255, 255, 0.12)
                        : "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.2)
                    border.width: 1
                    property bool cancelHovered: false

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Cancel")
                        font.pixelSize: 13
                        color: Theme.isDark() ? "#ddd" : "#333"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.cancelHovered = true
                        onExited: parent.cancelHovered = false
                        onClicked: memberSettingsDialog.close()
                    }
                }

                Rectangle {
                    width: 76
                    height: 32
                    radius: 8
                    color: saveHovered
                        ? Qt.rgba(0, 120, 212, 0.9)
                        : "#0078D4"
                    property bool saveHovered: false

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("Save")
                        font.pixelSize: 13
                        color: "#fff"
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.saveHovered = true
                        onExited: parent.saveHovered = false
                        onClicked: {
                            if (settingsLoader.item && settingsLoader.item.settings
                                    && root.backend) {
                                root.backend.saveMemberSettings(
                                    root.instanceId,
                                    memberSettingsDialog.currentMemberId,
                                    settingsLoader.item.settings)
                                root.applyMemberSettings(
                                    memberSettingsDialog.currentMemberId,
                                    memberSettingsDialog.currentMemberTypeId)
                            }
                            memberSettingsDialog.close()
                        }
                    }
                }
            }
        }
    }
}
