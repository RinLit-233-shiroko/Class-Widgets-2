import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Rectangle {
    id: root
    objectName: "aiChatPanel"
    property real anchorX: 0
    property real anchorY: 0
    property real anchorWidth: 0
    property real anchorHeight: 0
    property string errorMessage: ""
    property bool voiceActivation: false
    property bool hasConversation: AiChatService.messages.length > 0
                                  || AiChatService.state === "thinking"
                                  || AiChatService.state === "responding"
                                  || AiChatService.state === "speaking"
    property bool listening: AiChatService.recording
                             || (AiChatService.state === "listening" && AiChatService.transcriptionText.length > 0)
    property real conversationHeight: hasConversation
                                      ? Math.min(392, Math.max(148, messageList.contentHeight + 22))
                                      : 0
    property real composerHeight: listening ? 144 : 84
    property real desiredHeight: composerHeight + (hasConversation ? conversationHeight + 12 : 0)
                                 + (AiChatService.speaking ? 66 : 0) + 28

    width: Math.min(540, parent ? parent.width - 44 : 540)
    height: desiredHeight
    x: {
        const desiredX = anchorWidth > 0 ? anchorX + (anchorWidth - width) / 2 : (parent.width - width) / 2
        return Math.max(22, Math.min(parent.width - width - 22, desiredX))
    }
    y: {
        // 常态优先落在点击 Widget 下方；空间不足时留在屏幕下侧而非顶部。
        const belowWidget = anchorHeight > 0 ? anchorY + anchorHeight + 16 : parent.height - height - 34
        return Math.max(22, Math.min(parent.height - height - 30, belowWidget))
    }
    z: 400
    visible: false
    opacity: visible ? 1 : 0
    radius: 20
    color: Theme.isDark() ? Qt.rgba(0.075, 0.09, 0.13, 0.97) : Qt.rgba(0.98, 0.985, 1, 0.98)
    border.width: 1
    border.color: Theme.isDark() ? Qt.rgba(0.66, 0.78, 1, 0.22) : Qt.rgba(0.24, 0.38, 0.62, 0.18)
    clip: true
    focus: visible

    signal panelGeometryChanged()

    Behavior on height { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 340; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    function openAt(fromVoiceWake, x, y, width, height) {
        voiceActivation = fromVoiceWake
        anchorX = x
        anchorY = y
        anchorWidth = width
        anchorHeight = height
        errorMessage = ""
        visible = true
        if (!fromVoiceWake)
            input.forceActiveFocus()
        panelGeometryChanged()
    }

    function closePanel(cancelConversation) {
        if (cancelConversation)
            AiChatService.cancel()
        visible = false
        panelGeometryChanged()
    }

    onXChanged: panelGeometryChanged()
    onYChanged: panelGeometryChanged()
    onWidthChanged: panelGeometryChanged()
    onHeightChanged: panelGeometryChanged()
    onVisibleChanged: panelGeometryChanged()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Rectangle {
            id: conversationSurface
            Layout.fillWidth: true
            Layout.preferredHeight: root.conversationHeight
            visible: root.hasConversation
            radius: 15
            clip: true
            color: Theme.isDark() ? Qt.rgba(0.11, 0.14, 0.21, 0.9) : Qt.rgba(0.92, 0.95, 0.99, 0.96)

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 350; easing.type: Easing.OutCubic }
            }

            ListView {
                id: messageList
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8
                clip: true
                model: AiChatService.messages
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    required property var modelData
                    property bool isUser: modelData.role === "user"
                    width: messageList.width
                    height: bubble.height + 6

                    Rectangle {
                        id: bubble
                        width: Math.min(messageList.width * 0.82, 420)
                        height: messageText.implicitHeight + 20
                        x: parent.isUser ? parent.width - width : 0
                        radius: 14
                        color: parent.isUser ? Theme.themeColor : (Theme.isDark() ? "#293348" : "#FFFFFF")

                        Text {
                            id: messageText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            width: parent.width - 24
                            text: modelData.content
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                            color: parent.parent.isUser ? "white" : (Theme.isDark() ? "#F3F6FF" : "#23324A")
                            font.pixelSize: 14
                            lineHeight: 1.28
                        }
                    }
                }

                footer: Item {
                    width: messageList.width
                    height: (AiChatService.state === "thinking" || AiChatService.state === "responding")
                            ? liveBubble.height + 8 : 0

                    Rectangle {
                        id: liveBubble
                        width: Math.min(messageList.width * 0.82, 420)
                        height: liveText.implicitHeight + 20
                        radius: 14
                        color: Theme.isDark() ? "#293348" : "#FFFFFF"

                        Text {
                            id: liveText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            width: parent.width - 24
                            text: AiChatService.currentResponse.length > 0
                                  ? AiChatService.currentResponse
                                  : qsTr("Thinking…")
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                            color: Theme.isDark() ? "#F3F6FF" : "#23324A"
                            font.pixelSize: 14
                            lineHeight: 1.28
                        }
                    }
                }

                onContentHeightChanged: positionViewAtEnd()
                Component.onCompleted: positionViewAtEnd()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.listening ? 126 : 62
            radius: 15
            color: Theme.isDark() ? "#182238" : "#EDF4FF"
            border.width: 1
            border.color: root.listening ? Qt.rgba(Theme.themeColor.r, Theme.themeColor.g, Theme.themeColor.b, 0.6)
                                         : (Theme.isDark() ? "#344765" : "#CFDCEF")

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 8

                Item {
                    Layout.preferredWidth: root.listening ? 62 : 42
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.listening ? 48 : 32
                        height: width
                        radius: width / 2
                        color: root.listening ? Theme.themeColor : Qt.alpha(Theme.themeColor, 0.72)

                        SequentialAnimation on scale {
                            running: root.listening
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.92; to: 1.12; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.12; to: 0.92; duration: 700; easing.type: Easing.InOutSine }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.listening ? "◉" : "AI"
                            color: "white"
                            font.bold: true
                            font.pixelSize: root.listening ? 22 : 12
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: input
                        anchors.fill: parent
                        visible: !root.listening
                        placeholderText: qsTr("Type a message…")
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        color: Theme.isDark() ? "#F5F7FC" : "#23324A"
                        background: Item {}
                        Keys.onReturnPressed: function(event) {
                            if (!event.modifiers && input.text.trim().length > 0) {
                                AiChatService.sendMessage(input.text)
                                input.clear()
                                event.accepted = true
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: root.listening
                        spacing: 5

                        Text {
                            text: qsTr("Listening…")
                            color: Theme.themeColor
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            text: AiChatService.transcriptionText.length > 0
                                  ? AiChatService.transcriptionText
                                  : qsTr("Speak naturally. Your words will appear here when recognized.")
                            wrapMode: Text.Wrap
                            color: Theme.isDark() ? "#C8D5EC" : "#52647E"
                            font.pixelSize: 12
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }

                Button {
                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 42
                    text: AiChatService.recording ? "■" : "◉"
                    enabled: AiChatService.state === "listening" || AiChatService.recording
                    ToolTip.visible: hovered
                    ToolTip.text: AiChatService.recording ? qsTr("Stop recording") : qsTr("Start recording")
                    onClicked: {
                        if (AiChatService.recording)
                            AiChatService.stopRecording()
                        else
                            AiChatService.startRecording()
                    }
                }

                Button {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 42
                    text: qsTr("Send")
                    visible: !root.listening
                    enabled: input.text.trim().length > 0 && (AiChatService.state === "idle" || AiChatService.state === "listening")
                    onClicked: {
                        AiChatService.sendMessage(input.text)
                        input.clear()
                    }
                }

                ToolButton {
                    Layout.preferredWidth: 34
                    text: "×"
                    font.pixelSize: 20
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Close")
                    onClicked: root.closePanel(true)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            visible: AiChatService.speaking
            radius: 13
            color: Theme.isDark() ? "#1D2C45" : "#E8F3FF"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        Layout.preferredWidth: 3
                        Layout.preferredHeight: 12 + (index % 3) * 7
                        radius: 2
                        color: Theme.themeColor
                        SequentialAnimation on scale {
                            running: AiChatService.speaking
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 95 }
                            NumberAnimation { from: 0.45; to: 1.18; duration: 380; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.18; to: 0.45; duration: 380; easing.type: Easing.InOutSine }
                        }
                    }
                }
                Text {
                    Layout.fillWidth: true
                    text: AiChatService.speechText
                    color: Theme.isDark() ? "#EAF2FF" : "#2D4C70"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            color: "#D95858"
            wrapMode: Text.Wrap
            font.pixelSize: 12
        }
    }

    Connections {
        target: AiChatService
        function onActivationRequested(fromVoiceWake, x, y, width, height) {
            root.openAt(fromVoiceWake, x, y, width, height)
        }
        function onErrorOccurred(message) {
            root.errorMessage = message
            if (!root.visible)
                root.openAt(false, 0, 0, 0, 0)
        }
        function onConversationChanged() { messageList.positionViewAtEnd() }
        function onResponseChanged() { messageList.positionViewAtEnd() }
    }
}
