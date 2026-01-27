import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Item {
    id: root
    property var plugins: []
    property bool loading: false

    // 自适应列数
    readonly property int itemWidth: 300
    readonly property int columns: Math.max(1, Math.floor(width / itemWidth))
    readonly property int itemHeight: 90
    readonly property int spacing: 16

    readonly property int rowCount: Math.ceil((plugins && plugins.length > 0 ? plugins.length : 9) / columns)
    readonly property int contentHeight: rowCount * itemHeight + (rowCount - 1) * spacing

    implicitHeight: contentHeight

    GridLayout {
        width: parent.width
        height: contentHeight
        columns: root.columns
        columnSpacing: spacing
        rowSpacing: spacing

        Repeater {
            model: root.loading ? 9 : root.plugins

            delegate: PluginCard {
                Layout.fillWidth: true
                Layout.preferredHeight: itemHeight
                plugin: !root.loading ? modelData : null
                isLoading: root.loading
            }
        }
    }
}
