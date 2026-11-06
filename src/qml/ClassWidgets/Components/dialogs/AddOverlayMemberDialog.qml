import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import RinUI

Dialog {
    id: overlayMemberDialog
    title: qsTr("Add Widgets to Overlay")
    modal: true
    standardButtons: Dialog.Close
    width: 600
    height: 500

    property var overlayBackend: null
    property string overlayInstanceId: ""

    property var defs: {
        if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
            var list = []
            var raw = WidgetsModel.definitionsList
            for (var i = 0; i < raw.length; i++) {
                if (raw[i].id === "classwidgets.overlay"
                        || raw[i].id === "classwidgets.dynamicNotification")
                    continue
                list.push(raw[i])
            }
            return list
        }
        return []
    }

    property var selectedWidget: widgetsListView.currentIndex >= 0
        ? widgetsListView.model[widgetsListView.currentIndex]
        : null

    Component.onCompleted: {
        standardButton(Dialog.Close).text = qsTr("Close")
    }

    onOpened: {
        if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
            for (var i = 0; i < WidgetsModel.definitionsList.length; i++) {
                if (WidgetsModel.definitionsList[i].id === "classwidgets.overlay") {
                    overlayBackend = WidgetsModel.definitionsList[i].backend_obj
                    break
                }
            }
        }
        if (widgetsListView.currentIndex < 0 && widgetsListView.count > 0)
            widgetsListView.currentIndex = 0
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            Layout.preferredWidth: 185
            Layout.maximumWidth: 185
            Layout.fillHeight: true

            ListView {
                id: widgetsListView
                clip: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: overlayMemberDialog.defs
                textRole: "name"
                onModelChanged: {
                    if (count > 0 && currentIndex < 0)
                        currentIndex = 0
                }
                onCountChanged: {
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
                text: overlayMemberDialog.selectedWidget
                    ? overlayMemberDialog.selectedWidget.name
                    : qsTr("No Widget Selected")
            }

            Item {
                Layout.fillHeight: true
            }

            Loader {
                id: widgetLoader
                Layout.alignment: Qt.AlignCenter
                active: overlayMemberDialog.visible
                    && overlayMemberDialog.selectedWidget !== null
                source: overlayMemberDialog.selectedWidget
                    ? overlayMemberDialog.selectedWidget.qml_path
                    : ""
                enabled: false

                onItemChanged: {
                    if (item && overlayMemberDialog.selectedWidget) {
                        if (overlayMemberDialog.selectedWidget.backend_obj) {
                            item.backend = overlayMemberDialog.selectedWidget.backend_obj
                        }
                        if (overlayMemberDialog.selectedWidget.default_settings) {
                            item.settings = overlayMemberDialog.selectedWidget.default_settings
                        }
                        if (item.hasOwnProperty('widget_id')) {
                            item.widget_id = overlayMemberDialog.selectedWidget.id
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
                enabled: overlayMemberDialog.selectedWidget !== null
                onClicked: {
                    if (overlayMemberDialog.overlayBackend
                            && overlayMemberDialog.selectedWidget) {
                        overlayMemberDialog.overlayBackend.addMember(
                            overlayMemberDialog.overlayInstanceId,
                            overlayMemberDialog.selectedWidget.id)
                    }
                    overlayMemberDialog.close()
                }
            }
        }
    }
}
