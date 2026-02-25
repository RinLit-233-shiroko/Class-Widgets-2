import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme
import Qt5Compat.GraphicalEffects
import ClassWidgets.Easing

Widget {
    id: root
    property string notificationTitle: ""
    property string notificationMessage: ""
    property string notificationIcon: ""
    property int notificationLevel: -1
    property color notificationColor: Utils.primaryColor  // get theme color
    // property color notificationColor: "#605ed2"
    property bool hasNotification: false   // 新增，是否有通知

    property int notificationDuration: 4000 // 默认通知显示时间 4s

    // 目标显示状态（用于逻辑判断）
    readonly property bool shouldShow: editMode || !enabled || hasNotification

    // 实际显示状态（用于布局控制，动画完成后才改变）
    property bool actualVisible: true

    // 在目标状态变化时，更新实际可见性（延迟到动画完成）
    function updateVisibility() {
        if (shouldShow) {
            // 目标是要显示 - 立即设置实际可见性，播放入场动画
            if (!actualVisible) {
                actualVisible = true
                exitAnim.stop()
                enterAnim.start()
            }
        } else {
            // 目标是要隐藏 - 只播放消失动画，不立即改变实际可见性
            enterAnim.stop()
            exitAnim.start()
        }
    }

    // 初始状态设置
    Component.onCompleted: {
        actualVisible = shouldShow
        // 通知 Python 端 QML 已准备就绪
        if (AppCentral && AppCentral.notification) {
            AppCentral.notification.notifyQmlReady()
        }
    }

    // 宽度控制 - 只有在真正不可见时才设置为0
    width: actualVisible ? implicitWidth : 0
    visible: actualVisible

    // 初始状态
    opacity: 1
    scale: 1

    // 入场动画
    SequentialAnimation {
        id: enterAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 0; duration: 1 }
        PauseAnimation { duration: 0 }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 0; to: 1; duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root;
                property: "scale";
                from: 0.8; to: 1; duration: 400;
                easing.type: Easing.OutBack
            }
        }
        onFinished: {
            // 入场动画完成后，确保可见性正确
            actualVisible = shouldShow
        }
    }

    // 消失动画
    SequentialAnimation {
        id: exitAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 0; duration: 1 }
        PauseAnimation { duration: 0 }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 1; to: 0; duration: 200
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: root;
                property: "scale";
                from: 1; to: 0.9; duration: 250;
                easing.type: Easing.InQuad
            }
        }
        onFinished: {
            // 消失动画完成后才真正隐藏并重置内容
            if (!shouldShow) {
                actualVisible = false
                resetNotificationContent()
            }
        }
    }

    // 目标状态变化时触发更新
    onShouldShowChanged: {
        updateVisibility()
    }

    // 关闭按钮可见性
    property bool showCloseButton: editMode || (!editMode && hasNotification)

    // 手动关闭通知 - 只设置标记，实际重置在动画完成后
    function closeNotification() {
        hasNotification = false
    }

    // 真正重置通知内容（在动画完成后调用）
    function resetNotificationContent() {
        notificationTitle = ""
        notificationMessage = ""
        notificationIcon = ""
        notificationLevel = -1
    }

    // 自动消失定时器（可选）
    Timer {
        id: autoHideTimer
        interval: root.notificationDuration
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            if (!editMode && hasNotification) {
                closeNotification()
            }
        }
    }

    // Helper function 获取当前活动标题
    // function currentTitle() {
    //     return notificationTitle || qsTr("Dynamic Notification")
    // }
    //
    // function currentMessage() {
    //     return notificationMessage || qsTr("当前暂无通知")
    // }

    // Helper function 判断图标是否为URL
    function isIconUrl(icon) {
        return icon && (icon.startsWith("file://") || icon.startsWith("http://") || icon.startsWith("https://"))
    }

    // Helper function 获取当前图标
    function currentIcon() {
        if (notificationIcon) return notificationIcon
        return "ic_fluent_alert_badge_20_regular"
    }

    // Helper function 获取当前颜色
    function currentColor() {
        return levelColor(notificationLevel)
    }

    function levelColor(level) {
        switch (level) {
            case 0: // INFO
                return Utils.primaryColor   // 应用主题色
            case 1: // ANNOUNCEMENT
                return "#46CEA3"   // 绿，状态变化 / 上下课
            case 2: // WARNING
                return "#D83B01"   // Fluent 红橙，警告
            case 3: // SYSTEM
                return "#0078D4"   // Fluent 蓝，系统
            default:
                return Utils.primaryColor
        }
    }

    // 订阅后端通知
    property var notificationTarget: AppCentral.notification
    Connections {
        target: notificationTarget
        function onNotified(payload) {
            if (!payload) return
            // 设置新通知内容
            notificationTitle = payload.title || ""
            notificationMessage = payload.message || ""
            notificationIcon = payload.icon || ""
            notificationLevel = payload.level ?? 0

            // 如果当前正在播放消失动画，停止它
            exitAnim.stop()

            // 设置有通知状态，触发显示逻辑
            hasNotification = true

            // 重启自动消失定时器
            autoHideTimer.interval = payload.duration || 4000
            autoHideTimer.restart()
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 10

        // 图标显示，支持字体图标和图片文件
        Icon {
            id: notificationIconComponent
            name: !isIconUrl(notificationIcon) ? currentIcon() : ""
            source: isIconUrl(notificationIcon) ? notificationIcon : ""
            size: miniMode ? 24 : 32
            color: "#FFF"
            opacity: isIconUrl(notificationIcon) ? 1 : 0.9

            // 如果是图片文件，使用圆角遮罩
            layer.enabled: isIconUrl(notificationIcon)
            layer.effect: OpacityMask {
                width: notificationIconComponent.width
                height: notificationIconComponent.height

                maskSource: Rectangle {
                    width: notificationIconComponent.width
                    height: notificationIconComponent.height
                    radius: 12
                }
            }
        }

        // title & message
        RowLayout {
            spacing: 12
            MarqueeTitle {
                id: titleLabel
                color: "#FFF"
                text: editMode ? qsTr("No notification yet") : notificationTitle
                maximumWidth: 150
                speed: 100
            }
            Rectangle {
                Layout.preferredWidth: 2
                color: Qt.alpha("#FFF", 0.35)
                Layout.fillHeight: true
                visible: messageLabel.text ? !!titleLabel.text : false
            }
            MarqueeTitle {
                id: messageLabel
                color: "#FFF"
                text: notificationMessage
                speed: 100
            }
        }
    }

    subtitle: Subtitle {
        id: subtitleLabel
        color: "#FFF"
        text: qsTr("Dynamic Notification")
    }

    // 关闭按钮
    actions: ToolButton {
        flat: true
        visible: showCloseButton
        icon.name: "ic_fluent_dismiss_20_regular"
        color: "#FFF"
        implicitWidth: 24
        implicitHeight: 24
        size: 16
        onClicked: {
            // 停止自动消失定时器
            autoHideTimer.stop()
            // 开始消失动画，内容重置在动画完成后进行
            closeNotification()
        }
    }

    backgroundColor: Theme.isDark()
        ? Qt.alpha(currentColor(), 0.65)
        : Qt.alpha(currentColor(), 0.7)

    Behavior on notificationColor { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }
}
