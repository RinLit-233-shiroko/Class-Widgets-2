import QtQuick
import RinUI

CheckBox {
    id: root
    objectName: "diagnosticConsentCheckBox"
    checked: Configs.data.telemetry.enabled
    enabled: !Configs.isKeyLocked("telemetry.enabled")
    text: qsTr("Enable anonymous diagnostics")
    onToggled: {
        AppCentral.setTelemetryEnabled(checked)
        checked = Qt.binding(function() { return Configs.data.telemetry.enabled })
    }

    contentItem: Text {
        leftPadding: root.indicator.width + root.spacing
        text: root.text
        wrapMode: Text.WordWrap
        verticalAlignment: Text.AlignVCenter
    }
}
