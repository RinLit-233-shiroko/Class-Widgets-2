import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects


FluentPage {
    id: root
    horizontalPadding: 0
    wrapperWidth: width - 42*2

    // Banner / 横幅 //
    contentHeader: Item {
        width: parent.width
        height: Math.max(window.height * 0.35, 200)

        Image {
            id: banner
            anchors.fill: parent
            source: PathManager.assets("images/banner/cw2.png")
            fillMode: Image.PreserveAspectCrop
            // verticalAlignment: Image.AlignTop

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: banner.width
                    height: banner.height

                    // 渐变效果
                    gradient: Gradient {
                        GradientStop { position: 0.7; color: "white" }  // 不透明
                        GradientStop { position: 1.0; color: "transparent" }  // 完全透明
                    }
                }
            }
        }

        Column {
            anchors {
                top: parent.top
                left: parent.left
                leftMargin: 56
                topMargin: 38
            }
            spacing: 8

            Text {
                color: "#fff"
                typography: Typography.BodyLarge
                text: qsTr("Reimagining Your Schedule.")
            }

            Text {
                color: "#fff"
                typography: Typography.Title
                text: qsTr("Class Widgets 2")
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("About")
        }

        SettingExpander {
            Layout.fillWidth: true
            title: qsTr("Class Widgets 2")
            description: qsTr("© 2024-2026 RinLit. All rights reserved \nLicensed under the MIT license")
            icon.source: PathManager.images("logo.png")
            icon.size: 28

            content: RowLayout {
                spacing: 8
                InfoBadge {
                    text: Configs.data.app.channel
                }
                Text {
                    color: Theme.currentTheme.colors.textSecondaryColor
                    text: Configs.data.app.version
                }
            }

            SettingItem {
                id: repo
                title: qsTr("To view this repository")

                TextInput {
                    id: repoUrl
                    readOnly: true
                    text: "https://github.com/RinLit-233-shiroko/Class-Widgets-2"
                    wrapMode: TextInput.Wrap
                }
                ToolButton {
                    flat: true
                    icon.name: "ic_fluent_open_20_regular"
                    onClicked: {
                        Qt.openUrlExternally(repoUrl.text)
                    }
                }
            }
            SettingItem {
                title: qsTr("File a bug or request new sample")

                Hyperlink {
                    text: qsTr("Create an issue on GitHub")
                    openUrl: "https://github.com/RinLit-233-shiroko/Class-Widgets-2/issues/new/choose"
                }
            }
            SettingItem {
                Column {
                    Layout.fillWidth: true
                    Text {
                        text: qsTr("Dependencies & references")
                    }
                    Hyperlink {
                        text: qsTr("Qt & Qt Quick")
                        openUrl: "https://www.qt.io/"
                    }
                    Hyperlink {
                        text: qsTr("Fluent Design System")
                        openUrl: "https://fluent2.microsoft.design/"
                    }
                    Hyperlink {
                        text: qsTr("RinUI")
                        openUrl: "https://ui.rinlit.cn/"
                    }
                    Hyperlink {
                        text: qsTr("Loguru")
                        openUrl: "https://github.com/Delgan/loguru"
                    }
                    Hyperlink {
                        text: qsTr("Pydantic")
                        openUrl: "https://docs.pydantic.dev/latest/"
                    }
                }
            }
            SettingItem {
                title: qsTr("License")
                description: qsTr("This project is licensed under the GPL-3 license")

                Hyperlink {
                    text: qsTr("GPL-3 License")
                    onClicked: {
                        licenseDialog.open()
                    }
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Advances")
        }

        SettingExpander {
            Layout.fillWidth: true
            icon.name: "ic_fluent_text_bullet_list_square_warning_20_regular"
            title: qsTr("Log Storage Disabled")
            description: qsTr("When enabled, the app will <b>not</b> save logs.")

            action: Switch {
                onCheckedChanged: Configs.set("app.no_logs", checked)
                Component.onCompleted: checked = Configs.data.app.no_logs
            }

            SettingItem {
                title: qsTr("Clear Logs")

                Button {
                    icon.name: "ic_fluent_broom_20_regular"
                    text: qsTr("Clear")
                    onClicked: {
                        let resultTuple = UtilsBackend.clearLogs() // 0, bool; 1, int(kb)
                        if (resultTuple[0]) {
                            floatLayer.createInfoBar({
                                title: qsTr("Cleared"),
                                text: qsTr("All logs have been cleared about ") + resultTuple[1] + " KB.",
                                severity: Severity.Success,
                                duration: 2000,
                            })
                        } else {
                            floatLayer.createInfoBar({
                                title: qsTr("Failed"),
                                text: qsTr("Failed to clear logs."),
                                severity: Severity.Error,
                                duration: 2000,
                            })
                        }
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_developer_board_search_20_regular"
            title: qsTr("Debug Mode")
            description: qsTr(
                "Enable Debug Mode to access core widget information, " +
                "and debugging tools \n" +
                "* Requires restart"
            )

            Switch {
                onCheckedChanged: Configs.set("app.debug_mode", checked)
                Component.onCompleted: checked = Configs.data.app.debug_mode
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_learning_app_20_regular"
            title: qsTr("Show Tutorials again")

            Button {
                text: qsTr("Restart")
                onClicked: {
                    Configs.set("app.tutorial_completed", false)
                    AppCentral.restart()
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
            text: qsTr("This project (Class Widgets 2) is licensed under the GPL-3 license. For details, see:")
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