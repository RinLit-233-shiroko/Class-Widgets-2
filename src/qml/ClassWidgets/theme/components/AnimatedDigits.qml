// AnimatedDigit.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import ClassWidgets.Easing
import ClassWidgets.Theme 1.0


Rectangle {
    id: root
    color: "transparent"

    property string value: ""
    property string oldValue: ""
    property double progress: 1
    property int duration: 700
    property real scaleFactor: Configs.data.preferences.scale_factor || 1.0

    property alias font: oldDigit.font
    implicitWidth: Math.max(oldDigit.width, newDigit.width)
    implicitHeight: Math.max(oldDigit.height, newDigit.height)

    Title {
        id: oldDigit
        text: root.oldValue
        anchors.centerIn: parent
        opacity: 0
        layer.enabled: true
        layer.textureSize: Qt.size(width * scaleFactor * 4, 
                               height * scaleFactor * 4)
    }

    LinearGradient {
        id: oldDigitGradient
        anchors.fill: oldDigit
        source: oldDigit
        gradient: Gradient {
            GradientStop { position: 0; color: oldDigit.color }
            GradientStop {
                position: 0.8 - progress;
                color: Qt.alpha(oldDigit.color, Math.max(0, 1 - progress * 2))
            }
            GradientStop { position: 0.9 - progress; color: Qt.alpha(oldDigit.color, 0) }
            GradientStop { position: 1 - progress; color: Qt.alpha(oldDigit.color, 0) }
        }
    }

    Title {
        id: newDigit
        text: root.value
        anchors.centerIn: parent
        opacity: 0
        font: oldDigit.font
        layer.enabled: true
        layer.textureSize: Qt.size(width * scaleFactor * 4, 
                               height * scaleFactor * 4)
    }

    LinearGradient {
        id: newDigitGradient
        anchors.fill: newDigit
        opacity: progress * 3
        source: newDigit
        gradient: Gradient {
            GradientStop { position: 0.85 - progress; color: Qt.alpha(newDigit.color, 0) }
            GradientStop {
                position: 1 - progress;
                color: Qt.alpha(newDigit.color, Math.min(1, Math.max(0, progress * 2 - 0.5)))
            }
            GradientStop { position: 1; color: newDigit.color }
        }
    }

    onValueChanged: {
        newDigitGradient.visible = true
        progressAnimation.start()
    }

    SequentialAnimation {
        id: progressAnimation
        NumberAnimation {
            target: root
            property: "progress"
            from: 0
            to: 1
            duration: root.duration
            easing.type: Easing.OutQuart
        }
    }
}
