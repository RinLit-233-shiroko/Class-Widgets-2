import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


ApplicationWindow {
    id: tutorialWindow
    icon: PathManager.assets("images/icons/cw2_settings.png")
    title: qsTr("Welcome ╰(*°▽°*)╯")
    width: Screen.width * 0.4
    height: Screen.height * 0.5

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        anchors.topMargin: 16
        anchors.bottomMargin: 48


        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignCenter
            Icon {
                Layout.alignment: Qt.AlignHCenter
                source: PathManager.images("logo.png")
                size: 72
            }
            Text {
                Layout.fillWidth: true
                typography: Typography.Subtitle
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Welcome to Class Widgets 2")
            }
        }

        InfoBar {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            closable: false
            Layout.fillWidth: false
            Layout.preferredWidth: tutorialWindow.width * 0.7
            severity: Severity.Warning
            title: qsTr("注意")
            text: qsTr(
                "初始引导窗口还未完工，在做啦在做啦 \n" +
                "目前版本为测试版，大多数功能还未补完。若要在教学环境中使用，请三思而后行。\n" +
                "欢迎到我们的 GitHub 页面提交反馈或建议，谢谢！"
            )
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Text {
                text: qsTr("Select a language")
            }
            ComboBox {
                property var data: [AppCentral.translator.getSystemLanguage(), "en_US", "zh_CN"]
                property bool initialized: false
                model: ListModel {
                    ListElement { text: qsTr("Use System Language") }
                    ListElement { text: "English (US)" }
                    ListElement { text: "简体中文" }
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

        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            Button {
                text: qsTr("Exit")
                onClicked: Qt.quit()
            }
            Button {
                highlighted: true
                text: qsTr("Get started")
                onClicked: {
                    Configs.set("app.tutorial_completed", true)
                    AppCentral.restart()
                }
            }
        }
    }

    // 测试水印
    Watermark {
        anchors.centerIn: parent
    }
}