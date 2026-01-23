import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    property bool running: true
    property color baseColor: "#E6E6E6"
    property color highlightColor: "#F3F3F3"
    property int radius: 8

    color: baseColor
    border.width: 0
    clip: true
    // radius: root.radius

    Rectangle {
        id: shimmer
        visible: running
        width: parent.width * 0.6
        height: parent.height
        y: 0

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: highlightColor }
            GradientStop { position: 1.0; color: "transparent" }
        }

        x: -width
        opacity: 0.9

        SequentialAnimation on x {
            running: root.running
            loops: Animation.Infinite
            NumberAnimation {
                from: -shimmer.width
                to: root.width
                duration: 1200
                easing.type: Easing.InOutQuad
            }
        }
    }
}
