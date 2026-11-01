import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import "../../Components/tutorial" as TutorialComponents

TutorialComponents.TutorialPage {
    id: root

    title: qsTr("License terms")
    description: qsTr("Read our privacy policy. Optional diagnostics are sent through the Sentry SDK to help us improve Class Widgets.")
    currentStep: 2
    totalSteps: 7
    fillOperationHeight: true
    nextText: qsTr("Agree and continue")
    nextIcon: "ic_fluent_checkmark_20_regular"

    rightContent: TutorialComponents.TutorialVisual {
        icon.source: PathManager.images("icons/cw2_plugin.png")
        icon.size: 176
    }

    ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: 12

        ScrollableTextArea {
            id: policy
            objectName: "privacyPolicyText"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120
            implicitHeight: 160
            readOnly: true
            textArea.selectByMouse: true
            textArea.height: Math.max(policy.height, textArea.implicitHeight)
            text: qsTr("Privacy policy (placeholder)\n\nThe full privacy policy will be provided here.\n\nThis area will describe the information collected, how it is used, the third-party services involved, data retention, and your choices.\n\nDiagnostic reporting is optional. You can continue with diagnostics turned off.")
        }

        CheckBox {
            id: diagnostics
            objectName: "diagnosticConsentCheckBox"
            Layout.fillWidth: true
            checked: Configs.data.telemetry.enabled
            enabled: !Configs.isKeyLocked("telemetry.enabled")
            text: qsTr("Enable diagnostics to help improve your everyday experience (optional)")
            onToggled: {
                AppCentral.setTelemetryEnabled(checked)
                checked = Qt.binding(function() { return Configs.data.telemetry.enabled })
            }

            contentItem: Text {
                leftPadding: diagnostics.indicator.width + diagnostics.spacing
                text: diagnostics.text
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
