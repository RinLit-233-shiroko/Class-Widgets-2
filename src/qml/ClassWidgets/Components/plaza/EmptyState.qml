import QtQuick
import QtQuick.Layouts
import RinUI

Item {
    id: root

    property string iconName: "ic_fluent_box_24_regular"
    property string title: qsTr("Nothing here yet")
    property string description: ""

    Layout.fillHeight: true
    implicitHeight: 180

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, 420)
        spacing: 8
        opacity: 0.5

        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: root.iconName
            size: 46
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            typography: Typography.BodyLarge
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            typography: Typography.Caption
            color: Colors.proxy.textSecondaryColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: text.length > 0
        }
    }
}
