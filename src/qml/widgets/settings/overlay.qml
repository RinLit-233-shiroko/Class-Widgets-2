import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
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
    property int frameW: 0
    property int frameH: 0

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

    function syncFrameSize() {
        if (!overlayBackend) return
        overlayBackend.setFrameSize(instanceId, frameW, frameH)
        var f = overlayBackend.getFrameSize(instanceId)
        frameW = f ? (f.w || 0) : 0
        frameH = f ? (f.h || 0) : 0
    }

    function removeMember(key) {
        if (!overlayBackend) return
        overlayBackend.removeMember(instanceId, key)
        memberList = overlayBackend.getMembers(instanceId)
    }

    Component.onCompleted: {
        if (overlayBackend) {
            var f = overlayBackend.getFrameSize(instanceId)
            frameW = f ? (f.w || 0) : 0
            frameH = f ? (f.h || 0) : 0
        }
        widthSpinBox.value = Math.max(widthSpinBox.from, Math.min(widthSpinBox.to, frameW))
        heightSpinBox.value = Math.max(heightSpinBox.from, Math.min(heightSpinBox.to, frameH))
        widthSpinBox.initialized = true
        heightSpinBox.initialized = true
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_timer_20_regular"
        title: qsTr("Carousel interval")
        description: qsTr("Time each member stays visible before switching to the next, in seconds.")

        SpinBox {
            id: intervalSpinBox
            property bool initialized: false
            from: 1
            to: 60
            editable: true

            Component.onCompleted: {
                var value = Number(settings.interval_ms) / 1000
                intervalSpinBox.value = isNaN(value) || value <= 0
                        ? 5 : Math.max(from, Math.min(to, Math.round(value)))
                initialized = true
            }
            onValueChanged: {
                if (initialized) settings.interval_ms = value * 1000
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_text_align_center_20_regular"
        title: qsTr("Frame size mode")
        description: qsTr("Largest member keeps the frame at the size of the biggest member; Follow current resizes the frame smoothly to the visible member.")

        ComboBox {
            id: frameModeComboBox
            property bool initialized: false
            property var modes: ["max", "auto"]

            model: ListModel {
                ListElement { text: qsTr("Largest member") }
                ListElement { text: qsTr("Follow current") }
            }
            textRole: "text"

            Component.onCompleted: {
                var index = modes.indexOf(settings.frame_mode)
                currentIndex = index >= 0 ? index : 0
                initialized = true
            }
            onCurrentIndexChanged: {
                if (initialized && currentIndex >= 0)
                    settings.frame_mode = modes[currentIndex]
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_resize_20_regular"
        title: qsTr("Frame size")
        description: qsTr("Custom width and height for this stacked widget. Auto follows the content.")

        enabled: frameModeComboBox.currentIndex === 0

        RowLayout {
            spacing: 16

            ColumnLayout {
                spacing: 2
                SpinBox {
                    id: widthSpinBox
                    property bool initialized: false
                    from: 0
                    to: 2000
                    stepSize: 10
                    editable: true

                    onValueChanged: {
                        if (!initialized) return
                        frameW = value
                        syncFrameSize()
                        if (widthSpinBox.value !== frameW)
                            widthSpinBox.value = frameW
                    }
                }
                Text {
                    text: qsTr("Width")
                    typography: Typography.Caption
                }
            }

            ColumnLayout {
                spacing: 2
                SpinBox {
                    id: heightSpinBox
                    property bool initialized: false
                    from: 0
                    to: 2000
                    stepSize: 10
                    editable: true

                    onValueChanged: {
                        if (!initialized) return
                        frameH = value
                        syncFrameSize()
                        if (heightSpinBox.value !== frameH)
                            heightSpinBox.value = frameH
                    }
                }
                Text {
                    text: qsTr("Height")
                    typography: Typography.Caption
                }
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_arrow_sync_20_regular"
        title: qsTr("Show switch bar")
        description: qsTr("Show a switch button on the right edge of the widget to step through members manually.")

        Switch {
            id: switchBarSwitch
            onCheckedChanged: settings.show_switch_bar = switchBarSwitch.checked
            Component.onCompleted: switchBarSwitch.checked = settings.show_switch_bar !== false
        }
    }

    SettingCard {
        Layout.fillWidth: true

        icon.name: "ic_fluent_stack_20_regular"
        title: qsTr("Members")
        description: memberList.length === 0
                     ? qsTr("No members yet")
                     : qsTr("Members stacked inside this widget. Add or remove them from the desktop widget context menu.")

        Flickable {
            Layout.preferredWidth: 220
            Layout.preferredHeight: 32
            contentWidth: memberRow.width
            contentHeight: 32
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick

            RowLayout {
                id: memberRow
                spacing: 6
                height: 32

                Repeater {
                    model: memberList
                    delegate: PillButton {
                        Layout.alignment: Qt.AlignVCenter
                        text: nameOf(modelData.typeId) + "  \u2715"
                        implicitHeight: 28
                        onClicked: removeMember(modelData.key)
                    }
                }
            }
        }
    }
}
