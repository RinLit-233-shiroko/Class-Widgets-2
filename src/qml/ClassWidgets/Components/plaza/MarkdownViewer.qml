import QtQuick
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

Item {
    id: root

    property string html: ""
    property bool loading: false

    signal linkActivated(string link)

    implicitHeight: contentColumn.implicitHeight

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            visible: root.loading

            ProgressRing {
                anchors.centerIn: parent
                size: 38
                indeterminate: true
            }
        }

        TextEdit {
            Layout.fillWidth: true
            visible: !root.loading
            text: root.html
            textFormat: TextEdit.RichText
            wrapMode: TextEdit.Wrap
            readOnly: true
            selectByMouse: true
            cursorVisible: false
            height: contentHeight
            palette.link: Colors.proxy.primaryColor
            color: Colors.proxy.textColor
            selectionColor: Colors.proxy.primaryColor
            onLinkActivated: function(link) {
                root.linkActivated(link)
            }

            font.family: Utils.fontFamily
        }
    }
}
