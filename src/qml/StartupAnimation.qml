import QtQuick
import QtQuick.Window
import QtMultimedia
import Qt5Compat.GraphicalEffects

Window {
    id: root
    visible: true
    width: 520
    height: 330
    minimumWidth: 520
    maximumWidth: 520
    minimumHeight: 330
    maximumHeight: 330
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + (Screen.height - height) / 2
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window | Qt.WindowStaysOnTopHint
    title: previewMode ? qsTr("启动动画预览") : "Class Widgets"

    property bool previewMode: StartupAnimationPreview
    property bool customMedia: StartupAnimationController.hasCustomMedia
    property bool showInfo: !customMedia || Configs.data.app.startup_animation_show_info
    property bool detailsReady: false
    property bool videoMode: customMedia && StartupAnimationController.mediaType === "video"
    property bool forceCompleteVideo: videoMode && Configs.data.app.startup_animation_force_video_completion

    function finish() {
        if (!fadeOut.running)
            fadeOut.start()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 22
        color: "#f9fbffff"
        border.width: 1
        border.color: "#d9e1e8"
        opacity: 0
        scale: 0.96

        Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutBack } }

        Rectangle {
            id: mediaSurface
            anchors.fill: parent
            radius: parent.radius
            color: "#041720"
            visible: root.customMedia
            clip: true
            layer.enabled: visible
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: mediaSurface.width
                    height: mediaSurface.height
                    radius: mediaSurface.radius
                    color: "white"
                }
            }

            Image {
                anchors.fill: parent
                source: root.videoMode ? "" : StartupAnimationController.mediaUrl
                visible: root.customMedia && !root.videoMode
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Loader {
                anchors.fill: parent
                active: root.videoMode
                visible: root.videoMode

                sourceComponent: Component {
                    Item {
                        anchors.fill: parent

                        MediaPlayer {
                            id: mediaPlayer
                            source: StartupAnimationController.mediaUrl
                            videoOutput: videoOutput
                            audioOutput: AudioOutput { muted: true }
                            onMediaStatusChanged: {
                                if (mediaStatus === MediaPlayer.EndOfMedia || mediaStatus === MediaPlayer.InvalidMedia)
                                    root.finish()
                            }
                            Component.onCompleted: play()
                        }

                        VideoOutput {
                            id: videoOutput
                            anchors.fill: parent
                            fillMode: VideoOutput.PreserveAspectCrop
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: root.showInfo ? "#10202b55" : "#10202b10"
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: root.customMedia ? 1 : 0
            border.color: "#ffffff77"
        }

        Column {
            id: brandColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.customMedia && !root.showInfo ? 220 : 45
            width: parent.width - 72
            spacing: 13
            visible: root.showInfo
            opacity: root.showInfo ? 1 : 0

            Behavior on anchors.topMargin { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Image {
                id: logo
                anchors.horizontalCenter: parent.horizontalCenter
                width: 68
                height: 68
                source: PathManager.assets("images/logo.png")
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: card.opacity
            }

            Item {
                id: titleRow
                width: parent.width
                height: 36

                Text {
                    id: appName
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.detailsReady ? titleRow.width / 2 - width - 8 : (titleRow.width - width) / 2
                    text: "ClassWidgets"
                    color: root.customMedia ? "white" : "#16242d"
                    font.pixelSize: 27
                    font.weight: Font.DemiBold
                    Behavior on x { NumberAnimation { duration: 560; easing.type: Easing.InOutCubic } }
                }

                Text {
                    id: appVersion
                    anchors.verticalCenter: parent.verticalCenter
                    x: titleRow.width / 2 + 8
                    text: "v" + Configs.data.app.version
                    color: root.customMedia ? "#e9f4f8" : "#5d707d"
                    font.pixelSize: 15
                    opacity: root.detailsReady ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                }
            }
        }

        Item {
            id: loaderArea
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 43
            width: 44
            height: 44

            Rectangle {
                anchors.centerIn: parent
                width: 36
                height: 36
                radius: 18
                color: "transparent"
                border.width: 3
                border.color: root.customMedia ? "#ffffff77" : "#dbe7ed"
            }

            Rectangle {
                id: orbit
                width: 7
                height: 7
                radius: 4
                color: root.customMedia ? "#ffffff" : "#4099b2"
                x: parent.width / 2 - width / 2
                y: 0

                transform: Rotation {
                    id: orbitRotation
                    origin.x: orbit.width / 2
                    origin.y: orbit.parent.height / 2
                    angle: 0
                }
            }

            RotationAnimation {
                target: orbitRotation
                property: "angle"
                from: 0
                to: 360
                duration: 1150
                loops: Animation.Infinite
                running: true
            }
        }
    }

    Timer {
        id: revealTimer
        interval: 760
        repeat: false
        onTriggered: root.detailsReady = true
    }

    Timer {
        id: defaultCloseTimer
        interval: root.videoMode ? 10000 : (root.customMedia ? 3600 : 3100)
        repeat: false
        running: !root.forceCompleteVideo
        onTriggered: root.finish()
    }

    SequentialAnimation {
        id: fadeOut
        NumberAnimation { target: card; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic }
        ScriptAction { script: StartupAnimationController.finish() }
    }

    Component.onCompleted: {
        card.opacity = 1
        card.scale = 1
        revealTimer.start()
        if (!root.forceCompleteVideo)
            defaultCloseTimer.start()
    }
}
