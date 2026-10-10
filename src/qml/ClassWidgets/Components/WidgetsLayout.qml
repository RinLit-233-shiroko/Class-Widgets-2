import QtQuick
import QtQuick.Controls
import RinUI
import ClassWidgets.Easing

/*
 * WidgetsLayout —— 小组件横向排布（水平 ListView）
 */
Item {
    id: layoutRoot

    // Python 端按该 objectName 查找布局并计算窗口点击区域
    objectName: "widgetsFlow"

    property bool editMode: false
    // 正在拖动小组件
    property bool dragging: false
    property bool hide: false
    property real scaleFactor: 1.0
    property real spacing: 8

    // 视口取得足够大，保证全部 delegate 都实例化而不被回收销毁，
    // 否则小组件会被反复重载。高度只需覆盖小组件的最高尺寸。
    property real viewportWidth: 100000
    property real viewportHeight: 4096

    readonly property alias count: listView.count
    readonly property real contentWidth: listView.contentWidth
    property real contentHeight: 0

    width: contentWidth
    height: contentHeight
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    signal geometryChanged()
    signal editRequested()
    signal menuVisibilityChanged(bool visible)
    signal widgetTapped()

    // 遍历 delegate 求最大高度。水平 ListView 不负责纵向布局，
    // 必须自己算，否则容器高度为 0、外层按钮会压在小组件上。
    function refreshContentHeight() {
        var tallest = 0
        for (var i = 0; i < listView.count; ++i) {
            var it = listView.itemAtIndex(i)
            if (it && it.visible && it.height > tallest)
                tallest = it.height
        }
        contentHeight = tallest
    }

    // 每帧最多向外通知一次几何变化，避免逐帧刷 Python 端 mask
    Timer {
        id: geometryCoalesce
        interval: 0
        repeat: false
        onTriggered: layoutRoot.geometryChanged()
    }

    function notifyGeometry() {
        geometryCoalesce.restart()
    }

    // 按 widgetIndex 归位的槽位宽度表（moveRows 时 index 同步更新，itemAtIndex()/x 要等下一帧）
    function restingWidths() {
        var widths = []
        for (var i = 0; i < listView.count; ++i) {
            var it = listView.itemAtIndex(i)
            if (it && it.widgetIndex >= 0 && it.widgetIndex < listView.count)
                widths[it.widgetIndex] = it.width
        }
        return widths
    }

    // 编辑模式拖拽落点。用静止槽位而非当前 x：让位动画期间邻居的 x 一直在动，会让落点反复翻转。
    function dropIndexAt(centerX, fromIndex) {
        var widths = restingWidths()
        var x = 0
        var target = 0
        for (var i = 0; i < widths.length; ++i) {
            var w = widths[i] || 0
            if (i !== fromIndex && centerX > x + w / 2)
                ++target
            x += w
        }
        return target
    }

    function moveWidget(fromIndex, toIndex) {
        WidgetsModel.moveInstance(fromIndex, toIndex)
    }

    // 删除小组件。非编辑模式下的右键删除不会经过编辑模式的「完成」保存，
    // 若不在此写入后台配置，删除结果会在重启后丢失；编辑模式内仍统一等
    // 点击「完成」保存，避免频繁写入造成卡顿。
    function removeWidget(instanceId) {
        WidgetsModel.removeInstance(instanceId)
        if (!editMode)
            WidgetsModel.save_config()
    }

    // 供 delegate 判断后续是否还有可见小组件（决定是否需要输出间距）
    function itemAt(i) {
        return listView.itemAtIndex(i)
    }

    ListView {
        id: listView

        width: layoutRoot.viewportWidth
        height: layoutRoot.viewportHeight

        orientation: Qt.Horizontal
        spacing: 0
        interactive: false
        boundsBehavior: Flickable.StopAtBounds
        clip: false

        model: WidgetsModel

        // 拖动中被拖项的视觉位置由 delegate 偏移粘在指针上，这条动画会和偏移打架
        move: Transition {
            enabled: !layoutRoot.dragging
            NumberAnimation {
                properties: "x,y"
                duration: 240
                easing.type: Easing.OutCubic
            }
        }
        addDisplaced: Transition { enabled: false }
        removeDisplaced: Transition { enabled: false }
        // 拖动中让位要跟手：去掉延时并缩短时长
        displaced: Transition {
            id: displacedTransition

            SequentialAnimation {
                PauseAnimation {
                    duration: layoutRoot.dragging ? 0 : 30
                }

                NumberAnimation {
                    properties: "x,y"
                    duration: layoutRoot.dragging ? 180 : 260
                    easing.type: Easing.OutCubic
                }
            }
        }

        delegate: WidgetsLayoutDelegate {
            host: layoutRoot
            settingsDialog: settingsDialogInstance
            onWidgetTapped: layoutRoot.widgetTapped()
        }

        onContentWidthChanged: {
            layoutRoot.notifyGeometry()
            layoutRoot.refreshContentHeight()
        }
        onCountChanged: layoutRoot.refreshContentHeight()
    }

    WidgetSettingsDialog {
        // 独立 id，避免与 delegate 的同名属性形成自引用
        id: settingsDialogInstance
    }

    Component.onCompleted: refreshContentHeight()
}
