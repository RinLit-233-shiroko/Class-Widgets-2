import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


ColumnLayout {
    spacing: 12

    Text {
        typography: Typography.BodyStrong
        text: qsTr("Customize")
    }

    SettingCard {
        Layout.fillWidth: true
        title: qsTr("App Theme")
        description: qsTr("Select which app theme to display")
        icon.name: "ic_fluent_paint_brush_20_regular"

        ComboBox {
            property var data: [Theme.mode.Light, Theme.mode.Dark, Theme.mode.Auto]
            model: ListModel {
                ListElement { text: qsTr("Light") }
                ListElement { text: qsTr("Dark") }
                ListElement { text: qsTr("Use system setting") }
            }
            currentIndex: data.indexOf(Theme.getTheme())
            onCurrentIndexChanged: Theme.setTheme(data[currentIndex])
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_layer_20_regular"
        title: qsTr("Window Layer")
        description: qsTr("Let your widgets float on top, or tuck them behind other windows")

        ComboBox {
            model: ListModel {
                ListElement { text: qsTr("Pin on Top"); value: "top" }
                ListElement { text: qsTr("Send to Back"); value: "bottom" }
            }
            textRole: "text"
            onCurrentIndexChanged: if (focus) Configs.set("preferences.widgets_layer", model.get(currentIndex).value)
            Component.onCompleted: {
                for (var i = 0; i < model.count; i++) {
                    if (model.get(i).value === Configs.data.preferences.widgets_layer) {
                        currentIndex = i
                        break
                    }
                }
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        title: qsTr("Mini Mode")
        description: qsTr("Use a more compact layout for smaller widgets")
        icon.name: "ic_fluent_resize_20_regular"

        Switch {
            onCheckedChanged: Configs.set("preferences.mini_mode", checked)
            Component.onCompleted: checked = Configs.data.preferences.mini_mode
        }
    }

    Text {
        typography: Typography.BodyStrong
        text: qsTr("Actions")
    }

    SettingCard {
        Layout.fillWidth: true
        title: qsTr("Run at Startup")
        description: qsTr("Run Class Widgets on startup")
        icon.name: "ic_fluent_open_20_regular"

        Switch {
            onCheckedChanged: {
                Configs.set("app.auto_startup", checked)
                UtilsBackend.setAutostart(checked)
            }
            enabled: UtilsBackend.autostartSupported()
            Component.onCompleted: {
                if (!UtilsBackend.autostartEnabled()) {
                    checked = false
                    Configs.set("app.auto_startup", checked)
                    return
                }
                checked = Configs.data.app.auto_startup
            }
        }
    }
}