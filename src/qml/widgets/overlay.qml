import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Window
import RinUI
import ClassWidgets.Theme 1.0

Item {
    id: root

    property var backend: null
    property var settings: null
    property bool editMode: false
    property bool overlayListMode: false
    property string instanceId: ""

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
    readonly property int autoW: Math.max(96,
        (root.frameMode === "auto" ? root.activeSize().w : root.maxW) + root.switchBarSpace)
    readonly property int autoH: Math.max(80,
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

    property int frameW: 0
    property int frameH: 0

    property int switchBarSpace: root.showSwitchBar && root.members.length > 0 ? 48 : 0

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

    implicitWidth: root.gateHide ? 0 : (root.frameW > 0 ? root.frameW : root.autoW)
    implicitHeight: root.gateHide
        ? 0
        : (root.overlayListMode
            ? Math.max(80, root.listTotalH())
            : (root.miniMode ? 56 : (root.frameH > 0 ? root.frameH : root.autoH)))
    Behavior on implicitWidth {
        enabled: !root.overlayListMode && !root.gateHide && root.frameW === 0
            && root.frameMode === "auto"
        NumberAnimation { duration: 320; easing.type: Easing.InOutCubic }
    }
    Behavior on implicitHeight {
        enabled: !root.overlayListMode && !root.gateHide && root.frameH === 0
            && root.frameMode === "auto"
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
        function onFrameChanged() { root.reloadFrame() }
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
        root.reloadFrame()
    }

    function reloadFrame() {
        if (!backend) return
        var f = backend.getFrameSize(root.instanceId)
        root.frameW = f ? (f.w || 0) : 0
        root.frameH = f ? (f.h || 0) : 0
    }

    function stepFrame(dw, dh) {
        if (!backend) return
        var w = root.frameW
        if (dw !== 0) {
            w = w > 0 ? w + dw : root.autoW + (dw > 0 ? dw : 0)
            if (w < 60) w = 60
        }
        var h = root.frameH
        if (dh !== 0) {
            h = h > 0 ? h + dh : root.autoH + (dh > 0 ? dh : 0)
            if (h < 40) h = 40
        }
        backend.setFrameSize(root.instanceId, w, h)
        root.reloadFrame()
    }

    function resetFrame() {
        if (!backend) return
        backend.setFrameSize(root.instanceId, 0, 0)
        root.frameW = 0
        root.frameH = 0
    }

    function listY(i) {
        return i * (root.maxH + root.listSpacing)
    }

    function listTotalH() {
        var n = root.members.length
        if (n <= 0) return 0
        return n * root.maxH + root.listSpacing * (n - 1)
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

    function openOverlayEditor() {
        root.refresh()
        overlayEditDialog.open()
    }

    function openMemberSettings(i) {
        var m = root.members[i]
        if (!m) return
        var typeId = m.typeId
        var key = m.key
        var d = root.findDef(typeId)
        if (!d || !root.backend) return
        var sq = d.settingsQml || d.settings_qml || ""
        console.log("[overlay] openMemberSettings:", key, "settingsQml:", sq)
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

    Column {
        anchors.centerIn: parent
        visible: root.members.length === 0
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Stacked widget")
            color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Right-click to add members")
            color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(0, 0, 0, 0.5)
            font.pixelSize: 12
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
                }
                root.reportContent(memberId, root.backendHasContent(item))
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
        readonly property bool barVisible: root.showSwitchBar && root.members.length > 0
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

        Text {
            anchors.centerIn: parent
            text: qsTr("Next")
            color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(0, 0, 0, 0.75)
            font.pixelSize: 13
            font.weight: Font.DemiBold
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
            anchors.fill: parent
            anchors.margins: 16
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

    Dialog {
        id: overlayEditDialog
        title: qsTr("Edit stacked widget")
        modal: true
        standardButtons: Dialog.Close
        width: 620
        height: 520

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                Layout.fillWidth: true
                visible: root.members.length === 0
                text: qsTr("No members yet. Use Add member below to include widgets.")
                color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(0, 0, 0, 0.55)
                font.pixelSize: 13
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: memberListColumn.height

                Column {
                    id: memberListColumn
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: root.members
                        delegate: RowLayout {
                            width: memberListColumn.width
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: root.nameOf(modelData.typeId)
                                elide: Text.ElideRight
                                font.pixelSize: 13
                                color: Theme.isDark() ? "#eee" : "#222"
                            }
                            Button {
                                text: qsTr("Settings")
                                onClicked: root.openMemberSettings(index)
                            }
                            Button {
                                text: qsTr("Remove")
                                onClicked: root.removeMemberByKey(modelData.key)
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: {
                        var w = root.frameW
                        var h = root.frameH
                        if (w > 0 && h > 0) return w + "×" + h
                        if (w > 0) return w + " \u00d7 " + qsTr("Auto")
                        if (h > 0) return qsTr("Auto") + " \u00d7 " + h
                        return qsTr("Auto")
                    }
                    font.pixelSize: 13
                    color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.6)
                }
                Button { text: qsTr("W\u2212"); onClicked: root.stepFrame(-10, 0) }
                Button { text: qsTr("W+"); onClicked: root.stepFrame(10, 0) }
                Button { text: qsTr("H\u2212"); onClicked: root.stepFrame(0, -10) }
                Button { text: qsTr("H+"); onClicked: root.stepFrame(0, 10) }
                Button { text: qsTr("Auto"); onClicked: root.resetFrame() }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 8

                Button {
                    text: qsTr("Add member")
                    highlighted: true
                    onClicked: addMemberDialog.open()
                }
                Button {
                    text: qsTr("Done")
                    onClicked: overlayEditDialog.close()
                }
            }
        }
    }

    Dialog {
        id: addMemberDialog
        title: qsTr("Add member widget")
        modal: true
        standardButtons: Dialog.Close
        width: 560
        height: 480

        property var candidates: {
            var list = []
            if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
                var raw = WidgetsModel.definitionsList
                for (var i = 0; i < raw.length; i++) {
                    if (raw[i].id === "classwidgets.overlay") continue
                    list.push(raw[i])
                }
            }
            return list
        }
        property var selected: widgetsListView.currentIndex >= 0
            ? widgetsListView.model[widgetsListView.currentIndex] : null

        onOpened: {
            widgetsListView.currentIndex = -1
            widgetsListView.currentIndex = 0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            ListView {
                id: widgetsListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: addMemberDialog.candidates
                clip: true

                delegate: ItemDelegate {
                    width: widgetsListView.width
                    text: modelData.name || modelData.id
                    highlighted: index === widgetsListView.currentIndex
                    onClicked: widgetsListView.currentIndex = index
                }
            }

            Button {
                Layout.alignment: Qt.AlignRight
                text: qsTr("Add")
                highlighted: true
                enabled: addMemberDialog.selected !== null
                onClicked: {
                    if (root.backend && addMemberDialog.selected) {
                        root.backend.addMember(root.instanceId, addMemberDialog.selected.id)
                    }
                    addMemberDialog.close()
                }
            }
        }
    }
}
