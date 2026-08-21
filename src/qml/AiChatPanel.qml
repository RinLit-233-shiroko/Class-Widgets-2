import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import RinUI
import ClassWidgets.Theme

Rectangle {
    id: root
    objectName: "aiChatPanel"
    width: Math.min(560, parent ? parent.width - 48 : 560)
    property real speechTailHeight: AiChatService.speaking ? 104 : 0
    height: Math.min(650, parent ? parent.height - 48 - speechTailHeight : 650)
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? Math.max(24, (parent.height - height - speechTailHeight) / 2) : 0
    z: 6000
    visible: false
    radius: 24
    color: Theme.isDark() ? Qt.rgba(0.08, 0.09, 0.13, 0.97) : Qt.rgba(0.98, 0.98, 1, 0.98)
    border.width: 1
    border.color: Theme.isDark() ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0.22, 0.33, 0.5, 0.14)
    focus: visible

    property string errorMessage: ""
    signal panelGeometryChanged()

    function openPanel() {
        visible = true
        input.forceActiveFocus()
        panelGeometryChanged()
    }

    function closePanel() {
        visible = false
        panelGeometryChanged()
    }

    onXChanged: panelGeometryChanged()
    onYChanged: panelGeometryChanged()
    onWidthChanged: panelGeometryChanged()
    onHeightChanged: panelGeometryChanged()
    onVisibleChanged: panelGeometryChanged()

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 16
        radius: 32
        samples: 33
        color: "#50000000"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: "#58C9F3" }
                    GradientStop { position: 1; color: "#8978F2" }
                }
                Text {
                    anchors.centerIn: parent
                    text: "AI"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label {
                    text: qsTr("AI Conversation")
                    font.pixelSize: 18
                    font.bold: true
                    color: Theme.isDark() ? "#F4F5FC" : "#1D2433"
                }
                Label {
                    text: {
                        switch (AiChatService.state) {
                        case "listening": return AiChatService.recording ? qsTr("Listening… release the microphone button when you finish") : qsTr("Ready for your message")
                        case "thinking": return qsTr("Thinking…")
                        case "responding": return qsTr("Replying…")
                        case "speaking": return qsTr("Reading aloud…")
                        default: return qsTr("Conversation complete")
                        }
                    }
                    color: Theme.isDark() ? "#AEB8CD" : "#61708A"
                    font.pixelSize: 12
                }
            }

            ToolButton {
                text: "↺"
                font.pixelSize: 20
                enabled: AiChatService.state === "idle"
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Clear conversation")
                onClicked: AiChatService.clearConversation()
            }
            ToolButton {
                text: "×"
                font.pixelSize: 22
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Close")
                onClicked: root.closePanel()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.isDark() ? "#2A3040" : "#E0E5EE"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 16
            color: Theme.isDark() ? "#111520" : "#F1F4F9"
            clip: true

            ListView {
                id: messageList
                anchors.fill: parent
                anchors.margins: 12
                spacing: 9
                clip: true
                model: AiChatService.messages
                ScrollBar.vertical: ScrollBar {}

                delegate: Item {
                    required property var modelData
                    width: messageList.width
                    height: bubble.implicitHeight

                    Rectangle {
                        id: bubble
                        width: Math.min(implicitWidth, messageList.width * 0.82)
                        implicitWidth: messageText.implicitWidth + 24
                        implicitHeight: messageText.implicitHeight + 18
                        x: modelData.role === "user" ? parent.width - width : 0
                        radius: 13
                        color: modelData.role === "user" ? "#5379E8" : (Theme.isDark() ? "#293041" : "#FFFFFF")

                        Text {
                            id: messageText
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, messageList.width * 0.82 - 24)
                            text: modelData.content
                            wrapMode: Text.Wrap
                            color: modelData.role === "user" ? "white" : (Theme.isDark() ? "#F0F3FA" : "#273246")
                            font.pixelSize: 14
                            lineHeight: 1.25
                        }
                    }
                }

                footer: Item {
                    width: messageList.width
                    height: (AiChatService.state === "thinking" || AiChatService.state === "responding") ? responseBubble.implicitHeight + 9 : 0
                    visible: height > 0

                    Rectangle {
                        id: responseBubble
                        width: Math.min(implicitWidth, messageList.width * 0.82)
                        implicitWidth: responseText.implicitWidth + 24
                        implicitHeight: responseText.implicitHeight + 18
                        radius: 13
                        color: Theme.isDark() ? "#293041" : "#FFFFFF"

                        Text {
                            id: responseText
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, messageList.width * 0.82 - 24)
                            text: AiChatService.currentResponse || (AiChatService.state === "thinking" ? qsTr("Preparing a reply…") : "")
                            wrapMode: Text.Wrap
                            color: Theme.isDark() ? "#F0F3FA" : "#273246"
                            font.pixelSize: 14
                            lineHeight: 1.25
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: messageList.count === 0 && AiChatService.state === "idle"
                    text: qsTr("Type a message below, or use the microphone to speak to AI.")
                    width: parent.width - 40
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    color: Theme.isDark() ? "#7F8AA2" : "#7A879A"
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            color: "#E36565"
            wrapMode: Text.Wrap
            font.pixelSize: 12
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextArea {
                id: input
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                placeholderText: qsTr("Type a message…")
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                enabled: AiChatService.state === "idle" || AiChatService.state === "listening"
                color: Theme.isDark() ? "#F3F5FA" : "#1D2433"
                background: Rectangle {
                    radius: 14
                    color: Theme.isDark() ? "#1A2030" : "#F1F4F9"
                    border.width: 1
                    border.color: input.activeFocus ? "#668BFA" : (Theme.isDark() ? "#33405A" : "#D5DCE8")
                }
                Keys.onReturnPressed: function(event) {
                    if (!event.modifiers && input.text.trim().length > 0) {
                        AiChatService.sendMessage(input.text)
                        input.clear()
                        event.accepted = true
                    }
                }
            }

            Button {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 50
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
                Layout.preferredWidth: 70
                Layout.preferredHeight: 50
                text: qsTr("Send")
                enabled: input.text.trim().length > 0 && (AiChatService.state === "idle" || AiChatService.state === "listening")
                onClicked: {
                    AiChatService.sendMessage(input.text)
                    input.clear()
                }
            }
        }
    }

    Rectangle {
        id: speechTail
        anchors.top: root.bottom
        anchors.horizontalCenter: root.horizontalCenter
        width: root.width * 0.92
        height: root.speechTailHeight
        opacity: AiChatService.speaking ? 1 : 0
        visible: height > 0 || opacity > 0
        clip: true
        radius: 0
        color: Theme.isDark() ? "#1A2132" : "#EDF4FF"
        border.width: 1
        border.color: Theme.isDark() ? "#3B547A" : "#C7DDF8"

        Behavior on height {
            NumberAnimation { duration: 320; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 48
            height: 4
            radius: 2
            color: Theme.isDark() ? "#7CC7F5" : "#4B8EEB"
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 14
            anchors.bottomMargin: 12
            spacing: 12

            Item {
                Layout.preferredWidth: 44
                Layout.fillHeight: true

                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        width: 4
                        height: 13 + ((index * 7) % 18)
                        radius: 2
                        x: index * 8 + 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: index % 2 === 0 ? "#55C5F2" : "#887AF4"
                        SequentialAnimation on scale {
                            running: AiChatService.speaking
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 90 }
                            NumberAnimation { from: 0.45; to: 1.15; duration: 430; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.15; to: 0.45; duration: 430; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 3

                Label {
                    text: qsTr("Reading aloud")
                    color: Theme.isDark() ? "#9FC9F6" : "#316FC0"
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: AiChatService.speechText
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    color: Theme.isDark() ? "#F0F4FF" : "#233E65"
                    font.pixelSize: 13
                    lineHeight: 1.2
                }
            }

            Button {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 34
                text: "■"
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Stop reading")
                onClicked: AiChatService.cancel()
            }
        }
    }

    Connections {
        target: AiChatService
        function onActivationRequested(_fromVoiceWake) {
            root.errorMessage = ""
            root.openPanel()
        }
        function onErrorOccurred(message) {
            root.errorMessage = message
            root.openPanel()
        }
        function onConversationChanged() {
            messageList.positionViewAtEnd()
        }
        function onResponseChanged() {
            messageList.positionViewAtEnd()
        }
    }
}
