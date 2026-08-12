import QtQuick
import QtQuick.Layouts
import RinUI

ColumnLayout {
    id: root

    property var plugins: []
    property bool loading: false
    property bool showRating: true
    property int placeholderCount: 4
    property int itemHeight: 96

    spacing: 8

    Repeater {
        model: root.loading ? root.placeholderCount : root.plugins

        delegate: PluginCard {
            Layout.fillWidth: true
            Layout.preferredHeight: root.itemHeight
            plugin: root.loading ? null : modelData
            isLoading: root.loading
            transparent: true
            showRating: root.showRating
            showTags: root.itemHeight >= 110
        }
    }
}
