import QtQuick
import QtQuick.Controls
import QtQuick as QQ
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtQuick.Window as QQW
import Widgets
import RinUI
import ClassWidgets.Components
import ClassWidgets.Windows

QQW.Window {
    id: root
    visible: true
    flags: Qt.FramelessWindowHint | Qt.Window | Qt.NoDropShadow
    color: "transparent"

    property string screenName: Configs.data.preferences.display || Qt.application.screens[0].name
    property var screen: {
        for (let s of Qt.application.screens) {
            if (s.name === screenName)
                return s
        }
        return Qt.application.screens[0]
    }

    x: screen.virtualX + ((screen.width - width) / 2)  || 0
    y: screen.virtualY + ((screen.height - height) / 2) || 0
    width: screen.width
    height: screen.height

    property bool initialized: false
    property alias editMode: widgetsLoader.editMode
    property bool mouseHovered: false

    onMouseHoveredChanged: {
        // 仅保留状态属性，移除对 root.flags 的动态修改
        // 依靠 Python 端的 setMask 实现物理层面的点击穿透
    }

    // background
    Rectangle {
        id: background
        anchors.fill: parent
        visible: editMode
        color: "black"
        opacity: editMode? 0.25 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
    }

    Timer {
        id: initalizeTimer
        interval: 300
        running: true
        repeat: false
        onTriggered: root.initialized = true
    }

    // 全局点击拦截（仅用于关闭菜单）
    TapHandler {
        onTapped: {
            if (widgetsLoader.menuVisible) {
                widgetsLoader.menuVisible = false
            }
        }
    }

    Connections {
        target: AppCentral
        function onTogglePanel(pos) {
            trayPanel.raise()
        }
    }

    Watermark {
        x: widgetsLoader.x
        y: widgetsLoader.y + widgetsLoader.height / 3
        opacity: 0.2
        color: "gray"
        z: 999
    }

    WidgetsContainer {
        id: widgetsLoader
        objectName: "widgetsLoader"

        // 鼠标悬浮感应控制透明度
        opacity: mouseHovered ? 0.25
            : hide ? 0.75 : 1

        Behavior on x { NumberAnimation { duration: 400 * root.initialized; easing.type: Easing.OutQuint } }
        Behavior on y { NumberAnimation { duration: 500 * root.initialized; easing.type: Easing.OutQuint } }

        signal geometryChanged()
        onXChanged: geometryChanged()
        onYChanged: geometryChanged()
        onWidthChanged: geometryChanged()
        onHeightChanged: geometryChanged()
        onEditModeChanged: geometryChanged()
        onMenuVisibleChanged: geometryChanged()
    }

    TrayPanel {
        id: trayPanel
    }

    Component.onCompleted: {
        updateLayer()
    }

    Connections {
        target: Configs
        function onDataChanged() {
            updateLayer()
        }
    }

    function updateLayer() {
        switch (Configs.data.preferences.widgets_layer) {
            case "top":
                root.flags = (root.flags & ~Qt.WindowStaysOnBottomHint) | Qt.WindowStaysOnTopHint
                break
            case "bottom":
                root.flags = (root.flags & ~Qt.WindowStaysOnTopHint) | Qt.WindowStaysOnBottomHint
                break
        }
    }
}

