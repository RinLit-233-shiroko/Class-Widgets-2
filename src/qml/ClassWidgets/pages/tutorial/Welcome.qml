import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.VectorImage
import RinUI
// import
import "../../Components/tutorial" as TutorialComponents

Item {
    id: root
    transformOrigin: Item.Center

    property var tutorial
    property real pageTransitionOffset: 0
    property real visualTransitionOpacity: 1
    property var welcomeGreetings: ["欢迎", "歡迎", "ようこそ", "幸會", "Welcome"]
    property int greetingIndex: 0
    property string displayedGreeting: welcomeGreetings[greetingIndex]
    property string outgoingGreeting: ""
    property real greetingProgress: 0
    property real greetingEntryDelay: 0
    property real contentEntranceProgress: 0

    function clampedProgress(value) {
        return Math.max(0, Math.min(1, value))
    }

    function easeInCubic(value) {
        value = clampedProgress(value)
        return value * value * value
    }

    function easeOutQuint(value) {
        value = clampedProgress(value)
        return 1 - Math.pow(1 - value, 5)
    }

    function entranceProgress(delay, duration) {
        return easeOutQuint((contentEntranceProgress - delay) / duration)
    }

    function greetingCharStep(length, span) {
        return span / Math.max(1, length)
    }

    function advanceGreeting() {
        greetingProgress = 0
        greetingEntryDelay = 0.36
        outgoingGreeting = displayedGreeting
        greetingIndex = (greetingIndex + 1) % welcomeGreetings.length
        displayedGreeting = welcomeGreetings[greetingIndex]
        greetingTransition.start()
    }

    Timer {
        id: greetingTimer
        interval: 2400
        repeat: true
        running: root.visible && root.welcomeGreetings.length > 0

        onTriggered: root.advanceGreeting()
    }

    NumberAnimation {
        id: greetingTransition
        target: root
        property: "greetingProgress"
        from: 0
        to: 1
        duration: 1500
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: contentEntrance
        target: root
        property: "contentEntranceProgress"
        from: 0
        to: 1
        duration: 1050
        easing.type: Easing.Linear
    }

    Component.onCompleted: {
        greetingTransition.start()
        contentEntrance.start()
    }

    // TutorialComponents.TutorialBackdrop {
    //     anchors.fill: parent
    // }

    ColumnLayout {
        // anchors.top: parent.top
        // anchors.bottom: parent.bottom
        // anchors.horizontalCenter: parent.horizontalCenter
        anchors.fill: parent
        anchors.margins: 64
        spacing: 64

        ColumnLayout {
            spacing: 6
            Layout.alignment: Qt.AlignCenter
            Item {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 280
                Layout.preferredHeight: 56

                Row {
                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: root.outgoingGreeting.length

                        delegate: Text {
                            readonly property real progress: root.easeInCubic(
                                (root.greetingProgress - index * root.greetingCharStep(root.outgoingGreeting.length, 0.31)) / 0.31
                            )

                            text: root.outgoingGreeting.charAt(index)
                            typography: Typography.Title
                            font.pixelSize: 42
                            opacity: 1 - progress
                            y: -10 * progress
                            scale: 1 - 0.08 * progress
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 0

                    Repeater {
                        model: root.displayedGreeting.length

                        delegate: Text {
                            readonly property real progress: root.easeOutQuint(
                                (root.greetingProgress - root.greetingEntryDelay - index * root.greetingCharStep(root.displayedGreeting.length, 0.5)) / 0.5
                            )

                            text: root.displayedGreeting.charAt(index)
                            typography: Typography.Title
                            font.pixelSize: 42
                            opacity: progress
                            y: 14 * (1 - progress)
                            scale: 0.94 + 0.06 * progress
                        }
                    }
                }
            }

            Image {
                id: banner
                readonly property real progress: root.entranceProgress(0.08, 0.5)
                Layout.alignment: Qt.AlignCenter
                source: PathManager.images(
                    "tutorial/widgets_" + (Theme.isDark()? "dark" : "light") + ".png"
                )
                fillMode: Image.PreserveAspectCrop
                opacity: progress
                scale: 0.96 + 0.04 * progress
                transform: Translate { y: 18 * (1 - banner.progress) }
                transformOrigin: Item.Center
                // verticalAlignment: Image.AlignTop
            }
        }

        // Item {
        //     Layout.fillHeight: true
        // }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            spacing: 16


            RowLayout {
                id: primaryActionRow
                readonly property real progress: root.entranceProgress(0.38, 0.34)
                Layout.alignment: Qt.AlignCenter
                opacity: progress
                scale: 0.98 + 0.02 * progress
                transform: Translate { y: 12 * (1 - primaryActionRow.progress) }
                transformOrigin: Item.Center

                // ComboBox {
                //     Layout.preferredHeight: startBtn.height + 4
                //     property var data: [AppCentral.translator.getSystemLanguage(), "en_US", "zh_CN"]
                //     property bool initialized: false
                //     model: ListModel {
                //         ListElement { text: qsTr("Use System Language") }
                //         ListElement { text: "English (US)" }
                //         ListElement { text: "简体中文" }
                //     }
                //
                //     Component.onCompleted: {
                //         currentIndex = data.indexOf(AppCentral.translator.getLanguage())
                //         console.log("Language: " + AppCentral.translator.getLanguage())
                //         initialized = true
                //     }
                //
                //     onCurrentIndexChanged: {
                //         if (!initialized) return
                //         AppCentral.translator.setLanguage(data[currentIndex])
                //     }
                // }

                Button {
                    id: startBtn
                    Layout.alignment: Qt.AlignCenter
                    highlighted: true
                    icon.name: "ic_fluent_star_emphasis_20_regular"
                    text: qsTr("Get started")
                    onClicked: root.tutorial.goNext()
                }
            }

            RowLayout {
                id: secondaryActionRow
                readonly property real progress: root.entranceProgress(0.56, 0.3)
                Layout.alignment: Qt.AlignCenter
                opacity: progress
                transform: Translate { y: 10 * (1 - secondaryActionRow.progress) }

                Hyperlink {
                    text: qsTr("Data migration")
                    onClicked: root.tutorial.goToSetup()
                    enabled: false
                }

                Hyperlink {
                    text: qsTr("View License")
                    onClicked: {
                        licenseDialog.open()
                    }
                }

                Hyperlink {
                    text: qsTr("Skip tutorial")
                    onClicked: root.tutorial.requestSkip()
                }
            }
        }
    }

    Dialog {
        id: licenseDialog
        title: qsTr("License Agreement")
        width: root.width * 0.8
        height: root.height * 0.8
        modal: true

        Text {
            Layout.fillWidth: true
            text: qsTr("This project (Class Widgets 2) is licensed under the MIT license. For details, see:")
        }

        Flickable {
            clip: true
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: licenseText.height

            ScrollBar.vertical: ScrollBar {}

            Text {
                id: licenseText
                width: parent.width
                // textFormat: Text.RichText
                text: UtilsBackend.licenseText
            }
        }

        standardButtons: Dialog.Close
    }
}
