// CheckSingleInstanceDialog.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

ApplicationWindow {
    id: singleInstanceDialogWindow
    visible: true
    width: 320
    height: 180


    Item {   // 包裹一层 Item，避免直接挂到 contentItem
        Dialog {
            id: checkSingleInstanceDialog
            title: qsTr("Already running")
            standardButtons: Dialog.Ok | Dialog.Cancel

            Text { text: qsTr("Do you want another instance?") }
            onAccepted: {
                singleInstanceDialogWindow.close();
                AppCentral.init()

            }
            onRejected: {
                singleInstanceDialogWindow.close();
                AppCentral.quit()
            }
        }
        
    }
    Component.onCompleted: {
        singleInstanceDialogWindow.flags |= Qt.WindowStaysOnTopHint
        checkSingleInstanceDialog.open()
    }
    
    
}
