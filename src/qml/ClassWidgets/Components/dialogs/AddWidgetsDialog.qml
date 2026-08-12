import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import RinUI


Dialog {
    id: addWidgetsDialog
    title: qsTr("Add Widgets")
    modal: true
    standardButtons: Dialog.Close
    width: 600
    height: 500
    property var selectedWidget: widgetsListView.currentIndex >= 0
        ? widgetsListView.model[widgetsListView.currentIndex]
        : null
    property bool themeReloading: false

    Connections {
        target: CWThemeManager
        function onThemeReloadStarted() {
            addWidgetsDialog.themeReloading = true
        }

        function onThemeReadyToReload() {
            addWidgetsDialog.themeReloading = false
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            Layout.preferredWidth: 185
            Layout.maximumWidth: 185
            Layout.fillHeight: true
            // TextField {
            //     id: searchField
            //     placeholderText: qsTr("Search widgets...")
            //     Layout.fillWidth: true
            // }
            ListView {
                id: widgetsListView
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: WidgetsModel.definitionsList
                textRole: "name"
                onModelChanged: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0
                }

                onCountChanged: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0
                }

                Component.onCompleted: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0
                }
                delegate: ListViewDelegate {
                    Layout.fillWidth: true
                    contentItem: RowLayout {
                        spacing: 8

                        Icon {
                            name: "ic_fluent_app_generic_20_regular"
                            size: 22
                        }

                        Text {
                            wrapMode: Text.NoWrap
                            text: modelData.name
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.rightMargin: 12
                        }
                    }
                    ToolTip {
                        text: modelData.name
                        visible: parent.hovered
                        delay: 500
                    }
                }
            }
        }
        ColumnLayout {
            id: widgetInfoLayout
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                Layout.fillWidth: true
            }

            Text {
                Layout.alignment: Qt.AlignTop
                typography: Typography.Subtitle
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.topMargin: 20
                elide: Text.ElideMiddle
                text: addWidgetsDialog.selectedWidget
                    ? addWidgetsDialog.selectedWidget.name
                    : qsTr("No Widget Selected")
            }

            Item {
                Layout.fillHeight: true
            }

            // 动态加载组件样式
            Loader {
                id: widgetLoader
                Layout.alignment: Qt.AlignCenter
                active: addWidgetsDialog.visible
                    && addWidgetsDialog.selectedWidget !== null
                    && !addWidgetsDialog.themeReloading
                source: addWidgetsDialog.selectedWidget
                    ? addWidgetsDialog.selectedWidget.qml_path
                    : ""
                enabled: false // 阻止事件传递

                onItemChanged: {
                    if (item && addWidgetsDialog.selectedWidget) {
                        if (addWidgetsDialog.selectedWidget.backend_obj) {
                            item.backend = addWidgetsDialog.selectedWidget.backend_obj
                        }
                        if (addWidgetsDialog.selectedWidget.default_settings) {
                            item.settings = addWidgetsDialog.selectedWidget.default_settings
                        }
                        Qt.callLater(function() {
                            if (widgetLoader.item)
                                anim.start()
                        })
                    }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.alpha("black", 0.2)
                    shadowBlur: 1
                    shadowVerticalOffset: 4
                }

                ParallelAnimation {
                    id: anim
                    NumberAnimation {
                        target: widgetLoader
                        property: "opacity"
                        from: 0; to: 1; duration: 300
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: widgetLoader;
                        property: "scale";
                        from: 0.8; to: 1; duration: 400;
                        easing.type: Easing.OutBack
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                icon.name: "ic_fluent_add_20_regular"
                text: qsTr("Add")
                highlighted: true
                enabled: addWidgetsDialog.selectedWidget !== null
                onClicked: {
                    //添加
                    WidgetsModel.addInstance(addWidgetsDialog.selectedWidget.id)
                    addWidgetsDialog.close()
                }
            }
        }
    }
}
