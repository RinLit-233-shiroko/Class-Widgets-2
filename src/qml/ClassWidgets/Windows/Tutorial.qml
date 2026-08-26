import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import "../pages/tutorial" as TutorialPages

ApplicationWindow {
    id: tutorialWindow

    icon: PathManager.images("icons/cw2_whatsnew.png")
    title: qsTr("Getting Started")
    width: 960
    height: 640
    minimumWidth: 700
    minimumHeight: 500
    visible: true
    maximizeVisible: false

    readonly property int currentStep: pageStack.depth - 1
    property bool boundaryTransition: false
    property bool navigationPending: false
    property int pendingStep: -1
    property int normalExitDirection: 0
    property bool createShortcutOnComplete: Qt.platform.os === "windows"
    property Connections pageNavigation: Connections {
        target: pageStack.currentItem
        ignoreUnknownSignals: true

        function onBackRequested() {
            tutorialWindow.goBack()
        }

        function onNextRequested() {
            if (!pageStack.currentItem.managesNextNavigation)
                tutorialWindow.goNext()
        }
    }
    property ParallelAnimation normalPageExit: ParallelAnimation {
        NumberAnimation {
            target: pageStack.currentItem
            property: "pageTransitionOffset"
            to: pageStack.width * 0.25 * tutorialWindow.normalExitDirection
            duration: 220
            easing.type: Easing.Bezier
            easing.bezierCurve: [1, 0, 1, 1, 1, 1]
        }
        NumberAnimation {
            target: pageStack.currentItem
            property: "visualTransitionOpacity"
            to: 0
            duration: 140
            easing.type: Easing.OutCubic
        }
        onStopped: {
            if (tutorialWindow.navigationPending)
                tutorialWindow.finishNormalNavigation()
        }
    }
    property ParallelAnimation boundaryPageExit: ParallelAnimation {
        NumberAnimation {
            target: pageStack.currentItem
            property: "y"
            to: 2
            duration: 300
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }
        NumberAnimation {
            target: pageStack.currentItem
            property: "scale"
            to: 0.96
            duration: 300
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }
        NumberAnimation {
            target: pageStack.currentItem
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.Bezier
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }

        onStopped: {
            if (tutorialWindow.navigationPending)
                tutorialWindow.finishNormalNavigation()
        }
    }
    property Dialog skipDialog: Dialog {
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        title: qsTr("Skip setup?")
        width: 390

        Text {
            Layout.fillWidth: true
            text: qsTr("Are you sure you want to skip the setup?")
            typography: Typography.Body
            wrapMode: Text.WordWrap
        }

        standardButtons: Dialog.Ok | Dialog.Cancel

        onAccepted: tutorialWindow.completeTutorial()
    }
    property Dialog closeDialog: Dialog {
        parent: Overlay.overlay
        anchors.centerIn: parent
        modal: true
        title: qsTr("Close setup?")
        width: 390

        Text {
            Layout.fillWidth: true
            text: qsTr("Are you sure you want to close the setup?")
            typography: Typography.Body
            wrapMode: Text.WordWrap
        }

        standardButtons: Dialog.Cancel | Dialog.Ok

        onAccepted: Qt.quit()
    }
    readonly property var pageUrls: [
        Qt.resolvedUrl("../pages/tutorial/Welcome.qml"),
        Qt.resolvedUrl("../pages/tutorial/Language.qml"),
        Qt.resolvedUrl("../pages/tutorial/Theme.qml"),
        Qt.resolvedUrl("../pages/tutorial/Appearance.qml"),
        Qt.resolvedUrl("../pages/tutorial/Interactions.qml"),
        Qt.resolvedUrl("../pages/tutorial/Preferences.qml"),
        Qt.resolvedUrl("../pages/tutorial/Plugins.qml"),
        Qt.resolvedUrl("../pages/tutorial/Complete.qml")
    ]

    onClosing: function(event) {
        event.accepted = false
        closeDialog.open()
    }

    Component.onCompleted: {
        Theme.setThemeColor("#4099b2")
    }

    function switchTo(step) {
        if (pageStack.busy || navigationPending || step < 0
                || step >= pageUrls.length || step === currentStep)
            return

        boundaryTransition = (currentStep === 0 && step === 1)
                             || (currentStep === 1 && step === 0)
                             || (currentStep === pageUrls.length - 2
                                 && step === pageUrls.length - 1)
                             || (currentStep === pageUrls.length - 1
                                 && step === pageUrls.length - 2)
        if (boundaryTransition) {
            pendingStep = step
            navigationPending = true
            boundaryPageExit.start()
            return
        }

        pendingStep = step
        normalExitDirection = step > currentStep ? -1 : 1
        navigationPending = true
        normalPageExit.start()
    }

    function finishNormalNavigation() {
        var step = pendingStep
        pendingStep = -1
        navigationPending = false

        if (step > currentStep) {
            pageStack.push(pageUrls[step], { "tutorial": tutorialWindow })
        } else {
            pageStack.pop()
        }
    }

    function goNext() {
        switchTo(currentStep + 1)
    }

    function goBack() {
        switchTo(currentStep - 1)
    }

    function goToSetup() {
        switchTo(1)
    }

    function requestSkip() {
        skipDialog.open()
    }

    function completeTutorial() {
        Configs.set("app.tutorial_completed", true)
        Configs.set("app.startup_animation_skip_once", true)
        AppCentral.restart()
    }

    StackView {
        id: pageStack
        anchors.fill: parent
        clip: true

        initialItem: Component {
            TutorialPages.Welcome {
                tutorial: tutorialWindow
            }
        }

        pushEnter: Transition {
            SequentialAnimation {
                PropertyAction {
                    property: "z"
                    value: tutorialWindow.boundaryTransition ? 0 : 1
                }
                PropertyAction {
                    property: "pageTransitionOffset"
                    value: tutorialWindow.boundaryTransition ? 0 : pageStack.width * 0.25
                }
                PropertyAction {
                    property: "y"
                    value: tutorialWindow.boundaryTransition ? 2 : 0
                }
                PropertyAction {
                    property: "scale"
                    value: tutorialWindow.boundaryTransition ? 0.96 : 1
                }
                PropertyAction {
                    property: "opacity"
                    value: tutorialWindow.boundaryTransition ? 0 : 1
                }
                PropertyAction {
                    property: "visualTransitionOpacity"
                    value: tutorialWindow.boundaryTransition ? 1 : 0
                }
                ParallelAnimation {
                NumberAnimation {
                    property: "pageTransitionOffset"
                    to: 0
                    duration: tutorialWindow.boundaryTransition ? 0 : 220
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0, 0, 0, 1, 1, 1]
                }
                NumberAnimation {
                    property: "y"
                    to: 0
                    duration: tutorialWindow.boundaryTransition ? 300 : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "scale"
                    to: 1
                    duration: tutorialWindow.boundaryTransition ? 300 : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    to: 1
                    duration: tutorialWindow.boundaryTransition ? 300 : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "visualTransitionOpacity"
                    to: 1
                    duration: tutorialWindow.boundaryTransition ? 0 : 180
                    easing.type: Easing.OutCubic
                }
                }
            }
        }
        pushExit: Transition {
            ParallelAnimation {
                PropertyAction {
                    property: "z"
                    value: tutorialWindow.boundaryTransition ? 1 : 2
                }
                NumberAnimation {
                    property: "pageTransitionOffset"
                    from: 0
                    to: -pageStack.width * 0.25
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [1, 0, 1, 1, 1, 1]
                }
                NumberAnimation {
                    property: "y"
                    from: 0
                    to: 2
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.96
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
            }
        }
        popEnter: Transition {
            SequentialAnimation {
                PropertyAction {
                    property: "z"
                    value: tutorialWindow.boundaryTransition ? 0 : 1
                }
                PropertyAction {
                    property: "pageTransitionOffset"
                    value: tutorialWindow.boundaryTransition ? 0 : -pageStack.width * 0.25
                }
                PropertyAction {
                    property: "y"
                    value: tutorialWindow.boundaryTransition ? 2 : 0
                }
                PropertyAction {
                    property: "scale"
                    value: tutorialWindow.boundaryTransition ? 0.96 : 1
                }
                PropertyAction {
                    property: "opacity"
                    value: tutorialWindow.boundaryTransition ? 0 : 1
                }
                PropertyAction {
                    property: "visualTransitionOpacity"
                    value: tutorialWindow.boundaryTransition ? 1 : 0
                }
                ParallelAnimation {
                NumberAnimation {
                    property: "pageTransitionOffset"
                    to: 0
                    duration: tutorialWindow.boundaryTransition ? 0 : 220
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0, 0, 0, 1, 1, 1]
                }
                NumberAnimation {
                    property: "y"
                    to: 0
                    duration: tutorialWindow.boundaryTransition ? 300 : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "scale"
                    to: 1
                    duration: tutorialWindow.boundaryTransition ? 300 : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    to: 1
                    duration: tutorialWindow.boundaryTransition ? 300 : 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "visualTransitionOpacity"
                    to: 1
                    duration: tutorialWindow.boundaryTransition ? 0 : 180
                    easing.type: Easing.OutCubic
                }
                }
            }
        }
        popExit: Transition {
            ParallelAnimation {
                PropertyAction {
                    property: "z"
                    value: tutorialWindow.boundaryTransition ? 1 : 2
                }
                NumberAnimation {
                    property: "pageTransitionOffset"
                    from: 0
                    to: pageStack.width * 0.25
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [1, 0, 1, 1, 1, 1]
                }
                NumberAnimation {
                    property: "y"
                    from: 0
                    to: 2
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.96
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 0
                    easing.type: Easing.Bezier
                    easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
                }
            }
        }
    }

}
