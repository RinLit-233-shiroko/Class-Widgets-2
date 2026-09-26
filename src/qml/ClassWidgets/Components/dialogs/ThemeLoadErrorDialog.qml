import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import QtQuick.Window as QQW

QQW.Window {
    id: themeLoadErrorDialogWindow
    visible: true
    width: screen.width
    height: screen.height
    color: "transparent"
    flags: Qt.WindowStaysOnTopHint
           | Qt.FramelessWindowHint
           | Qt.WA_TranslucentBackground

    property string failedThemeId: ""
    property bool recovered: true

    Connections {
        target: ThemeLoadErrorDialog
        function onFailedThemeIdChanged(value) {
            themeLoadErrorDialogWindow.failedThemeId = value
        }
        function onRecoveredChanged(value) {
            themeLoadErrorDialogWindow.recovered = value
        }
    }

    onClosing: function(event) {
        event.accepted = false
        WindowManager.closeThemeLoadError()
    }

    Dialog {
        id: themeLoadErrorDialog
        width: Screen.width * 0.25
        title: qsTr("Theme could not be loaded")
        modal: true
        closePolicy: Popup.NoAutoClose

        RowLayout {
            spacing: 12
            Layout.fillWidth: true

            Icon {
                Layout.alignment: Qt.AlignTop
                size: 42
                source: PathManager.images("icons/cw2_info.png")
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: themeLoadErrorDialogWindow.recovered
                    ? qsTr("The selected theme could not be loaded. \nClass Widgets has restored the default theme.")
                    : qsTr("The selected theme could not be loaded, and the default theme is unavailable.")
            }
        }

        standardButtons: Dialog.Ok

        onAccepted: WindowManager.closeThemeLoadError()
    }

    Component.onCompleted: themeLoadErrorDialog.open()
}
