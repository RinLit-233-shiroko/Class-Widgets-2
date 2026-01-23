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
                delegate: ListViewDelegate {
                    Layout.fillWidth: true
                    leftArea: Icon {
                        icon: "ic_fluent_app_generic_20_regular"
                        size: 22
                    }
                    middleArea: [
                        Text {
                            wrapMode: Text.NoWrap
                            text: modelData.name
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.rightMargin: 12
                        }
                    ]
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
            property var model: widgetsListView.model[widgetsListView.currentIndex]

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
                text: widgetInfoLayout.model.name || qsTr("No Widget Selected")
            }

            Item {
                Layout.fillHeight: true
            }

            // 动态加载组件样式
            Loader {
                id: widgetLoader
                Layout.alignment: Qt.AlignCenter
                source: widgetsListView.currentIndex >= 0
                ? widgetInfoLayout.model.qml_path
                : ""
                enabled: false // 阻止事件传递

                onItemChanged: {
                    if (item) {
                        if (widgetInfoLayout.model.backend_obj) {
                            item.backend = widgetInfoLayout.model.backend_obj
                        }
                        if (widgetInfoLayout.model.default_settings) {
                            item.settings = widgetInfoLayout.model.default_settings
                        }
                        Qt.callLater(function() {
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
                onClicked: {
                    //添加
                    WidgetsModel.addInstance(widgetsListView.model[widgetsListView.currentIndex].id)
                    addWidgetsDialog.close()
                }
            }
        }
    }
}
