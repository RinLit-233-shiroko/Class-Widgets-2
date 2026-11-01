import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

ColumnLayout {
    spacing: 8

    Text {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        text: qsTr("Send error reports and sampled operation timings to Sentry to help improve Class Widgets. Optional, off by default, and effective immediately when enabled.")
    }

    SettingExpander {
        Layout.fillWidth: true
        icon.name: "ic_fluent_shield_20_regular"
        title: qsTr("Send diagnostics")

        action: Switch {
            objectName: "diagnosticConsentSwitch"
            checked: Configs.data.telemetry.enabled
            enabled: !Configs.isKeyLocked("telemetry.enabled")
            onToggled: {
                AppCentral.setTelemetryEnabled(checked)
                checked = Qt.binding(function() { return Configs.data.telemetry.enabled })
            }
        }

        SettingItem {
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Reports include exception types and sanitized stack traces, app and system versions, relevant plugin or theme identifiers, and operation timings.")
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: qsTr("Schedule contents, full settings, log files, local variables, and device names are not collected. Reports go to Sentry SaaS. Earlier errors are not uploaded after you enable diagnostics.")
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
    }

    InfoBar {
        Layout.fillWidth: true
        visible: AppCentral.telemetryError.length > 0
        severity: Severity.Error
        title: qsTr("Preference could not be saved")
        text: AppCentral.telemetryError
    }
}
