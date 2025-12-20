// AnimatedDigit.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import ClassWidgets.Easing

Rectangle {
    id: root
    color: "transparent"

    property real scaleFactor: Configs.data.preferences.scale_factor || 1.0

    property string value: ""
    property string oldValue: ""
    property double progress: 1  // 0-1
    property int duration: 700

    property alias font: oldDigit.font
    implicitWidth: Math.max(oldDigit.width, newDigit.width)
    implicitHeight: Math.max(oldDigit.height, newDigit.height)

    Title {
        id: oldDigit
        text: root.oldValue
        anchors.centerIn: parent
        layer.enabled: true
        visible: false // 隐藏原始项，只让 Shader 显示
        layer.textureSize: Qt.size(width * scaleFactor, 
                               height * scaleFactor)
    }

    Title {
        id: newDigit
        text: root.value
        anchors.centerIn: parent
        layer.enabled: true
        visible: false
        layer.textureSize: Qt.size(width * scaleFactor, 
                               height * scaleFactor)
    }

    ShaderEffect {
        id: combinedShader
        anchors.fill: parent
        
        // 传入两个纹理
        property variant sourceOld: oldDigit
        property variant sourceNew: newDigit
        
        // 传入进度
        property real progress: root.progress
        
        fragmentShader: "digit.frag.qsb"
        
        // 只有在动画运行或数值不同时显示
        visible: true 
    }

    onValueChanged: {
        progressAnimation.restart()
    }

    SequentialAnimation {
        id: progressAnimation
        NumberAnimation {
            target: root
            property: "progress"
            from: 0
            to: 1
            duration: root.duration
            // easing.type: Easing.OutQuart
            easing.type: Easing.Bezier
            easing.bezierCurve: [ .51,.2,0,.44, 1, 1 ]
        }
        ScriptAction {
            script: {
                root.oldValue = root.value
            }
        }
    }
}
