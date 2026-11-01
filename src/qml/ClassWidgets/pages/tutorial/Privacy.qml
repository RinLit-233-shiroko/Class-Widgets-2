import QtQuick
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import "../../Components/tutorial" as TutorialComponents

TutorialComponents.TutorialPage {
    id: root

    title: qsTr("Privacy & diagnostics")
    description: qsTr("Choose whether to help us diagnose problems. You can continue with diagnostics turned off.")
    currentStep: 6
    totalSteps: 7
    icon.name: "ic_fluent_shield_20_regular"

    DiagnosticConsent {
        width: parent.width
    }
}
