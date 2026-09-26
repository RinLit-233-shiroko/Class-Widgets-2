import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

RowLayout {
    id: root

    property bool selectionMode: false
    property int selectedCount: 0
    // 当前可选的课程表数量（已按搜索条件过滤），用于判断是否已经全选。
    property int itemCount: 0
    property bool readOnly: false
    property int viewIndex: 0

    // 已选中全部可选项目时，全选按钮切换为取消全选。
    readonly property bool allSelected: itemCount > 0 && selectedCount >= itemCount

    signal searchChanged(string text)
    signal selectionModeRequested(bool enabled)
    signal selectAllRequested(bool select)
    signal duplicateSelected()
    // 批量导出需要先选格式（cw2 / cses），与右键菜单的导出保持一致。
    signal exportSelected(string format)
    signal deleteSelected()
    signal viewIndexRequested(int index)

    TextField {
        Layout.preferredWidth: 220
        placeholderText: qsTr("Search schedules")
        leftPadding: 34
        onTextChanged: root.searchChanged(text)
        Icon {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 10
            anchors.topMargin: 5
            color: Colors.proxy.textSecondaryColor
            // anchors.verticalCenter: parent.verticalCenter
            name: "ic_fluent_search_20_regular"
            size: 16
        }
    }

    Item {
        Layout.fillWidth: true // 分割
    }


    ToolButton {
        visible: root.selectionMode
        enabled: root.itemCount > 0
        flat: true
        icon.name: root.allSelected ? "ic_fluent_select_all_off_20_regular"
                                    : "ic_fluent_select_all_on_20_regular"
        onClicked: root.selectAllRequested(!root.allSelected)

        ToolTip {
            visible: parent.hovered
            text: root.allSelected ? qsTr("Clear selection") : qsTr("Select all")
        }
    }
    ToolSeparator { visible: root.selectionMode; Layout.fillHeight: true }
    ToolButton {
        visible: root.selectionMode
        enabled: root.selectedCount > 0 && !root.readOnly
        flat: true
        icon.name: "ic_fluent_copy_20_regular"
        onClicked: root.duplicateSelected()

        ToolTip {
            visible: parent.hovered
            text: qsTr("Duplicate selected")
        }
    }
    ToolButton {
        visible: root.selectionMode
        enabled: root.selectedCount > 0
        flat: true
        icon.name: "ic_fluent_arrow_export_20_regular"
        // 点击弹出格式菜单，而不是直接导出。
        onClicked: exportMenu.open()

        ToolTip {
            visible: parent.hovered && !exportMenu.opened
            text: qsTr("Export selected")
        }

        Menu {
            id: exportMenu
            // 与右键菜单一致：RinUI 的 Menu 在这里是按钮的子项，
            // Position.Bottom 会以按钮为参照物挂在下方。
            position: Position.Bottom

            MenuItem {
                icon.source: PathManager.images("icons/cw2_editor.png")
                text: qsTr("Class Widgets 2 Schedule")
                onTriggered: root.exportSelected("json")
            }
            MenuItem {
                icon.source: PathManager.images("icons/smart_teach.svg")
                text: qsTr("CSES Schedule Exchange Format")
                onTriggered: root.exportSelected("cses")
            }
        }
    }
    ToolButton {
        visible: root.selectionMode
        enabled: root.selectedCount > 0 && !root.readOnly
        flat: true
        icon.name: "ic_fluent_delete_20_regular"
        onClicked: root.deleteSelected()

        ToolTip {
            visible: parent.hovered
            text: qsTr("Delete selected")
        }
    }
    ToolSeparator { visible: root.selectionMode; Layout.fillHeight: true }
    Button {
        flat: true
        // icon.name: root.selectionMode ? "ic_fluent_dismiss_20_regular" : "ic_fluent_checkbox_checked_20_regular"
        text: root.selectionMode ? qsTr("Cancel") : qsTr("Select")
        onClicked: root.selectionModeRequested(!root.selectionMode)

        ToolTip {
            visible: parent.hovered
            text: root.selectionMode ? qsTr("Cancel") : qsTr("Select")
        }
    }
    ToolSeparator { Layout.fillHeight: true }
    Segmented {
        Layout.alignment: Qt.AlignVCenter
        currentIndex: root.viewIndex
        onCurrentIndexChanged: root.viewIndexRequested(currentIndex)

        SegmentedItem {
            icon.name: "ic_fluent_grid_20_regular"
        }
        SegmentedItem {
            icon.name: "ic_fluent_list_bar_20_regular"
        }
    }
}
