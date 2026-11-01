import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
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
        icon.source: PathManager.images("tutorial/cw2_privacy.png")
        icon.size: 176
    }

    ColumnLayout {
        width: parent.width
        height: parent.height
        spacing: 12

        PrivacyPolicyText {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120
        }

        DiagnosticConsent {
            Layout.fillWidth: true
        }
    }
}
