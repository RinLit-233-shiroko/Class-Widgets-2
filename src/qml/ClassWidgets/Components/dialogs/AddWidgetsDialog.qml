import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import RinUI
import ClassWidgets.Easing


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
    property string widgetSource: ""

    onSelectedWidgetChanged: {
        // 切换时先清空再延迟加载，参考 WidgetLoader 的 cacheBuster 机制
        widgetSource = ""
        if (selectedWidget) {
            Qt.callLater(function() {
                addWidgetsDialog.widgetSource = addWidgetsDialog.selectedWidget.qml_path + "?t=" + Date.now()
            })
        }
    }

    onVisibleChanged: {
        if (visible && selectedWidget) {
            // 重新打开 Dialog 时强制刷新
            widgetSource = ""
            Qt.callLater(function() {
                addWidgetsDialog.widgetSource = addWidgetsDialog.selectedWidget.qml_path + "?t=" + Date.now()
            })
        }
    }

    Connections {
        target: CWThemeManager
        function onThemeReloadStarted() {
            addWidgetsDialog.themeReloading = true
        }

        function onThemeReadyToReload() {
            addWidgetsDialog.themeReloading = false
            // 主题重载后强制刷新，参考 WidgetLoader 的实现
            if (addWidgetsDialog.selectedWidget) {
                var oldSource = widgetSource.toString()
                widgetSource = ""
                Qt.callLater(function() {
                    var cacheBuster = (oldSource.indexOf("?") >= 0 ? "&" : "?") + "t=" + Date.now()
                    addWidgetsDialog.widgetSource = oldSource.split("?")[0] + cacheBuster
                })
            }
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
                // text: widgetLoader.status
                text: addWidgetsDialog.selectedWidget
                    ? addWidgetsDialog.selectedWidget.name
                    : qsTr("No Widget Selected")
            }

            Item {
                Layout.fillHeight: true
            }

            // 动态加载组件样式（外层容器负责阴影和居中）
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignCenter

                // 外层容器应用阴影，避免与 Widget 内部的 layer 嵌套冲突
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.alpha("black", 0.2)
                    shadowBlur: 1
                    shadowVerticalOffset: 4
                }

                Loader {
                    id: widgetLoader
                    anchors.centerIn: parent
                    width: item ? item.implicitWidth : 0
                    height: item ? item.height : 0
                    source: widgetSource
                    active: addWidgetsDialog.visible
                        && addWidgetsDialog.selectedWidget !== null
                        && !addWidgetsDialog.themeReloading
                    enabled: false // 阻止事件传递
                    asynchronous: true

                    onStatusChanged: {
                        if (status === Loader.Ready) {
                            if (item && addWidgetsDialog.selectedWidget) {
                                if (addWidgetsDialog.selectedWidget.backend_obj) {
                                    item.backend = addWidgetsDialog.selectedWidget.backend_obj
                                }
                                if (addWidgetsDialog.selectedWidget.default_settings) {
                                    item.settings = addWidgetsDialog.selectedWidget.default_settings
                                }
                                if (item.hasOwnProperty('widget_id')) {
                                    item.widget_id = addWidgetsDialog.selectedWidget.id
                                }
                                anim.start()
                            }
                        } else if (status === Loader.Error) {
                            console.error("AddWidgetsDialog: Failed to load widget preview:",
                                addWidgetsDialog.selectedWidget ? addWidgetsDialog.selectedWidget.name : "null")
                        }
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
                            easing.type: Easing.Bezier
                            easing.bezierCurve: BezierCurve.popBack
                        }
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
