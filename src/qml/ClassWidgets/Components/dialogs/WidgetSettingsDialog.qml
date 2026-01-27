import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


Dialog {
    id: settingsDialog
    title: qsTr("Widget Settings")
    modal: true
    width: Screen.width * 0.3
    height: Screen.height * 0.45
    standardButtons: Dialog.Ok | Dialog.Cancel

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

    // 保存设置
    onAccepted: {
        if (settingsLoader.item && settingsLoader.item.settings && settingsLoader.item.instanceId) {
            WidgetsModel.updateSettings(settingsLoader.item.instanceId, settingsLoader.item.settings)
        }
    }

    function setSource(source, params) {
        settingsLoader.setSource(source, params)
    }
}