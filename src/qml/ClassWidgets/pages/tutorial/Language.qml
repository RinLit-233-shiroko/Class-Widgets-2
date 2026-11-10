import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../Components/tutorial" as TutorialComponents
import RinUI


TutorialComponents.TutorialPage {
    id: root

    property var languages: [AppCentral.translator.getSystemLanguage(), "en_US", "ja_JP", "zh_CN", "zh_HK"]
    property bool languageReady: false
    title: qsTr("Choose your language")
    description: qsTr("Choose a language. You can refine every setting later.")
    currentStep: 1
    totalSteps: 7
    icon.source: PathManager.images("tutorial/cw2_lang.png")
    // visualTitle: qsTr("A little more you")
    // visualSubtitle: qsTr("Theme and language")
    // visualIconName: "ic_fluent_paint_brush_20_regular"

    ColumnLayout {
        width: parent.width
        spacing: 4

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text { text: qsTr("Language"); typography: Typography.BodyStrong }

            ListView {
                id: languageListView
                Layout.fillWidth: true
                height: contentHeight // 让 ListView 高度自适应内容
                property var data: [AppCentral.translator.getSystemLanguage(), "en_US", "ja_JP", "zh_CN", "zh_HK"]
                property bool initialized: false

                model: ListModel {
                    ListElement { text: qsTr("Use System Language") }
                    ListElement { text: "English (US)" }
                    ListElement { text: "日本語" }
                    ListElement { text: "简体中文" }
                    ListElement { text: "繁體中文（香港）" }
                }

                Component.onCompleted: {
                    currentIndex = data.indexOf(AppCentral.translator.getLanguage())
                    console.log("Language: " + AppCentral.translator.getLanguage())
                    initialized = true
                }

                onCurrentIndexChanged: {
                    if (!initialized) return
                    AppCentral.translator.setLanguage(data[currentIndex])
                }
            }
        }

        // ColumnLayout {
        //     width: parent.width
        //     spacing: 8
        //
        //     Text { text: qsTr("Appearance"); typography: Typography.BodyStrong }
        //
        //     RowLayout {
        //         width: parent.width
        //         spacing: 8
        //
        //         Repeater {
        //             model: [
        //                 { name: qsTr("Light"), value: Theme.mode.Light, color: "#f7ffff" },
        //                 { name: qsTr("Dark"), value: Theme.mode.Dark, color: "#16383b" },
        //                 { name: qsTr("System"), value: Theme.mode.Auto, color: "#89bfc2" }
        //             ]
        //
        //             delegate: Button {
        //                 Layout.fillWidth: true
        //                 flat: true
        //                 highlighted: Theme.getTheme() === modelData.value
        //                 text: modelData.name
        //                 onClicked: Theme.setTheme(modelData.value)
        //
        //                 Rectangle {
        //                     anchors.horizontalCenter: parent.horizontalCenter
        //                     anchors.top: parent.top
        //                     anchors.topMargin: 7
        //                     width: 28
        //                     height: 4
        //                     radius: 2
        //                     color: modelData.color
        //                 }
        //             }
        //         }
        //     }
        // }
    }
}
