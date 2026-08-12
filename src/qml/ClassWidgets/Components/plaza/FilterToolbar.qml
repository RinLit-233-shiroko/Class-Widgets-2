import QtQuick
import QtQuick.Layouts
import RinUI

RowLayout {
    id: root

    property var tags: []
    property string selectedTag: ""
    property string sortValue: "latest"
    property bool showRelevance: false
    property bool busy: false
    signal tagSelected(string tagId)
    signal sortSelected(string sortValue)

    spacing: 8

    // 标签筛选（原 TagPills 组件内联，此处为唯一使用方）
    Segmented {
        enabled: !root.busy

        SegmentedItem {
            text: qsTr("All")
            checked: root.selectedTag === ""
            onClicked: root.tagSelected("")
        }

        Repeater {
            model: root.tags instanceof Array ? root.tags.slice(0, 5) : []

            delegate: SegmentedItem {
                required property var modelData
                readonly property string tagId: modelData.id || modelData.name || ""
                text: modelData.name || modelData.id || ""
                checked: root.selectedTag === tagId
                onClicked: root.tagSelected(tagId)
            }
        }
    }

    Item { Layout.fillWidth: true }

    DropDownButton {
        Layout.alignment: Qt.AlignRight
        enabled: !root.busy
        text: root.sortValue === "relevance" ? qsTr("Relevance")
            : root.sortValue === "name" ? qsTr("Name")
            : root.sortValue === "rating" ? qsTr("Rating")
            : root.sortValue === "downloads" ? qsTr("Downloads")
            : qsTr("Latest")
        icon.name: "ic_fluent_arrow_sort_20_regular"

        MenuItem { visible: root.showRelevance; text: qsTr("Relevance"); onTriggered: root.sortSelected("relevance") }
        MenuItem { text: qsTr("Latest"); onTriggered: root.sortSelected("latest") }
        MenuItem { text: qsTr("Name"); onTriggered: root.sortSelected("name") }
        MenuItem { text: qsTr("Rating"); onTriggered: root.sortSelected("rating") }
        MenuItem { text: qsTr("Downloads"); onTriggered: root.sortSelected("downloads") }
    }
}
