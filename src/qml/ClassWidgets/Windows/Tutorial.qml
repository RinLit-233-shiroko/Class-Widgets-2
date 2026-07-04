import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


ApplicationWindow {
    id: tutorialWindow
    icon: PathManager.assets("images/icons/cw2_settings.png")
    title: qsTr("Welcome ╰(*°▽°*)╯")
    width: Math.min(Screen.width * 0.48, 820)
    height: Math.min(Screen.height * 0.62, 640)

    property int currentPage: 0
    property var pages: [
        { title: qsTr("Language"), description: qsTr("Choose the language used by Class Widgets 2.") },
        { title: qsTr("General"), description: qsTr("Set theme, window behavior, Mini Mode and startup.") },
        { title: qsTr("Widgets"), description: qsTr("Adjust widget scale, opacity, font and display position.") },
        { title: qsTr("Interactions"), description: qsTr("Choose how widgets react to clicks, hover and window state.") },
        { title: qsTr("Personalization"), description: qsTr("Pick accent color and a visual theme.") },
        { title: qsTr("Subjects"), description: qsTr("Select default subjects and add your custom courses.") },
        { title: qsTr("Finish"), description: qsTr("Save setup and start using Class Widgets 2.") }
    ]

    function nextPage() {
        if (currentPage < pages.length - 1) {
            currentPage += 1
        }
    }

    function previousPage() {
        if (currentPage > 0) {
            currentPage -= 1
        }
    }

    function finishSetup() {
        if (!subjectsPageLoader.item || !subjectsPageLoader.item.applySubjects()) {
            finishError.visible = true
            return
        }
        AppCentral.scheduleManager.save()
        Configs.set("app.tutorial_completed", true)
        AppCentral.restart()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Icon {
                source: PathManager.images("logo.png")
                size: 40
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    typography: Typography.BodyStrong
                    text: tutorialWindow.pages[tutorialWindow.currentPage].title
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: tutorialWindow.pages[tutorialWindow.currentPage].description
                    elide: Text.ElideRight
                }
            }

            Text {
                text: qsTr("%1 / %2").arg(tutorialWindow.currentPage + 1).arg(tutorialWindow.pages.length)
            }
        }

        ProgressBar {
            Layout.fillWidth: true
            from: 1
            to: tutorialWindow.pages.length
            value: tutorialWindow.currentPage + 1
        }

        InfoBar {
            id: finishError
            Layout.fillWidth: true
            visible: false
            closable: true
            severity: Severity.Error
            title: qsTr("Unable to finish setup")
            text: qsTr("Please select or add at least one subject before starting.")
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true
            padding: 14

            StackLayout {
                id: pageStack
                anchors.fill: parent
                currentIndex: tutorialWindow.currentPage

                Loader {
                    active: tutorialWindow.currentPage === 0
                    sourceComponent: OobeLanguagePage {}
                }

                Loader {
                    active: tutorialWindow.currentPage === 1
                    sourceComponent: OobeGeneralPage {}
                }

                Loader {
                    active: tutorialWindow.currentPage === 2
                    sourceComponent: OobeWidgetsPage {}
                }

                Loader {
                    active: tutorialWindow.currentPage === 3
                    sourceComponent: OobeInteractionsPage {}
                }

                Loader {
                    active: tutorialWindow.currentPage === 4
                    sourceComponent: OobePersonalizationPage {}
                }

                Loader {
                    id: subjectsPageLoader
                    active: tutorialWindow.currentPage >= 5
                    sourceComponent: OobeSubjectsPage {}
                }

                Loader {
                    active: tutorialWindow.currentPage === 6
                    sourceComponent: OobeFinishPage {}
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: qsTr("Exit")
                onClicked: Qt.quit()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Back")
                enabled: tutorialWindow.currentPage > 0
                onClicked: tutorialWindow.previousPage()
            }

            Button {
                highlighted: tutorialWindow.currentPage < tutorialWindow.pages.length - 1
                visible: tutorialWindow.currentPage < tutorialWindow.pages.length - 1
                text: qsTr("Next")
                onClicked: tutorialWindow.nextPage()
            }

            Button {
                highlighted: true
                visible: tutorialWindow.currentPage === tutorialWindow.pages.length - 1
                text: qsTr("Start using")
                onClicked: tutorialWindow.finishSetup()
            }
        }
    }

    // 测试水印
    Watermark {
        anchors.centerIn: parent
    }
}