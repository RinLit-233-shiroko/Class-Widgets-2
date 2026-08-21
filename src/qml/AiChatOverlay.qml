import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent
    z: 5000
    enabled: false
    property bool active: AiChatService.active
    visible: opacity > 0.01
    opacity: active ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: root.active ? 420 : 620; easing.type: Easing.OutCubic }
    }

    // 屏幕四边的连续彩色底光，始终完整覆盖边缘而非仅显示一个小光点。
    Rectangle {
        id: topBand
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 5
        height: 9
        radius: height / 2
        opacity: 0.9
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#39D8F6" }
            GradientStop { position: 0.23; color: "#66F0B6" }
            GradientStop { position: 0.48; color: "#FFF179" }
            GradientStop { position: 0.73; color: "#FF88D8" }
            GradientStop { position: 1.00; color: "#6DA7FF" }
        }
    }
    Rectangle {
        id: rightBand
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 5
        width: 9
        radius: width / 2
        opacity: 0.9
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.00; color: "#6DA7FF" }
            GradientStop { position: 0.24; color: "#FF88D8" }
            GradientStop { position: 0.50; color: "#FFF179" }
            GradientStop { position: 0.76; color: "#66F0B6" }
            GradientStop { position: 1.00; color: "#39D8F6" }
        }
    }
    Rectangle {
        id: bottomBand
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 5
        height: 9
        radius: height / 2
        opacity: 0.9
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: "#39D8F6" }
            GradientStop { position: 0.25; color: "#66F0B6" }
            GradientStop { position: 0.50; color: "#FFF179" }
            GradientStop { position: 0.75; color: "#FF88D8" }
            GradientStop { position: 1.00; color: "#6DA7FF" }
        }
    }
    Rectangle {
        id: leftBand
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 5
        width: 9
        radius: width / 2
        opacity: 0.9
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.00; color: "#39D8F6" }
            GradientStop { position: 0.24; color: "#66F0B6" }
            GradientStop { position: 0.50; color: "#FFF179" }
            GradientStop { position: 0.76; color: "#FF88D8" }
            GradientStop { position: 1.00; color: "#6DA7FF" }
        }
    }

    // 以四条连续移动的高亮段制造绕屏跑马灯效果。
    Item {
        id: topTrack
        anchors.left: topBand.left
        anchors.right: topBand.right
        anchors.verticalCenter: topBand.verticalCenter
        height: 22
        clip: true
        Rectangle {
            id: topRunner
            width: Math.max(210, topTrack.width * 0.16)
            height: 5
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: "#FFFFFF" }
                GradientStop { position: 0.52; color: "#FFF9BC" }
                GradientStop { position: 0.75; color: "#FFFFFF" }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on x {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation { from: -topRunner.width; to: topTrack.width; duration: 2100; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 80 }
            }
        }
    }
    Item {
        id: rightTrack
        anchors.top: rightBand.top
        anchors.bottom: rightBand.bottom
        anchors.horizontalCenter: rightBand.horizontalCenter
        width: 22
        clip: true
        Rectangle {
            id: rightRunner
            width: 5
            height: Math.max(210, rightTrack.height * 0.16)
            anchors.horizontalCenter: parent.horizontalCenter
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: "#FFFFFF" }
                GradientStop { position: 0.52; color: "#FFF9BC" }
                GradientStop { position: 0.75; color: "#FFFFFF" }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on y {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation { from: -rightRunner.height; to: rightTrack.height; duration: 2100; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 140 }
            }
        }
    }
    Item {
        id: bottomTrack
        anchors.left: bottomBand.left
        anchors.right: bottomBand.right
        anchors.verticalCenter: bottomBand.verticalCenter
        height: 22
        clip: true
        Rectangle {
            id: bottomRunner
            width: Math.max(210, bottomTrack.width * 0.16)
            height: 5
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: "#FFFFFF" }
                GradientStop { position: 0.52; color: "#FFF9BC" }
                GradientStop { position: 0.75; color: "#FFFFFF" }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on x {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation { from: bottomTrack.width; to: -bottomRunner.width; duration: 2100; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 220 }
            }
        }
    }
    Item {
        id: leftTrack
        anchors.top: leftBand.top
        anchors.bottom: leftBand.bottom
        anchors.horizontalCenter: leftBand.horizontalCenter
        width: 22
        clip: true
        Rectangle {
            id: leftRunner
            width: 5
            height: Math.max(210, leftTrack.height * 0.16)
            anchors.horizontalCenter: parent.horizontalCenter
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: "#FFFFFF" }
                GradientStop { position: 0.52; color: "#FFF9BC" }
                GradientStop { position: 0.75; color: "#FFFFFF" }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on y {
                running: root.active
                loops: Animation.Infinite
                NumberAnimation { from: leftTrack.height; to: -leftRunner.height; duration: 2100; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 300 }
            }
        }
    }

    // 柔和外发光让深色和浅色壁纸上均可看清完整边界。
    Repeater {
        model: [topBand, rightBand, bottomBand, leftBand]
        delegate: Glow {
            required property var modelData
            anchors.fill: modelData
            source: modelData
            radius: 18
            samples: 25
            color: "#8FEFFB"
            opacity: 0.68
            transparentBorder: true
        }
    }
}
