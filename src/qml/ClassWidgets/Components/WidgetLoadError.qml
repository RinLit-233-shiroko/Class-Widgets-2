import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root

    property string widgetName: ""
    property bool editMode: false
    signal removeRequested()
    signal retryRequested()

    opacity: 0
    scale: 0.92
    text: qsTr("Load failed")
    visible: editMode

    Component.onCompleted: appearAnimation.start()

    ParallelAnimation {
        id: appearAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            to: 1
            duration: 180
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "scale"
            to: 1
            duration: 220
            easing.type: Easing.OutBack
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 4

        Button {
            Layout.preferredHeight: 40
            text: qsTr("Remove")
            icon.name: "ic_fluent_delete_20_regular"
            onClicked: root.removeRequested()
        }

        Button {
            Layout.preferredHeight: 40
            icon.name: "ic_fluent_arrow_sync_20_regular"
            onClicked: root.retryRequested()
        }
    }
}
