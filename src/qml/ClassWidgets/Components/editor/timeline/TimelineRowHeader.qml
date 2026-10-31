import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

Item {
    id: root

    property var timeline: ({})
    property string title: ""
    property string rule: ""
    property bool expanded: false
    property bool compactLayout: false

    signal collapseRequested()
    signal editRulesRequested(var timeline)
    signal deleteRequested(var timeline)
    signal duplicateRequested(string dayId)

    height: 32

    Button {
        id: collapseButton
        visible: root.expanded
        z: 20
        flat: true
        icon.name: "ic_fluent_dismiss_20_regular"
        width: 32
        height: 32
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        onClicked: root.collapseRequested()
    }

    Row {
        id: headingGroup
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: actionGroup.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        transform: Translate {
            x: root.expanded ? collapseButton.width + 8 : 0
            Behavior on x {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: titleLabel
            width: Math.max(1, Math.min(
                implicitWidth,
                headingGroup.width - ruleBadge.width - headingGroup.spacing
            ))
            height: 20
            text: root.title
            typography: Typography.BodyStrong
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.NoWrap
            maximumLineCount: 1
        }
        Rectangle {
            id: ruleBadge
            width: ruleLabel.implicitWidth + 12
            height: ruleLabel.implicitHeight + 2
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.alpha(Colors.proxy.systemNeutralColor, 0.1)
            border.width: 1
            border.color: Qt.alpha(Colors.proxy.textColor, 0.02)
            Text {
                id: ruleLabel
                anchors.centerIn: parent
                text: root.rule
                font.pixelSize: 12
                color: Colors.proxy.textColor
            }
        }
    }

    RowLayout {
        id: actionGroup
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Button {
            visible: root.expanded
            Layout.minimumWidth: root.compactLayout ? 40 : 132
            Layout.preferredWidth: root.compactLayout ? 40 : 132
            flat: true
            icon.name: "ic_fluent_edit_20_regular"
            text: root.compactLayout ? "" : qsTr("Adjust rules")
            onClicked: root.editRulesRequested(root.timeline)
            ToolTip {
                text: qsTr("Adjust rules")
                visible: root.compactLayout && parent.hovered
            }
        }
        ToolSeparator { visible: root.expanded; height: 32 }
        Button {
            visible: root.expanded
            flat: true
            icon.name: "ic_fluent_document_copy_20_regular"
            onClicked: root.duplicateRequested(root.timeline.id)
        }
        Button {
            visible: root.expanded
            flat: true
            icon.name: "ic_fluent_delete_20_regular"
            onClicked: root.deleteRequested(root.timeline)
        }
        Button {
            id: moreActionsButton
            visible: !root.expanded
            Layout.maximumWidth: root.compactLayout ? 40 : 999
            z: 2
            flat: true
            icon.name: "ic_fluent_more_vertical_20_regular"
            onClicked: actionsMenu.open()

            ToolTip {
                text: qsTr("More actions")
                visible: parent.hovered
                delay: 250
            }

            Menu {
                id: actionsMenu
                position: Position.Bottom
                MenuItem {
                    text: qsTr("Adjust rules")
                    icon.name: "ic_fluent_edit_20_regular"
                    onTriggered: root.editRulesRequested(root.timeline)
                }
                MenuItem {
                    text: qsTr("Duplicate")
                    icon.name: "ic_fluent_document_copy_20_regular"
                    onTriggered: root.duplicateRequested(root.timeline.id)
                }
                MenuItem {
                    text: qsTr("Delete")
                    icon.name: "ic_fluent_delete_20_regular"
                    onTriggered: root.deleteRequested(root.timeline)
                }
            }
        }
    }
}
