import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    spacing: 0

    property int secValue: 5
    onSecValueChanged: settings.interval_ms = secValue * 1000

    Component.onCompleted: {
        secValue = (settings.interval_ms || 5000) / 1000
        reloadFrame()
    }

    property var backendObj: null
    property var overlayBackend: {
        if (backendObj) return backendObj
        if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
            var defs = WidgetsModel.definitionsList
            for (var i = 0; i < defs.length; i++) {
                if (defs[i].typeId === "classwidgets.overlay") return defs[i].backendObj || defs[i].backend_obj
                if (defs[i].id === "classwidgets.overlay") return defs[i].backendObj || defs[i].backend_obj
            }
        }
        return null
    }

    property var memberList: overlayBackend ? overlayBackend.getMembers(instanceId) : []

    function nameOf(typeId) {
        if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
            var defs = WidgetsModel.definitionsList
            for (var i = 0; i < defs.length; i++) {
                if (defs[i].id === typeId || defs[i].typeId === typeId)
                    return defs[i].name || typeId
            }
        }
        return typeId
    }

    property int frameW: 0
    property int frameH: 0

    function reloadFrame() {
        if (!overlayBackend) return
        var f = overlayBackend.getFrameSize(instanceId)
        frameW = f ? (f.w || 0) : 0
        frameH = f ? (f.h || 0) : 0
    }

    function stepFrame(dw, dh) {
        if (!overlayBackend) return
        var w = frameW
        if (dw !== 0) {
            w = w > 0 ? w + dw : 400 + (dw > 0 ? dw : 0)
            if (w < 60) w = 60
        }
        var h = frameH
        if (dh !== 0) {
            h = h > 0 ? h + dh : 200 + (dh > 0 ? dh : 0)
            if (h < 40) h = 40
        }
        overlayBackend.setFrameSize(instanceId, w, h)
        reloadFrame()
    }

    function resetFrame() {
        if (!overlayBackend) return
        overlayBackend.setFrameSize(instanceId, 0, 0)
        frameW = 0
        frameH = 0
    }

    SettingExpander {
        Layout.fillWidth: true
        title: qsTr("Carousel interval")
        description: qsTr("Time each member stays visible before switching to the next, in seconds.")
        expanded: true

        SettingItem {
            action: RowLayout {
                Layout.preferredWidth: 260
                spacing: 8

                Button {
                    text: "\u2212"
                    implicitWidth: 36
                    onClicked: secValue = Math.max(1, secValue - 1)
                }
                Text {
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignHCenter
                    text: secValue + " " + qsTr("s")
                    font.bold: true
                }
                Button {
                    text: "+"
                    implicitWidth: 36
                    onClicked: secValue = Math.min(60, secValue + 1)
                }
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: qsTr("Frame size mode")
        description: qsTr("Largest member keeps the frame at the size of the biggest member; Follow current resizes the frame smoothly to the visible member.")
        expanded: true

        SettingItem {
            action: ComboBox {
                Layout.preferredWidth: 240
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: qsTr("Largest member"), value: "max" },
                    { text: qsTr("Follow current"), value: "auto" }
                ]
                Component.onCompleted: {
                    var v = settings.frame_mode || "max"
                    var i = indexOfValue(v)
                    currentIndex = i >= 0 ? i : 0
                }
                onActivated: settings.frame_mode = currentValue
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: qsTr("Frame size")
        description: qsTr("Custom width and height for this stacked widget. Auto follows the content.")
        expanded: true

        SettingItem {
            action: ColumnLayout {
                spacing: 8
                Text {
                    text: (frameW > 0 && frameH > 0) ? frameW + " \u00d7 " + frameH
                          : (frameW > 0) ? frameW + " \u00d7 " + qsTr("Auto")
                          : (frameH > 0) ? qsTr("Auto") + " \u00d7 " + frameH
                          : qsTr("Auto")
                    font.bold: true
                }
                RowLayout {
                    spacing: 6
                    Button { text: qsTr("W\u2212"); onClicked: stepFrame(-10, 0) }
                    Button { text: qsTr("W+"); onClicked: stepFrame(10, 0) }
                    Button { text: qsTr("H\u2212"); onClicked: stepFrame(0, -10) }
                    Button { text: qsTr("H+"); onClicked: stepFrame(0, 10) }
                    Button { text: qsTr("Auto"); onClicked: resetFrame() }
                }
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: qsTr("Show switch bar")
        description: qsTr("Show a switch button on the right edge of the widget to step through members manually.")
        expanded: true

        SettingItem {
            action: Switch {
                primaryColor: Colors.proxy.controlStrongColor
                checked: settings.show_switch_bar !== false
                onCheckedChanged: settings.show_switch_bar = checked
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: qsTr("Members")
        description: qsTr("Members stacked inside this widget. Add or remove them from the desktop widget context menu.")
        expanded: true

        SettingItem {
            action: ColumnLayout {
                spacing: 4

                Text {
                    visible: memberList.length === 0
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 0.6
                    wrapMode: Text.Wrap
                    text: qsTr("No members yet")
                }

                Repeater {
                    model: memberList
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: (index + 1) + ". " + nameOf(modelData.typeId)
                            elide: Text.ElideMiddle
                        }
                        Button {
                            text: qsTr("Remove")
                            implicitWidth: 72
                            implicitHeight: 26
                            onClicked: {
                                if (overlayBackend) {
                                    overlayBackend.removeMember(instanceId, modelData.key)
                                    memberList = overlayBackend.getMembers(instanceId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
