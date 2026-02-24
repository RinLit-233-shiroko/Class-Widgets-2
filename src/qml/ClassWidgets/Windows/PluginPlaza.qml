import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentWindow {
    id: plazaWindow
    icon: PathManager.assets("images/icons/cw2_settings.png")
    title: qsTr("Plugin Plaza")
    width: Screen.width * 0.7
    height: Screen.height * 0.8
    minimumWidth: 900

    onClosing: function(event) {
        event.accepted = false
        plazaWindow.visible = false
    }

    titleBarArea: RowLayout {
        anchors.fill: parent
        spacing: 24

        Item { Layout.fillWidth: true }

        ToolButton {
            flat: true
            Layout.alignment: Qt.AlignRight
            icon.name: "ic_fluent_refresh_20_regular"
            size: 18

            ToolTip {
                text: qsTr("Refresh")
                visible: parent.hovered
            }

            onClicked: {
                PlazaBridge.refreshAll()
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
        }
    ]



    Watermark {
        anchors.centerIn: parent
    }
}
