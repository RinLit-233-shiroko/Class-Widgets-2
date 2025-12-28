import QtQuick
import QtQuick.Controls
import RinUI
import Widgets

Item {
    id: marquee
    property int maximumWidth: 200
    implicitWidth: Math.min(label.implicitWidth, maximumWidth)
    height: label.height
    clip: true

    property alias text: label.text
    property alias font: label.font
    property alias color: label.color
    property int speed: 50
    property bool running: true
    signal finished()

    Title {
        id: label
        anchors.verticalCenter: parent.verticalCenter

        NumberAnimation on x {
            id: scrollAnim
            loops: Animation.Infinite
            from: marquee.width
            to: -label.width
            duration: (label.width + marquee.width) * 1000 / Math.max(1, marquee.speed)
            running: false
        }
    }

    Component.onCompleted: restart()
    onRunningChanged: restart()
    onSpeedChanged: restart()
    onWidthChanged: restart()   // ✅ 关键修复点

    Connections {
        target: label
        function onWidthChanged() { restart() }
        function onTextChanged()  { restart() }
    }

    function restart() {
        scrollAnim.stop()
        finished()

        if (!running) return

        if (label.implicitWidth <= marquee.width) {
            label.x = (marquee.width - label.width) / 2
            return
        }

        scrollAnim.from = marquee.width
        scrollAnim.to   = -label.width
        scrollAnim.duration =
            (label.width + marquee.width) * 1000 / Math.max(1, marquee.speed)

        label.x = marquee.width
        scrollAnim.start()
    }
}
