import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

ColumnLayout {
    id: root

    property bool inlineDetails: false

    spacing: 8

    component ConsentSwitch: Switch {
        objectName: "diagnosticConsentSwitch"
        checked: Configs.data.telemetry.enabled
        enabled: !Configs.isKeyLocked("telemetry.enabled")
        onToggled: {
            AppCentral.setTelemetryEnabled(checked)
            checked = Qt.binding(function() { return Configs.data.telemetry.enabled })
        }
    }

    SettingExpander {
        id: consentExpander
        Layout.fillWidth: true
        expanded: root.inlineDetails
        icon.name: "ic_fluent_shield_20_regular"
        title: qsTr("Send diagnostics")
        description: qsTr("Optional error reports, INFO+ logs, and operation timings via Sentry. Off by default.")

        action: ConsentSwitch {}

        SettingItem {
            visible: !root.inlineDetails
            title: qsTr("About diagnostics")

            Hyperlink {
                text: qsTr("View details")
                onClicked: detailsDialog.open()
            }
        }

        Details {
            Layout.fillWidth: true
            Layout.margins: 16
            visible: root.inlineDetails
        }
    }

    property Dialog detailsDialog: Dialog {
        parent: Overlay.overlay
        anchors.centerIn: parent
        title: qsTr("About diagnostics")
        width: Math.min(520, parent.width - 48)
        height: Math.min(440, parent.height - 48)
        modal: true
        standardButtons: Dialog.Close

        Flickable {
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: details.implicitHeight
            flickableDirection: Flickable.VerticalFlick

            ScrollBar.vertical: ScrollBar {}

            Details {
                id: details
                width: parent.width
            }
        }
    }

    component Details: ColumnLayout {
        spacing: 12

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Reports include exception types and sanitized stack traces, redacted INFO and higher log messages, app and system versions, relevant plugin or theme identifiers, and operation timings.")
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("Full settings, log files, local variables, and device names are not attached. Log messages are redacted before sending to Sentry SaaS. Earlier errors and logs are not uploaded after you enable diagnostics.")
        }
        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("You can turn this off at any time in About → Diagnostics & maintenance. Unsent reports are discarded when you turn it off.")
        }
        Hyperlink {
            text: qsTr("Sentry privacy policy")
            openUrl: "https://sentry.io/privacy/"
        }
    }
}
