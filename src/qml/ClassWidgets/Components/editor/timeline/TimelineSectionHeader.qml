import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

RowLayout {
    id: root

    property string title: ""
    property bool expanded: true
    property var filterModel1: []
    property var filterModel2: []
    property int filterIndex1: 0
    property int filterIndex2: 0

    signal expandedToggled(bool expanded)
    signal filterActivated1(int index, string text)
    signal filterActivated2(int index, string text)

    implicitHeight: 32
    spacing: 4

    Button {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        flat: true
        icon.name: root.expanded
            ? "ic_fluent_chevron_down_20_regular"
            : "ic_fluent_chevron_right_20_regular"
        onClicked: root.expandedToggled(!root.expanded)
    }

    Text {
        text: root.title
        typography: Typography.BodyStrong
    }

    Item { Layout.fillWidth: true }

    ComboBox {
        visible: root.filterModel1.length > 0
        Layout.preferredHeight: 32
        implicitContentWidthPolicy: ComboBox.WidestText
        model: root.filterModel1
        currentIndex: root.filterIndex1
        onActivated: root.filterActivated1(currentIndex, currentText)
    }

    ComboBox {
        visible: root.filterModel2.length > 0
        Layout.preferredHeight: 32
        implicitContentWidthPolicy: ComboBox.WidestText
        model: root.filterModel2
        currentIndex: root.filterIndex2
        onActivated: root.filterActivated2(currentIndex, currentText)
    }
}
