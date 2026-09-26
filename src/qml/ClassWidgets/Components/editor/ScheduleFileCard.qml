import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

// 编辑器首页网格布局使用的课程表文件卡片。
Rectangle {
    id: root

    property string filename: ""
    property string modifiedAt: ""
    property bool selected: false
    property bool selectionMode: false

    property int relativeTimeTick: 0

    function formatModifiedAt(value, tick) {
        const date = new Date(value)
        if (!value || isNaN(date.getTime()))
            return value || qsTr("Edited at unknown time")

        const elapsedSeconds = Math.max(0, (Date.now() - date.getTime()) / 1000)
        if (elapsedSeconds < 60)
            return qsTr("Edited just now")
        if (elapsedSeconds < 3600)
            return qsTr("Edited %1 minutes ago").arg(Math.floor(elapsedSeconds / 60))
        if (elapsedSeconds < 86400)
            return qsTr("Edited %1 hours ago").arg(Math.floor(elapsedSeconds / 3600))
        if (elapsedSeconds < 604800)
            return qsTr("Edited %1 days ago").arg(Math.floor(elapsedSeconds / 86400))
        if (elapsedSeconds < 2592000)
            return qsTr("Edited %1 weeks ago").arg(Math.floor(elapsedSeconds / 604800))
        if (elapsedSeconds < 31536000)
            return qsTr("Edited %1 months ago").arg(Math.floor(elapsedSeconds / 2592000))
        return qsTr("Edited at %1").arg(Qt.formatDate(date, Qt.locale().dateFormat(Locale.ShortFormat)))
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: root.relativeTimeTick++
    }
    signal clicked()
    signal selectionToggled()
    signal contextMenuRequested(real mouseX, real mouseY)

    implicitWidth: 112
    implicitHeight: 112
    radius: 4
    color: hoverHandler.hovered ? Qt.rgba(Colors.proxy.textColor.r,
                                           Colors.proxy.textColor.g,
                                           Colors.proxy.textColor.b, 0.04)
                                 : "transparent"
    border.width: selected || hoverHandler.hovered ? 1 : 0
    border.color: selected ? Colors.proxy.primaryColor : Colors.proxy.controlBorderColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 4

        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "ic_fluent_calendar_clock_20_regular"
            size: 32
            color: root.selected ? Colors.proxy.primaryColor : Colors.proxy.textColor
        }
        Text {
            Layout.fillWidth: true
            text: root.filename
            typography: Typography.Caption
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 12
            maximumLineCount: 1
            elide: Text.ElideRight
            // elide: Text.ElideMiddle
        }
        Text {
            Layout.fillWidth: true
            text: root.formatModifiedAt(root.modifiedAt, root.relativeTimeTick)
            typography: Typography.Caption
            font.pixelSize: 9
            color: Colors.proxy.textSecondaryColor
            maximumLineCount: 1
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }

    CheckBox {
        id: selectionCheckBox
        visible: root.selectionMode
        checked: root.selected
        onClicked: root.selectionToggled()
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 6
    }

    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.selectionMode ? root.selectionToggled() : root.clicked() }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: root.contextMenuRequested(point.position.x, point.position.y) }
    HoverHandler { id: hoverHandler }
}
