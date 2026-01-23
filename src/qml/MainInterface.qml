import QtQuick
import QtQuick.Controls
import QtQuick as QQ
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtQuick.Window as QQW
import RinUI
import ClassWidgets.Components
import ClassWidgets.Windows

QQW.Window {
    id: root
    visible: true
    // 动态判断平台
    flags: {
        let result = Qt.FramelessWindowHint | Qt.Window | Qt.WindowStaysOnTopHint;

        if (Qt.platform.os === "osx" || Qt.platform.os === "macos") {  // 修复macOS窗口问题
            return result;
        } else {
            // Windows：小组件页面不会被alt+tab截获
            return  Qt.Tool | result;
        }
    }
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
        root.flags = mouseHovered
            ? root.flags | Qt.WindowTransparentForInput
            : root.flags & ~Qt.WindowTransparentForInput
    }

    //background
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

    MouseArea {
        anchors.fill: parent
        onClicked: {
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

        // 坐标控制迁移到WidgetsContainer

        // 鼠标悬浮隐藏
        opacity: mouseHovered ? 0.25
            : hide ? 0.75 : 1

        Behavior on x { NumberAnimation { duration: 400 * root.initialized; easing.type: Easing.OutQuint } }
        Behavior on y { NumberAnimation { duration: 500 * root.initialized; easing.type: Easing.OutQuint } }

        TapHandler {
            id: hideTapHandler
            onTapped: {
                if (Configs.data.interactions.hide.clicked) {
                    Configs.set("interactions.hide.state", !Configs.data.interactions.hide.state)
                }
            }
        }

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
        // 应用当前主题的主题色
        var currentTheme = CWThemeManager.getThemeById(CWThemeManager.currentTheme)
        if (currentTheme && currentTheme.color) {
            // Theme.setThemeColor(currentTheme.color)
        } else {
            // origin #5CDCFF; 因为RinUI自带在暗色模式中的主题色补偿（这不夸夸（bushi），所以这里改成了更深的色调
            Theme.setThemeColor("#4099b2")
        }
    }


    Connections {
        target: Configs
        function onDataChanged() {
            updateLayer()
        }
    }

    Connections {
        target: CWThemeManager
        function onThemeChanged() {
            // 主题切换时应用主题色
            var currentTheme = CWThemeManager.getThemeById(CWThemeManager.currentTheme)
            if (currentTheme && currentTheme.color) {
                Theme.setThemeColor(currentTheme.color)
            }
        }
    }

    function updateLayer() {
        switch (Configs.data.preferences.widgets_layer) {
            case "top":
                root.flags &= ~Qt.WindowStaysOnBottomHint
                root.flags |= Qt.WindowStaysOnTopHint
                break
            case "bottom":
                root.flags &= ~Qt.WindowStaysOnTopHint
                root.flags |= Qt.WindowStaysOnBottomHint
                break
        }
    }
}

