import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import QtQuick.Window as QQW


QQW.Window {
    id: singleInstanceDialogWindow
    visible: true
    // width: 320
    // height: 180
    width: screen.width
    height: screen.height
    color: "transparent"

    flags: Qt.WindowStaysOnTopHint | Qt.FramelessWindowHint | Qt.WA_TranslucentBackground


    Dialog {
        id: checkSingleInstanceDialog
        width: Screen.width * 0.25
        title: qsTr("Already running")
        // Text { text: qsTr("Do you want another instance?") }

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
                text: qsTr(
                    "Class Widgets is already running.\n\n"
                    + "Looks like it was opened twice.\n"
                    + "You can continue to open another one, "
                    + "or close this window."
                )
            }
        }

        footer: DialogButtonBox {
            Layout.fillWidth: true
            Button {
                Layout.preferredWidth: parent.width * 0.5
                text: qsTr("Exit")
                highlighted: true
                onClicked: {
                    singleInstanceDialogWindow.close()
                    AppCentral.quit()
                }
            }

            Button {
                Layout.preferredWidth: parent.width * 0.5
                text: qsTr("Open anyway")
                onClicked: {
                    singleInstanceDialogWindow.close()
                    AppCentral.init()
                }
            }
        }
    }

    Component.onCompleted: {
        // singleInstanceDialogWindow.flags |= Qt.WindowStaysOnTopHint
        checkSingleInstanceDialog.open()
    }
}
