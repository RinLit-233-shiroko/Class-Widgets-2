import QtQuick
import QtQuick.Layouts
import RinUI

Item {
    id: root

    property string title: qsTr("Unable to load content")
    property string description: ""
    property string retryText: qsTr("Retry")
    property bool retryVisible: true
    signal retryRequested()

    implicitHeight: 210

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, 460)
        spacing: 10

        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "ic_fluent_error_circle_24_regular"
            size: 34
            color: Colors.proxy.systemCriticalColor
        }

        Text {
            Layout.fillWidth: true
            text: root.title
            typography: Typography.BodyStrong
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

        Button {
            Layout.alignment: Qt.AlignHCenter
            text: root.retryText
            icon.name: "ic_fluent_arrow_clockwise_20_regular"
            visible: root.retryVisible
            onClicked: root.retryRequested()
        }
    }
}
