import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Item {
    id: root

    property var plugins: []
    property bool loading: false
    property bool showRating: true
    property int placeholderCount: 6
    readonly property int itemWidth: 312
    readonly property int columns: Math.max(1, Math.floor(width / itemWidth))
    readonly property int itemHeight: 96
    readonly property int spacing: 16
    readonly property int itemCount: loading ? placeholderCount : plugins.length
    readonly property int rowCount: itemCount > 0 ? Math.ceil(itemCount / columns) : 0
    readonly property int contentHeight: rowCount > 0 ? rowCount * itemHeight + (rowCount - 1) * spacing : 0

    implicitHeight: contentHeight

    GridLayout {
        width: parent.width
        height: root.contentHeight
        columns: root.columns
        columnSpacing: root.spacing
        rowSpacing: root.spacing

        Repeater {
            model: root.loading ? root.placeholderCount : root.plugins
            delegate: PluginCard {
                Layout.fillWidth: true
                Layout.preferredHeight: root.itemHeight
                plugin: root.loading ? null : modelData
                isLoading: root.loading
                showRating: root.showRating
            }
        }
    }
}
