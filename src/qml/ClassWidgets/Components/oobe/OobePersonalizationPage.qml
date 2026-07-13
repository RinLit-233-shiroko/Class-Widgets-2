import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import RinUI

Item {
    id: root
    property string pendingThemeId: ""

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: container.implicitHeight
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: container
            width: flickable.width
            spacing: 12

            InfoBar {
                Layout.fillWidth: true
                title: qsTr("Warning")
                text: qsTr("The theme system is still under development. If translations are missing after a theme change, please restart.")
                severity: Severity.Warning
            }

            Text {
                typography: Typography.BodyStrong
                text: qsTr("Accent Color")
            }

            SettingCard {
                Layout.fillWidth: true
                title: qsTr("Accent Color")
                description: qsTr("Pick the color which app highlighted color")
                icon.name: "ic_fluent_paint_brush_20_regular"

                DropDownColorPicker {
                    position: Position.Left
                    color: Utils.primaryColor
                    onColorChanged: Theme.setThemeColor(color)
                }
            }

            Text {
                typography: Typography.BodyStrong
                text: qsTr("Themes")
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: CWThemeManager.themes

                    delegate: Item {
                        id: themeCard
                        width: 200
                        height: 150
                        property int radius: Theme.currentTheme.appearance.buttonRadius
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: themeCard.radius
                            color: modelData.color || Colors.proxy.controlFillColorDefault
                        }

                        Image {
                            id: themeImage
                            anchors.fill: parent
                            source: modelData.preview || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                width: themeImage.width
                                height: themeImage.height
                                maskSource: Rectangle { width: themeImage.width; height: themeImage.height; radius: themeCard.radius }
                            }
                        }

                        Rectangle {
                            id: overlay
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 80
                            radius: themeCard.radius
                            property real highlightedOpacity: hoverHandler.hovered ? 0.5 : 0.4
                            gradient: Gradient {
                                GradientStop { position: 0.6; color: "transparent" }
                                GradientStop { position: 1.0; color: Qt.alpha("black", overlay.highlightedOpacity) }
                            }

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 8
                                spacing: 2

                                Text {
                                    text: modelData.name || ""
                                    typography: Typography.BodyStrong
                                    color: "white"
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                RowLayout {
                                    InfoBadge { severity: Severity.Info; text: qsTr("Built-in"); visible: modelData._type === "builtin"; solid: false }
                                    InfoBadge { severity: Severity.Error; text: qsTr("Incompatible"); visible: !modelData._compatible; solid: false }
                                    Text { text: modelData.author || ""; typography: Typography.Caption; color: "#DDFFFFFF"; elide: Text.ElideRight; maximumLineCount: 1 }
                                }
                            }
                        }

                        HoverHandler { id: hoverHandler }

                        TapHandler {
                            onTapped: {
                                if (modelData._compatible) {
                                    CWThemeManager.themeChange(modelData.id)
                                    if (modelData.color) Theme.setThemeColor(modelData.color)
                                } else {
                                    root.pendingThemeId = modelData.id
                                    incompatibleDialog.open()
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: themeCard.radius
                            color: "transparent"
                            border.width: modelData.id === CWThemeManager.currentTheme ? 3 : 1
                            border.color: modelData.id === CWThemeManager.currentTheme ? Colors.proxy.primaryColor : Colors.proxy.controlSolidColor

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: themeCard.radius
                                color: "transparent"
                                visible: modelData.id === CWThemeManager.currentTheme
                                border.color: Colors.proxy.controlSolidColor
                            }
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: incompatibleDialog
        modal: true
        dim: true
        title: qsTr("Incompatible Theme")
        width: 420

        Text {
            Layout.fillWidth: true
            text: qsTr("This theme may be incompatible with the current app version. Applying it may cause errors or unexpected behavior.")
        }

        footer: DialogButtonBox {
            Button { text: qsTr("Cancel"); highlighted: true; onClicked: incompatibleDialog.close() }
            Button {
                text: qsTr("Apply anyway")
                onClicked: {
                    incompatibleDialog.close()
                    if (root.pendingThemeId) {
                        CWThemeManager.themeChange(root.pendingThemeId)
                        root.pendingThemeId = ""
                    }
                }
            }
        }
    }
}