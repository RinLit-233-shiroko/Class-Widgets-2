import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels
import RinUI

// 课程表文件视图：网格 / 表格两种呈现方式 + 右键菜单。
Item {
    id: view

    property var schedules: []
    property var selectedNames: []
    property string currentName: ""
    property bool selectionMode: false
    // 0 = 网格视图，1 = 表格视图
    property int viewMode: 0
    implicitHeight: view.viewMode === 1 ? 40 + Math.max(1, scheduleModel.rowCount) * 40 : 180
    // 当前右键菜单作用的对象与点击位置（view 坐标系）
    property string contextName: ""
    property real contextX: 0
    property real contextY: 0

    signal scheduleActivated(string name)
    signal selectionToggled(string name)
    signal duplicateRequested(string name)
    signal renameRequested(string name)
    signal deleteRequested(string name)
    signal exportRequested(string name, string format)

    function isSelected(name) {
        return (selectedNames || []).indexOf(name) >= 0
    }

    function nameAt(row) {
        const item = (view.schedules || [])[row]
        return item ? String(item.name || "") : ""
    }

    function formatModifiedAt(value) {
        const date = new Date(value)
        if (!value || isNaN(date.getTime())) return value || qsTr("Edited at unknown time")
        const elapsedSeconds = Math.max(0, (Date.now() - date.getTime()) / 1000)
        if (elapsedSeconds < 60) return qsTr("Just now")
        if (elapsedSeconds < 3600) return qsTr("%1 minutes ago").arg(Math.floor(elapsedSeconds / 60))
        if (elapsedSeconds < 86400) return qsTr("%1 hours ago").arg(Math.floor(elapsedSeconds / 3600))
        if (elapsedSeconds < 604800) return qsTr("%1 days ago").arg(Math.floor(elapsedSeconds / 86400))
        if (elapsedSeconds < 2592000) return qsTr("%1 weeks ago").arg(Math.floor(elapsedSeconds / 604800))
        if (elapsedSeconds < 31536000) return qsTr("%1 months ago").arg(Math.floor(elapsedSeconds / 2592000))
        return Qt.formatDate(date, Qt.locale().dateFormat(Locale.ShortFormat))
    }

    // ------------------------------------------------------------------
    // 右键菜单定位
    //
    // RinUI 的 Menu 虽然继承自 Popup，却额外声明了 position / posX / posY：
    //   1. Menu 写在一个 Item 里时，Popup.parent 就是那个 Item，因此
    //      x / y 属于该父项的坐标系，而不是 Overlay 坐标系；
    //   2. position 为 Position.None 时 posX / posY 会退化成 root.x / root.y，
    //      而 enter 动画又把 x / y 动画到 posX / posY，形成自引用，
    //      最终把菜单拉到 (0, 0) 附近 —— 这正是右键菜单错位的根因。
    // 所以这里统一把坐标换算到“菜单父项”坐标系，并覆盖掉 RinUI 自带的
    // 定位动画，只保留淡入淡出。
    // ------------------------------------------------------------------
    function menuParent() {
        return contextMenu.parent || view
    }

    function menuWidth() {
        return Math.max(contextMenu.implicitWidth, contextMenu.width, 80)
    }

    function menuHeight() {
        return Math.max(contextMenu.implicitHeight, 40)
    }

    // 把 view 坐标系下的点换算到菜单父项坐标系，并夹紧在 Overlay 可见范围内。
    function resolveMenuPosition(x, y) {
        const parentItem = menuParent()
        const overlay = Overlay.overlay
        if (!overlay)
            return view.mapToItem(parentItem, x, y)

        const margin = 8
        const point = view.mapToItem(overlay, x, y)
        const maxX = Math.max(margin, overlay.width - menuWidth() - margin)
        const maxY = Math.max(margin, overlay.height - menuHeight() - margin)
        return overlay.mapToItem(parentItem,
            Math.max(margin, Math.min(point.x, maxX)),
            Math.max(margin, Math.min(point.y, maxY)))
    }

    // 记录本次右键点击位置（view 坐标系），菜单尺寸变化时据此重新夹紧。
    function applyMenuPosition() {
        const point = resolveMenuPosition(view.contextX, view.contextY)
        contextMenu.x = point.x
        contextMenu.y = point.y
    }

    // x / y 为 view 坐标系下的点击位置
    function openContextMenu(name, x, y) {
        if (!name)
            return

        view.contextX = x
        view.contextY = y
        contextName = name
        contextMenu.scheduleName = name
        applyMenuPosition()

        if (!contextMenu.opened)
            contextMenu.open()

        // 菜单打开后隐式尺寸才最终确定，此时按真实尺寸再做一次夹紧。
        Qt.callLater(function() {
            if (contextMenu.opened)
                view.applyMenuPosition()
        })
    }

    // 菜单尺寸/位置稳定过程中持续校正，保证贴边时也精确夹紧。
    Connections {
        target: contextMenu
        function onImplicitWidthChanged() { if (contextMenu.opened) view.applyMenuPosition() }
        function onImplicitHeightChanged() { if (contextMenu.opened) view.applyMenuPosition() }
        function onWidthChanged() { if (contextMenu.opened) view.applyMenuPosition() }
        function onHeightChanged() { if (contextMenu.opened) view.applyMenuPosition() }
    }

    // ===== 网格视图 =====
    GridView {
        id: scheduleGrid
        anchors.fill: parent
        visible: view.viewMode === 0
        clip: true
        cellWidth: 124
        cellHeight: 124
        model: view.schedules

        delegate: ScheduleFileCard {
            required property var modelData
            width: 112
            height: 112
            filename: modelData.name
            modifiedAt: modelData.modifiedAt
            selected: view.isSelected(modelData.name)
                || (!view.selectionMode && modelData.name === view.currentName)
            selectionMode: view.selectionMode
            onClicked: view.scheduleActivated(modelData.name)
            onSelectionToggled: view.selectionToggled(modelData.name)
            onContextMenuRequested: {
                const point = mapToItem(view, mouseX, mouseY)
                view.openContextMenu(modelData.name, point.x, point.y)
            }
        }
    }

    // ===== 表格视图 =====
    // 第 0 列是选择模式下的勾选列（无表头文字），
    // 第 1、2 列才是名称与修改时间。
    TableModel {
        id: scheduleModel
        TableModelColumn { display: "selected" }
        TableModelColumn { display: "name" }
        TableModelColumn { display: "editedAt" }
    }

    // 行数据与 view.schedules 一一对应，nameAt() 依赖这一点。
    function rebuildModel() {
        const items = view.schedules || []
        const rows = []
        for (let i = 0; i < items.length; ++i) {
            rows.push({
                // 勾选列本身不显示文本，勾选状态由 CheckBox 直接反映 selectedNames。
                selected: "",
                name: String(items[i].name || ""),
                editedAt: view.formatModifiedAt(items[i].modifiedAt),
            })
        }
        scheduleModel.rows = rows
    }
    onSchedulesChanged: { rebuildModel(); tableView.forceLayout() }
    Component.onCompleted: rebuildModel()

    // 勾选列宽度。必须始终大于 0：
    // RinUI 的 TableViewDelegate 只在 column 0 的 delegate 里绘制整行背景
    // （background.visible: delegate.column === 0，且矩形宽度撑满整行），
    // 该列宽度为 0 时不会创建 delegate，整行背景与选中高亮都会消失。
    // 因此这里保持恒定居中列宽，选择模式只切换勾选框的显示，列宽不变、内容也不会跳动。
    readonly property int selectionColumnWidth: 38

    HorizontalHeaderView {
        id: horizontalHeader
        visible: view.viewMode === 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        syncView: tableView
        // 勾选列为空表头
        model: ["", qsTr("Name"), qsTr("Last edited")]
    }

    TableView {
        id: tableView
        visible: view.viewMode === 1
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: horizontalHeader.bottom
        implicitHeight: Math.max(1, scheduleModel.rowCount) * 40
        height: implicitHeight
        clip: true

        model: scheduleModel
        // 选中状态由 Home.qml 的 selectedNames 统一保存，不使用 TableView 自带的选中模型。
        selectionModel: null
        editTriggers: TableView.NoEditTriggers
        rowHeightProvider: function(row) { return 40 }
        columnWidthProvider: function(column) {
            // 勾选列恒定占位（见 selectionColumnWidth 的说明），其余宽度按比例分配。
            const checkboxWidth = view.selectionColumnWidth
            const rest = Math.max(0, tableView.width - 1 - checkboxWidth)
            const nameWidth = Math.floor(rest * 0.50)
            const editedWidth = Math.max(0, rest - nameWidth)
            if (column === 0)
                return checkboxWidth
            if (column === 1)
                return nameWidth
            if (column === 2)
                return editedWidth
            return 0
        }
        columnSpacing: 0
        rowSpacing: 0
        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        delegate: TableViewDelegate {
            id: cell
            // 每行对应的课程表名，供选中判断与勾选框复用。
            readonly property string rowName: view.nameAt(cell.row)
            readonly property bool isSelectionColumn: cell.column === 0

            highlighted: view.isSelected(rowName)
                || (!view.selectionMode && rowName === view.currentName)

            // 勾选列：默认显示课表图标，进入选择模式后换成勾选框。
            CheckBox {
                visible: view.selectionMode && cell.isSelectionColumn
                checked: view.isSelected(cell.rowName)
                anchors.centerIn: parent
                onClicked: view.selectionToggled(cell.rowName)
            }

            // 非选择模式下用图标占位，避免该列空着。
            // 图标与网格视图的卡片保持一致，选中时用主题主色。
            Icon {
                visible: !view.selectionMode && cell.isSelectionColumn
                anchors.centerIn: parent
                name: "ic_fluent_calendar_clock_20_regular"
                size: 20
                color: cell.highlighted ? Colors.proxy.primaryColor : Colors.proxy.textColor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    const name = view.nameAt(cell.row)
                    if (!name)
                        return
                    if (view.selectionMode)
                        view.selectionToggled(name)
                    else
                        view.scheduleActivated(name)
                }
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    const name = view.nameAt(cell.row)
                    if (!name)
                        return
                    const point = cell.mapToItem(view, point.position.x, point.position.y)
                    view.openContextMenu(name, point.x, point.y)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: (view.schedules || []).length === 0
        text: qsTr("No schedules found")
        typography: Typography.Body
        color: Colors.proxy.textSecondaryColor
    }

    // ===== 右键菜单 =====
    Menu {
        id: contextMenu
        objectName: "scheduleFileContextMenu"

        // 由 openContextMenu() 手动定位，因此禁用 RinUI 的锚定与定位动画。
        position: Position.None
        enter: Transition {
            NumberAnimation {
                target: contextMenu
                property: "opacity"
                from: 0
                to: 1
                duration: Utils.animationSpeedFaster
                easing.type: Easing.OutQuart
            }
        }
        exit: Transition {
            NumberAnimation {
                target: contextMenu
                property: "opacity"
                from: 1
                to: 0
                duration: Utils.animationSpeedFaster
                easing.type: Easing.OutQuart
            }
        }

        property string scheduleName: ""
        property bool deleteEnabled: view.contextName !== view.currentName

        signal duplicateRequested(string name)
        signal renameRequested(string name)
        signal deleteRequested(string name)
        signal exportRequested(string name, string format)

        MenuItem {
            icon.name: "ic_fluent_copy_add_20_regular"
            text: qsTr("Duplicate")
            onTriggered: contextMenu.duplicateRequested(contextMenu.scheduleName)
        }
        MenuItem {
            icon.name: "ic_fluent_rename_20_regular"
            text: qsTr("Rename")
            onTriggered: contextMenu.renameRequested(contextMenu.scheduleName)
        }
        MenuItem {
            icon.name: "ic_fluent_delete_20_regular"
            text: qsTr("Delete")
            enabled: contextMenu.deleteEnabled
            onTriggered: contextMenu.deleteRequested(contextMenu.scheduleName)
        }
        MenuSeparator {}
        Menu {
            icon.name: "ic_fluent_share_20_regular"
            title: qsTr("Export")
            position: Position.Right
            MenuItem {
                icon.source: PathManager.images("icons/cw2_editor.png")
                text: qsTr("Class Widgets 2 Schedule")
                onTriggered: contextMenu.exportRequested(contextMenu.scheduleName, "json")
            }
            MenuItem {
                icon.source: PathManager.images("icons/smart_teach.svg")
                text: qsTr("CSES Schedule Exchange Format")
                onTriggered: contextMenu.exportRequested(contextMenu.scheduleName, "cses")
            }
        }

        onDuplicateRequested: function(name) { view.duplicateRequested(name) }
        onRenameRequested: function(name) { view.renameRequested(name) }
        onDeleteRequested: function(name) { view.deleteRequested(name) }
        onExportRequested: function(name, format) { view.exportRequested(name, format) }
    }
}
