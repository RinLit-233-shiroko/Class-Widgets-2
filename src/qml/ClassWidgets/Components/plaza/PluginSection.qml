import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import RinUI

Frame {
    id: root

    /* ========= Public API ========= */
    property string title: ""
    property var plugins: []
    property bool loading: false
    property int pageSize: 6
    property bool showHeader: true
    property bool showControls: true

    /* ========= Paging ========= */
    property int currentPage: 0

    readonly property int totalCount: plugins.length
    readonly property bool canPrev: currentPage > 0
    readonly property bool canNext: (currentPage + 1) * pageSize < totalCount

    /* ========= Derived ========= */
    function visiblePlugins() {
        if (!plugins || plugins.length === 0)
            return []
        const start = currentPage * pageSize
        return plugins.slice(start, start + pageSize)
    }

    onPluginsChanged: currentPage = 0

    /* ========= Frame styling ========= */
    padding: 16
    // radius: 16
    // background: Rectangle {
    //     radius: root.radius
    //     color: Colors.proxy.backgroundColor
    //     border.color: Colors.proxy.controlBorderColor
    //     border.width: 1
    // }

    /* ========= Layout ========= */
    ColumnLayout {
        id: layoutRoot
        width: parent.width
        spacing: 12

        /* ===== Header / Toolbar ===== */
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: root.showHeader

            Text {
                Layout.fillWidth: true
                text: root.title
                typography: Typography.BodyLarge
            }

            Item { Layout.fillWidth: true }

            ToolButton {
                visible: root.showControls
                flat: true
                enabled: canPrev
                icon.name: "ic_fluent_chevron_left_20_regular"
                onClicked: currentPage = Math.max(0, currentPage - 1)
            }

            ToolButton {
                visible: root.showControls
                flat: true
                enabled: canNext
                icon.name: "ic_fluent_chevron_right_20_regular"
                onClicked: {
                    if (canNext) currentPage++
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: root.showHeader
            color: Colors.proxy.controlBorderColor
        }

        /* ===== Content ===== */
        GridLayout {
            Layout.fillWidth: true
            
            // 自适应列数
            property int itemWidth: 300
            columns: Math.max(1, Math.floor(width / itemWidth))
            
            columnSpacing: 16
            rowSpacing: 16

            Repeater {
                model: loading ? 6 : visiblePlugins()

                delegate: PluginCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 90
                    plugin: !loading ? modelData : null
                    isLoading: loading
                }
            }
        }
    }
}
