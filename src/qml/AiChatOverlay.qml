import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

Item {
    id: root
    anchors.fill: parent
    z: 5000
    enabled: false
    visible: AiChatService.active
    opacity: visible ? 1 : 0

    property color accent: "#66D9FF"
    property color accentSecondary: "#A78BFA"

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    // 四个边缘使用同一套流光语义；仅绘制极窄线条，不遮挡桌面或 Widget。
    Item {
        id: topTrack
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 5
        clip: true

        Rectangle {
            id: topGlow
            width: Math.max(160, topTrack.width * 0.22)
            height: topTrack.height
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: Qt.alpha(root.accent, 0.12) }
                GradientStop { position: 0.5; color: root.accent }
                GradientStop { position: 0.72; color: Qt.alpha(root.accentSecondary, 0.65) }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on x {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { from: -topGlow.width; to: topTrack.width; duration: 1850; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 120 }
            }
        }
    }

    Item {
        id: rightTrack
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 5
        clip: true

        Rectangle {
            id: rightGlow
            width: rightTrack.width
            height: Math.max(160, rightTrack.height * 0.22)
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: Qt.alpha(root.accentSecondary, 0.16) }
                GradientStop { position: 0.52; color: root.accentSecondary }
                GradientStop { position: 0.74; color: Qt.alpha(root.accent, 0.66) }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on y {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { from: -rightGlow.height; to: rightTrack.height; duration: 1850; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 240 }
            }
        }
    }

    Item {
        id: bottomTrack
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 5
        clip: true

        Rectangle {
            id: bottomGlow
            width: Math.max(160, bottomTrack.width * 0.22)
            height: bottomTrack.height
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: Qt.alpha(root.accentSecondary, 0.12) }
                GradientStop { position: 0.5; color: root.accentSecondary }
                GradientStop { position: 0.72; color: Qt.alpha(root.accent, 0.65) }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on x {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { from: bottomTrack.width; to: -bottomGlow.width; duration: 1850; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 360 }
            }
        }
    }

    Item {
        id: leftTrack
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 5
        clip: true

        Rectangle {
            id: leftGlow
            width: leftTrack.width
            height: Math.max(160, leftTrack.height * 0.22)
            radius: width / 2
            gradient: Gradient {
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.28; color: Qt.alpha(root.accent, 0.16) }
                GradientStop { position: 0.52; color: root.accent }
                GradientStop { position: 0.74; color: Qt.alpha(root.accentSecondary, 0.66) }
                GradientStop { position: 1; color: "transparent" }
            }
            SequentialAnimation on y {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { from: leftTrack.height; to: -leftGlow.height; duration: 1850; easing.type: Easing.InOutSine }
                PauseAnimation { duration: 480 }
            }
        }
    }

    // 低透明度外发光使屏幕边界在深浅主题下都易于察觉。
    DropShadow {
        anchors.fill: parent
        source: root
        visible: false
    }
}
