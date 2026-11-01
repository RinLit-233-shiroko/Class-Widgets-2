import QtQuick
import RinUI

ScrollableTextArea {
    id: root
    objectName: "privacyPolicyText"
    implicitHeight: 160
    readOnly: true
    textArea.selectByMouse: true
    textArea.height: Math.max(root.height, textArea.implicitHeight)
    text: qsTr("Privacy policy (placeholder)\n\nThe full privacy policy will be provided here.\n\nThis area will describe the information collected, how it is used, the third-party services involved, data retention, and your choices.\n\nDiagnostic reporting is optional. You can continue with diagnostics turned off.")
}
