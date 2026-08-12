import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Theme 1.0

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
            duration: (label.width + marquee.width) * 1000 / Math.max(1, marquee.speed);
            running: false
        }
    }

    Component.onCompleted: restart();
    onRunningChanged: restart();
    onSpeedChanged: restart();
    onWidthChanged: restart();

    Connections {
        target: label;
        function onWidthChanged() { restart(); }
        function onTextChanged() { restart(); }
    }

    // 只有内容超出可视宽度时才滚动；内容放得下时静止显示
    function restart() {
        scrollAnim.stop();
        finished();

        // 未启用滚动，或内容宽度不超过可视宽度：静止显示，无需滚动
        if (!running || label.width <= marquee.width) {
            label.x = Math.max(0, (marquee.width - label.width) / 2);
            return;
        }

        // 内容超宽：从右侧循环滚动到左侧
        label.x = marquee.width;
        scrollAnim.restart();
    }
}
