import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Frame {
    Layout.fillWidth: true
    padding: 24

    property alias source: image.source
    property alias title: titleLabel.text
    property alias description: descriptionLabel.text

    default property alias action: actionLayout.data

    RowLayout {
        anchors.fill: parent
        spacing: 24

        Image {
            id: image
            Layout.alignment: Qt.AlignCenter
            Layout.maximumWidth: 200
            Layout.maximumHeight: 150
            fillMode: Image.PreserveAspectFit
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            id: actionLayout

            Text {
                id: titleLabel
                Layout.fillWidth: true
                typography: Typography.BodyLarge
            }
            Text {
                id: descriptionLabel
                Layout.fillWidth: true
            }
        }
    }
}