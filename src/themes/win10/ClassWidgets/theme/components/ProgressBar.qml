import QtQuick 2.15
import QtQuick.Controls.Basic 2.15
import Qt5Compat.GraphicalEffects
import RinUI


ProgressBar {
    id: root

    property color backgroundColor: indeterminate
        ? "transparent"
        // : Theme.currentTheme.colors.controlBorderStrongColor
        : Theme.isDark() ? Qt.alpha("white", 0.2) : Qt.alpha("black", 0.2)
    property color primaryColor: Theme.currentTheme.colors.primaryColor
    property int radius: 0
    property int state: ProgressBar.Running

    enum State {
        Running,
        Paused,
        Error
    }

    implicitHeight: 3

    // 背景轨道
    background: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: parent.height
        radius: root.radius
        color: backgroundColor
    }

    // 遮罩（让指示条圆角可控）
    // layer.enabled: true
    // layer.smooth: true
    // layer.effect: OpacityMask {
    //     maskSource: Rectangle {
    //         width: root.width
    //         height: root.height
    //         radius: root.radius
    //     }
    // }

    // 进度内容
    contentItem: Item {
        id: content
        implicitWidth: 200
        implicitHeight: 3
        clip: true

        // 指示条 Rectangle
        Rectangle {
            id: indicator
            height: parent.height
            radius: root.radius
            color: root.state === 1 ? Theme.currentTheme.colors.systemCautionColor :
                   root.state === 2 ? Theme.currentTheme.colors.systemCriticalColor :
                   root.primaryColor

            width: root.indeterminate
                ? root.state === 0 ? root.width / 3 : parent.width
                : root.visualPosition * parent.width

            x: root.indeterminate
                ? (root.state === 0 ? -indicator.width : 0)
                : 0

            Behavior on width {
                enabled: !root.indeterminate
                NumberAnimation {
                    duration: Utils.animationSpeed
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Utils.animationSpeed
                    easing.type: Easing.OutCubic
                }
            }

            // 非确定态动画（Running）
            NumberAnimation on x {
                from: -indicator.width
                to: root.width
                duration: Utils.progressBarAnimationSpeed
                loops: Animation.Infinite
                easing.type: Easing.InOutQuart
                running: root.indeterminate && root.state === 0
            }
        }

        // 非确定态动画（Paused / Error）→ 归位动画
        SequentialAnimation {
            id: returnAnimation
            running: root.indeterminate && root.state !== 0
            NumberAnimation {
                target: indicator
                property: "width"
                from: indicator.width
                to: root.width / 10
                duration: Utils.animationSpeedFaster
                easing.type: Easing.InQuart
            }
            NumberAnimation {
                target: indicator
                property: "width"
                from: 0
                to: root.width
                duration: Utils.animationSpeedMiddle
                easing.type: Easing.OutQuint
            }
        }
    }

    // 状态切换立即更新 indicator 状态
    onStateChanged: {
        if (indeterminate) {
            if (state !== 0) {
                indicator.x = 0
            } else {
                indicator.width = root.width / 3
            }
        }
    }

    Component.onCompleted: {
        if (!indeterminate) {
            indicator.width = root.visualPosition * root.width
        } else {
            indicator.width = state === 0 ? root.width / 3 : root.width
        }
    }
}
