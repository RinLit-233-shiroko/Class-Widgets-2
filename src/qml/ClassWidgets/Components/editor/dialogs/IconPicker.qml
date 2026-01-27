import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

// IconPicker.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Popup {
    id: popup
    focus: true
    width: 350
    height: 275

    signal iconPicked(string name)

    property var allIcons: Object.keys(Utils.fontIconIndex)
    property string searchText: ""
    property var filteredIcons: allIcons.filter(function(name) {
        return name.toLowerCase().indexOf(searchText.toLowerCase()) !== -1
           && name.toLowerCase().endsWith("_regular")
    })

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        TextField {
            id: searchField
            placeholderText: qsTr("Search icon in English... (e.g. 'run' or 'book')")
            Layout.fillWidth: true
            onTextChanged: searchText = text
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            cellWidth: 48
            cellHeight: 48
            model: filteredIcons

            ScrollBar.vertical: ScrollBar {}

            delegate: ToolButton {
                flat: true
                width: 48
                height: 48
                icon.name: modelData
                onClicked: {
                    popup.iconPicked(modelData)
                    popup.close()
                }

                ToolTip {
                    text: modelData
                    visible: hovered
                    delay: 250
                }
            }
        }
    }
}
