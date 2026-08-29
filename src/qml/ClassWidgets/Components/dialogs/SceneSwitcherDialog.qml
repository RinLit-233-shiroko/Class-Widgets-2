import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Dialog {
    id: sceneDialog
    title: qsTr("Switch Scene")
    standardButtons: Dialog.Close
    modal: true

    property var sceneData: AppCentral.sceneModes.scenes

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: qsTr("Select a scene to switch to")
            wrapMode: Text.Wrap
            typography: Typography.Body
        }

        ListView {
            id: sceneList
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 200)
            spacing: 4
            model: sceneDialog.sceneData
            clip: true

            delegate: Clip {
                width: sceneList.width
                height: 48
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Icon {
                        name: modelData.kind === "exam" ? "ic_fluent_clipboard_task_20_regular" : "ic_fluent_layer_20_regular"
                        size: 20
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        elide: Text.ElideRight
                    }

                    Icon {
                        name: "ic_fluent_checkmark_20_regular"
                        visible: modelData.id === AppCentral.sceneModes.activeSceneId
                        size: 16
                    }
                }

                onClicked: {
                    AppCentral.sceneModes.applyScene(modelData.id)
                    sceneDialog.close()
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }
    }

    onOpened: {
        sceneDialog.sceneData = AppCentral.sceneModes.scenes
    }
}
