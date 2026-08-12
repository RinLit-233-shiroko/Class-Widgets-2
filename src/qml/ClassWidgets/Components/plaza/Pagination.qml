import QtQuick
import QtQuick.Layouts
import RinUI

RowLayout {
    id: root

    property int currentPage: 1
    property int totalPages: 1
    signal pageRequested(int page)

    spacing: 8

    ToolButton {
        flat: true
        icon.name: "ic_fluent_chevron_left_20_regular"
        enabled: root.currentPage > 1
        onClicked: root.pageRequested(root.currentPage - 1)
        ToolTip { text: qsTr("Previous page"); visible: parent.hovered }
    }

    Text {
        text: qsTr("Page %1 of %2").arg(root.currentPage).arg(root.totalPages)
        typography: Typography.Caption
    }

    ToolButton {
        flat: true
        icon.name: "ic_fluent_chevron_right_20_regular"
        enabled: root.currentPage < root.totalPages
        onClicked: root.pageRequested(root.currentPage + 1)
        ToolTip { text: qsTr("Next page"); visible: parent.hovered }
    }
}
