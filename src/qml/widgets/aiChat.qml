import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root
    text: {
        AppCentral.translator.language
        return qsTr("AI Conversation")
    }
    implicitWidth: miniMode ? 160 : 228

    property color accent: AiChatService.active ? "#65CFF6" : "#7D89A5"
    property string stateLabel: {
        switch (AiChatService.state) {
        case "listening": return AiChatService.recording ? qsTr("Listening…") : qsTr("Ready to talk")
        case "thinking": return qsTr("Thinking…")
        case "responding": return qsTr("Replying…")
        default: return qsTr("Click to chat")
        }
    }

    backgroundArea: Rectangle {
        width: root.height * 0.55
        height: width
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        radius: width / 2
        color: root.accent
        visible: root.lightingEffect
        opacity: AiChatService.active ? 0.5 : 0.18
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: miniMode ? 8 : 12

        Rectangle {
            Layout.preferredWidth: miniMode ? 30 : 38
            Layout.preferredHeight: miniMode ? 30 : 38
            radius: width / 2
            color: Qt.alpha(root.accent, AiChatService.active ? 0.92 : 0.62)
            Text {
                anchors.centerIn: parent
                text: "AI"
                color: "white"
                font.bold: true
                font.pixelSize: miniMode ? 11 : 13
            }
            SequentialAnimation on scale {
                running: AiChatService.active
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.12; duration: 760; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.12; to: 1.0; duration: 760; easing.type: Easing.InOutSine }
            }
        }

        ColumnLayout {
            spacing: 2
            visible: !miniMode
            Label {
                text: qsTr("AI Conversation")
                font.pixelSize: 16
                font.bold: true
                color: Theme.isDark() ? "#F4F5FC" : "#1D2433"
            }
            Label {
                text: root.stateLabel
                color: root.accent
                font.pixelSize: 12
            }
        }
    }

    TapHandler {
        enabled: !root.editMode
        onTapped: AiChatService.activate()
    }
}
