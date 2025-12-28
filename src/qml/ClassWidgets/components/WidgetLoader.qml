import QtQuick
import RinUI


Loader {
    id: loader
    source: model.qmlPath
    asynchronous: true
    anchors.centerIn: parent
    onStatusChanged: {
        if (status === Loader.Ready) {
            if (item && model.backendObj) {
                item.backend = model.backendObj
            }
            if (item && model.settings) {
                item.settings = model.settings
            }
            if (item && item.hasOwnProperty('editMode')) {
                item.editMode = widgetsContainer.editMode
            }
            anim.start()
        }
    }

    Connections {
        target: WidgetsModel
        function onModelChanged() {
            if (loader.item && model.settings) {
                loader.item.settings = model.settings
            }
        }
    }

    Connections {
        target: widgetsContainer
        function onEditModeChanged() {
            if (loader.item && loader.item.hasOwnProperty('editMode')) {
                loader.item.editMode = widgetsContainer.editMode
            }
        }
    }
}