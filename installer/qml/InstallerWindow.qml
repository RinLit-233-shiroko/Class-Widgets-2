import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root
    visible: true
    width: 800
    height: 600
    minimumWidth: 800
    minimumHeight: 600
    x: Screen.virtualX + (Screen.width - width) / 2
    y: Screen.virtualY + (Screen.height - height) / 2
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.Window
    title: "Class Widgets 2 Installer"

    property int currentPage: 0 // 0 welcome, 1 location, 2 installing, 3 complete
    property bool welcomePlayed: false
    property bool completionPlayed: false
    property string installPath: InstallerBridge.defaultInstallPath
    property color accent: "#4299e1"
    property color accentSoft: "#e4f3ff"
    property color ink: "#16242d"
    property color muted: "#6f8290"

    onClosing: function(close) {
        close.accepted = !InstallerBridge.installing
    }

    function goToLocation() {
        currentPage = 1
    }

    function beginInstallation() {
        if (pathInput.text.trim().length === 0)
            return
        installPath = pathInput.text.trim()
        currentPage = 2
        InstallerBridge.install(installPath)
    }

    function selectFolder() {
        const chosen = InstallerBridge.chooseInstallPath(pathInput.text)
        if (chosen.length > 0) {
            installPath = chosen
            pathInput.text = chosen
        }
    }

    Rectangle {
        id: stage
        anchors.fill: parent
        radius: 22
        clip: true
        color: "#f9fbff"
        border.width: 1
        border.color: "#d8e5ef"
        opacity: 0
        scale: 0.965

        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 0.5; color: "#f7fbff" }
                GradientStop { position: 1.0; color: "#eef7ff" }
            }
        }

        Rectangle {
            width: 510
            height: 510
            radius: width / 2
            x: -180
            y: -245
            color: "#d8f0ff"
            opacity: 0.48
        }

        Rectangle {
            width: 430
            height: 430
            radius: width / 2
            x: 570
            y: 390
            color: "#e5dcff"
            opacity: 0.37
        }

        Item {
            id: titleBar
            height: 52
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            z: 20

            MouseArea {
                anchors.left: parent.left
                anchors.right: windowControls.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                cursorShape: Qt.SizeAllCursor
                onPressed: root.startSystemMove()
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: "Class Widgets 2"
                color: "#6e8392"
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Row {
                id: windowControls
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                WindowControlButton {
                    symbol: "−"
                    onClicked: root.showMinimized()
                }
                WindowControlButton {
                    symbol: root.visibility === Window.Maximized ? "❐" : "□"
                    onClicked: {
                        if (root.visibility === Window.Maximized)
                            root.showNormal()
                        else
                            root.showMaximized()
                    }
                }
                WindowControlButton {
                    symbol: "×"
                    closeButton: true
                    enabled: !InstallerBridge.installing
                    onClicked: root.close()
                }
            }
        }

        Item {
            id: welcomePage
            anchors.fill: parent
            opacity: root.currentPage === 0 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }

            Image {
                id: welcomeLogo
                source: InstallerBridge.logoUrl
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectFit
                width: 72
                height: 72
                x: 72
                y: 112
                opacity: 0
            }

            Text {
                id: welcomeName
                text: "Class Widgets"
                color: root.ink
                font.pixelSize: 30
                font.weight: Font.DemiBold
                opacity: 0
                x: welcomeLogo.x + welcomeLogo.width + 14
                y: 227
            }

            Text {
                id: welcomeVersion
                text: "v" + InstallerBridge.version
                color: root.muted
                font.pixelSize: 15
                font.weight: Font.Medium
                opacity: 0
                x: 410
                y: 240
            }

            Text {
                id: welcomeSubtitle
                text: "为桌面课程信息提供恰到好处的陪伴"
                color: root.muted
                font.pixelSize: 14
                opacity: 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: 306
            }

            Rectangle {
                id: welcomeNext
                width: 56
                height: 56
                radius: width / 2
                color: nextHover.containsMouse ? "#2e89d2" : root.accent
                opacity: 0
                anchors.horizontalCenter: parent.horizontalCenter
                y: 382
                scale: nextHover.containsMouse ? 1.06 : 1.0

                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    text: "→"
                    color: "white"
                    font.pixelSize: 28
                    font.weight: Font.Medium
                }

                HoverHandler { id: nextHover }
                TapHandler { onTapped: root.goToLocation() }
            }

            SequentialAnimation {
                id: welcomeAnimation
                running: root.currentPage === 0 && !root.welcomePlayed
                onFinished: root.welcomePlayed = true

                ParallelAnimation {
                    NumberAnimation { target: welcomeLogo; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: welcomeLogo; property: "x"; to: (root.width - 126) / 2; duration: 660; easing.type: Easing.OutCubic }
                    NumberAnimation { target: welcomeLogo; property: "y"; to: 84; duration: 660; easing.type: Easing.OutCubic }
                    NumberAnimation { target: welcomeLogo; property: "width"; to: 126; duration: 660; easing.type: Easing.OutBack }
                    NumberAnimation { target: welcomeLogo; property: "height"; to: 126; duration: 660; easing.type: Easing.OutBack }
                }
                PauseAnimation { duration: 90 }
                ParallelAnimation {
                    NumberAnimation { target: welcomeName; property: "opacity"; to: 1; duration: 240; easing.type: Easing.OutCubic }
                    NumberAnimation { target: welcomeName; property: "x"; to: 420; duration: 440; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 420 }
                ParallelAnimation {
                    NumberAnimation { target: welcomeName; property: "x"; to: 214; duration: 540; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: welcomeVersion; property: "opacity"; to: 1; duration: 340; easing.type: Easing.OutCubic }
                }
                ParallelAnimation {
                    NumberAnimation { target: welcomeSubtitle; property: "opacity"; to: 1; duration: 280; easing.type: Easing.OutCubic }
                    NumberAnimation { target: welcomeNext; property: "opacity"; to: 1; duration: 280; easing.type: Easing.OutCubic }
                }
            }
        }

        Item {
            id: locationPage
            anchors.fill: parent
            opacity: root.currentPage === 1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }

            Column {
                width: 630
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 146
                spacing: 14

                Text {
                    text: "选择安装位置"
                    color: root.ink
                    font.pixelSize: 31
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "默认安装到当前用户目录，无需管理员权限。请选择一个你拥有写入权限的位置。"
                    color: root.muted
                    font.pixelSize: 14
                    lineHeight: 1.3
                }

                Item { width: 1; height: 16 }

                Rectangle {
                    width: parent.width
                    height: 58
                    radius: 15
                    color: "#f1f6fb"
                    border.width: pathInput.activeFocus ? 2 : 1
                    border.color: pathInput.activeFocus ? root.accent : "#dbe7f0"

                    TextField {
                        id: pathInput
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.right: browseButton.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.installPath
                        selectByMouse: true
                        color: root.ink
                        font.pixelSize: 14
                        background: Item {}
                    }

                    Rectangle {
                        id: browseButton
                        width: 92
                        height: 38
                        radius: 11
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        color: browseHover.containsMouse ? "#d8efff" : "#e7f4ff"

                        Text {
                            anchors.centerIn: parent
                            text: "浏览"
                            color: root.accent
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        HoverHandler { id: browseHover }
                        TapHandler { onTapped: root.selectFolder() }
                    }
                }

                Text {
                    text: "安装后的课表、配置、日志、外部主题和插件会安全地保存在你的本地应用数据目录。"
                    color: "#8a9aa6"
                    font.pixelSize: 12
                }

                Item { width: 1; height: 28 }

                Row {
                    width: parent.width
                    spacing: 12

                    ModernButton {
                        width: 120
                        text: "← 返回"
                        outline: true
                        onClicked: root.currentPage = 0
                    }
                    Item { width: parent.width - 332; height: 1 }
                    ModernButton {
                        width: 200
                        text: "确认并安装"
                        onClicked: root.beginInstallation()
                    }
                }
            }
        }

        Item {
            id: installingPage
            anchors.fill: parent
            opacity: root.currentPage === 2 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }

            Column {
                width: 560
                anchors.centerIn: parent
                spacing: 16

                Image {
                    source: InstallerBridge.logoUrl
                    width: 74
                    height: 74
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.92
                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 2600
                        loops: Animation.Infinite
                        running: InstallerBridge.installing
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "正在安装 Class Widgets"
                    color: root.ink
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: InstallerBridge.phase
                    color: root.muted
                    font.pixelSize: 14
                }

                Item { width: 1; height: 14 }

                Rectangle {
                    width: parent.width
                    height: 12
                    radius: 6
                    color: "#dfeaf2"

                    Rectangle {
                        width: parent.width * InstallerBridge.progress
                        height: parent.height
                        radius: parent.radius
                        color: root.accent
                        Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Math.round(InstallerBridge.progress * 100) + "%"
                    color: root.accent
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }
        }

        Item {
            id: completePage
            anchors.fill: parent
            opacity: root.currentPage === 3 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }

            Image {
                id: finishLogo
                source: InstallerBridge.logoUrl
                width: 126
                height: 126
                anchors.horizontalCenter: parent.horizontalCenter
                y: 100
                fillMode: Image.PreserveAspectFit
                opacity: root.completionPlayed ? 1 : 0
                scale: root.completionPlayed ? 1 : 0.72
                Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: 520; easing.type: Easing.OutBack } }
            }

            Repeater {
                model: 18
                delegate: Rectangle {
                    id: sparkle
                    required property int index
                    property real direction: index % 2 === 0 ? -1 : 1
                    property real distance: 72 + (index % 5) * 23
                    property real elevation: -52 + (index % 6) * 22
                    width: 6 + (index % 3) * 2
                    height: width
                    radius: width / 2
                    color: ["#4299e1", "#7b6cf6", "#43c5b8", "#f1a95f"][index % 4]
                    x: root.width / 2 - width / 2
                    y: 161 - height / 2
                    opacity: 0

                    SequentialAnimation on x {
                        running: root.currentPage === 3
                        PauseAnimation { duration: 60 + sparkle.index * 20 }
                        NumberAnimation { to: root.width / 2 - sparkle.width / 2 + sparkle.direction * sparkle.distance; duration: 640; easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation on y {
                        running: root.currentPage === 3
                        PauseAnimation { duration: 60 + sparkle.index * 20 }
                        NumberAnimation { to: 161 + sparkle.elevation; duration: 640; easing.type: Easing.OutCubic }
                    }
                    SequentialAnimation on opacity {
                        running: root.currentPage === 3
                        PauseAnimation { duration: 60 + sparkle.index * 20 }
                        NumberAnimation { to: 1; duration: 120 }
                        PauseAnimation { duration: 200 }
                        NumberAnimation { to: 0; duration: 320; easing.type: Easing.InCubic }
                    }
                }
            }

            Column {
                width: 380
                anchors.horizontalCenter: parent.horizontalCenter
                y: 254
                spacing: 9
                opacity: root.completionPlayed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Class Widgets"
                    color: root.ink
                    font.pixelSize: 29
                    font.weight: Font.DemiBold
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "已准备就绪"
                    color: root.muted
                    font.pixelSize: 15
                }
                Item { width: 1; height: 20 }
                ModernButton {
                    width: 204
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "进入应用"
                    onClicked: InstallerBridge.launchInstalledApplication()
                }
            }
        }
    }

    Timer {
        id: completionTimer
        interval: 80
        repeat: false
        onTriggered: root.completionPlayed = true
    }

    Connections {
        target: InstallerBridge
        function onInstallationFinished(success, message) {
            if (success) {
                root.currentPage = 3
                root.completionPlayed = false
                completionTimer.start()
            } else {
                root.currentPage = 1
                root.installPath = InstallerBridge.defaultInstallPath
                pathInput.text = root.installPath
            }
        }
    }

    component ModernButton: Rectangle {
        property string text: ""
        property bool outline: false
        signal clicked()
        height: 46
        radius: 14
        color: outline ? "#f3f7fa" : root.accent
        border.width: outline ? 1 : 0
        border.color: "#d8e3eb"
        scale: buttonHover.containsMouse ? 1.02 : 1.0

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 150 } }

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: parent.outline ? root.muted : "white"
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
        HoverHandler { id: buttonHover }
        TapHandler { onTapped: parent.clicked() }
    }

    component WindowControlButton: Rectangle {
        property string symbol: ""
        property bool closeButton: false
        signal clicked()
        width: 31
        height: 29
        radius: 9
        color: controlHover.containsMouse ? (closeButton ? "#ef5d6c" : "#e8f1f7") : "transparent"
        opacity: enabled ? 1 : 0.35

        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            anchors.centerIn: parent
            text: parent.symbol
            color: controlHover.containsMouse && parent.closeButton ? "white" : "#68808f"
            font.pixelSize: parent.symbol === "×" ? 20 : 17
            font.weight: Font.Medium
        }
        HoverHandler { id: controlHover }
        TapHandler { enabled: parent.enabled; onTapped: parent.clicked() }
    }

    Component.onCompleted: {
        stage.opacity = 1
        stage.scale = 1
    }
}
