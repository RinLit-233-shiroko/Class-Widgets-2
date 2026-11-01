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
        description: qsTr("Optional error reports, logs, and operation timings via Sentry. Off by default.")

        action: ConsentSwitch {}

        SettingItem {
            visible: !root.inlineDetails
            title: qsTr("About diagnostics")

            Hyperlink {
                text: qsTr("View details")
                onClicked: detailsDialog.open()
            }
        }

        SettingItem {
            visible: !root.inlineDetails
            title: qsTr("Installation ID")

            TextField {
                objectName: "telemetryInstallationId"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: 260
                text: Configs.data.telemetry.installation_id
                readOnly: true
                clearEnabled: false
            }
        }

        SettingItem {
            visible: root.inlineDetails

            Details {
                Layout.fillWidth: true
            }
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
            text: qsTr("Session reports include duration, error count, and exit status. A random installation ID stored in your settings links diagnostic reports and sessions from this installation. It is sent only while diagnostics are enabled and is not derived from your hardware, username, or email.")
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
