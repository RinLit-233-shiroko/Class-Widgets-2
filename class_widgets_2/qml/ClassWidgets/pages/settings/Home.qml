import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentPage {
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

            // Text {
            //     color: "#fff"
            //     typography: Typography.BodyLarge
            //     text: qsTr("ww")
            // }

            Text {
                color: "#fff"
                typography: Typography.Title
                text: qsTr("Home")
            }
        }
    }

    // ColumnLayout {
    //     Layout.fillWidth: true
    //     Layout.alignment: Qt.AlignCenter
    //     Text {
    //         text: qsTr("Under Construction...")
    //     }
    //     Button {
    //         Layout.alignment: Qt.AlignCenter
    //         text: qsTr("OK")
    //     }
    // }

    // 还没想好放什么

    InfoBar {
        Layout.fillWidth: true
        severity: Severity.Warning
        title: qsTr("Warning")
        text: qsTr(
            "This version is still under testing and may contain bugs or incomplete features. " +
            "You are welcome to submit issues on GitHub"
        )
    }

    RowLayout {
        Layout.fillWidth: true

        Component {
            id: card
            Clip {
                Layout.fillWidth: true
                Layout.preferredWidth: 220
                Layout.preferredHeight: 128

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 18

                    Icon {
                        Layout.alignment: Qt.AlignVCenter
                        name: modelData.icon
                        source: modelData.icon
                        size: 32
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        width: parent.width
                        typography: Typography.BodyLarge
                        text: modelData.title
                    }
                }

                // corner sign
                IconWidget {
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: 12
                    }
                    size: 18
                    icon: "ic_fluent_open_20_regular"
                }

                onClicked: Qt.openUrlExternally(modelData.url)
            }
        }

        Repeater {
            model: [
                {
                    icon: Theme.isDark() ? PathManager.images("icons/github_light.svg")
                                            : PathManager.images("icons/github.svg"),
                    title: qsTr("GitHub"),
                    url: "https://github.com/RinLit-233-shiroko/Class-Widgets-2/issues"
                },
                {
                    icon: "ic_fluent_chat_help_20_filled",
                    title: qsTr("Discord"),
                    url: qsTr("https://discord.gg/nNZxaCBh")  // 国内换为q群，在翻译文件改 https://qm.qq.com/q/VXK8RE3Uqc
                }
            ]
            delegate: card
        }
    }
}