import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 24

        Item { Layout.preferredHeight: Math.max(0, (root.height - 260) / 2) }

        Icon {
            Layout.alignment: Qt.AlignHCenter
            size: 88
            source: PathManager.images("logo.png")
        }

        Text {
            Layout.fillWidth: true
            typography: Typography.Subtitle
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Ready to use Class Widgets")
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Your preferences and initial subjects are ready. Click the button below to start.")
            wrapMode: Text.WordWrap
        }

        Item { Layout.preferredHeight: Math.max(0, (root.height - 260) / 2) }
    }
}