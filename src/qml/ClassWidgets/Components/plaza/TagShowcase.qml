import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import RinUI

ColumnLayout {
    id: root

    property string tagId: ""
    property string title: ""
    property var plugins: []
    property int total: plugins ? plugins.length : 0
    property bool loading: false
    property bool showRating: false

    spacing: 12

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
            Layout.fillWidth: true
            text: root.title
            typography: Typography.BodyLarge
            elide: Text.ElideRight
        }

        ToolButton {
            flat: true
            icon.name: "ic_fluent_chevron_right_20_regular"
            enabled: root.tagId.length > 0
            onClicked: navigationView.push(Qt.resolvedUrl("../../pages/plaza/Plugins.qml"), { initialTag: root.tagId })
            ToolTip.text: qsTr("View all %1 plugins").arg(root.title)
            ToolTip.visible: hovered
        }
    }

    ListView {
        id: cardList
        Layout.fillWidth: true
        Layout.preferredHeight: 224
        orientation: ListView.Horizontal
        spacing: 16
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentWidth > width
        model: root.loading ? 0 : (root.plugins || [])

        ScrollBar.horizontal: ScrollBar {
            policy: ScrollBar.AsNeeded
        }

        delegate: PluginCardRounded {
            required property var modelData
            plugin: modelData
            showRating: root.showRating
        }
    }

    PlazaLoading {
        visible: root.loading
    }
}
