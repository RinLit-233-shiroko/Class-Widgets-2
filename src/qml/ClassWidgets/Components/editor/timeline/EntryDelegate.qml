import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Clip {
    id: entryDelegate
    property int index
    property var entry
    property real pxPerMin
    property Item listViewRoot: null
    checked: currentIndex === model.index
    clip: true


    radius: 6
    color: entry.type === "class"    ? Colors.proxy.primaryColor
         : entry.type === "break"    ? Theme.currentTheme.colors.systemSuccessColor
         : entry.type === "activity" ? Theme.currentTheme.colors.systemCautionColor
                                     : Theme.currentTheme.colors.systemNeutralColor

    background: Rectangle {
        anchors.fill: parent
        color: entryDelegate.color
        radius: entryDelegate.radius
        opacity: checked ? 1 : 0.3

    }

    property int tempStart: parseTime(entry.startTime)
    property int tempEnd: parseTime(entry.endTime)
    readonly property bool enabledDrag: height > 20

    x: 52
    width: parent.width - x
    y: tempStart * pxPerMin
    height: (tempEnd - tempStart) * pxPerMin + 1

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: updateListHoverState()
    }

    onCheckedChanged: updateListHoverState()

    Menu {
        id: contextMenu

        MenuItem {
            icon.name: "ic_fluent_delete_20_regular"
            text: qsTr("Remove")
            onTriggered: {
                AppCentral.scheduleEditor.removeEntry(entry.id)
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: contextMenu.open()
    }

    onClicked: {
        currentIndex = entryDelegate.index
        // Loader creation is asynchronous when the selection changes.
        Qt.callLater(function() {
            if (detailViewLoader.item)
                detailViewLoader.item.refresh(entry)
        })
    }

    // The flyout contains a subject Repeater and several controls. Keeping
    // one instance per entry makes large schedules expensive to build.
    Loader {
        id: detailViewLoader
        active: entryDelegate.checked
        sourceComponent: Component {
            EntryDetailView {
                sourceItem: entryDelegate.listViewRoot
            }
        }
    }

    // 正在编辑该条（详情 Flyout 打开）时，禁用其拖动手柄，避免时间选择器
    // 里的拖拽穿透把本条带跑。
    readonly property bool detailOpen: detailViewLoader.active
        && detailViewLoader.item ? detailViewLoader.item.opened : false

    // 上拖拽调整
    Item {
        id: startResizeHandle
        anchors.top: parent.top
        width: parent.width
        height: 12
        z: 2

        Rectangle {
            anchors.top: parent.top
            anchors.margins: 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width / 6
            height: 4
            radius: height / 2
            color: Qt.alpha("white", 0.4)
        }

        DragHandler {
            id: startResizeHandler
            target: null
            yAxis.enabled: true
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onTranslationChanged: {
                let deltaMins = Math.round(translation.y / pxPerMin / 5) * 5
                let newStart = parseTime(entry.startTime) + deltaMins
                entryDelegate.tempStart = Math.max(0, Math.min(
                    newStart, entryDelegate.tempEnd - 5
                ))
            }
            onActiveChanged: if (!active) commitUpdate()
        }

        HoverHandler {
            cursorShape: Qt.SizeVerCursor
        }

        visible: enabledDrag
        enabled: enabledDrag && !entryDelegate.detailOpen
    }

    // 下拖拽调整时间
    Item {
        id: endResizeHandle
        width: parent.width
        height: 12
        anchors.bottom: parent.bottom
        z: 2

        visible: enabledDrag
        enabled: enabledDrag && !entryDelegate.detailOpen

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.margins: 4
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width / 6
            height: 4
            radius: height / 2
            color: Qt.alpha("white", 0.4)
        }

        DragHandler {
            id: endResizeHandler
            target: null
            yAxis.enabled: true
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onTranslationChanged: {
                let deltaMins = Math.round(translation.y / pxPerMin / 5) * 5
                let newEnd = parseTime(entry.endTime) + deltaMins
                entryDelegate.tempEnd = Math.min(24 * 60, Math.max(
                    newEnd, entryDelegate.tempStart + 5
                ))
            }
            onActiveChanged: if (!active) commitUpdate()
        }

        HoverHandler {
            cursorShape: Qt.SizeVerCursor
        }
    }

    // 拖动整体调整
    DragHandler {
        id: moveHandler
        // The selected entry must be able to take the pointer from Flickable.
        // 详情/时间选择器打开时禁用，避免拖拽穿透把本条带跑。
        enabled: checked && !entryDelegate.detailOpen && !startResizeHandler.active && !endResizeHandler.active
        target: null
        yAxis.enabled: true
        grabPermissions: PointerHandler.CanTakeOverFromAnything

        property int startTempStart
        property int startTempEnd

        onActiveChanged: {
            if (active) {
                startTempStart = entryDelegate.tempStart
                startTempEnd = entryDelegate.tempEnd
            } else {
                commitUpdate()
            }
        }

        onTranslationChanged: {
            let deltaMins = Math.round(translation.y / pxPerMin / 5) * 5
            let newStart = startTempStart + deltaMins
            let newEnd = startTempEnd + deltaMins
            if (newStart >= 0 && newEnd <= 24 * 60) {  // 保证不超出一天
                entryDelegate.tempStart = newStart
                entryDelegate.tempEnd = newEnd
            }
        }
    }

    HoverHandler {
        enabled: checked
        cursorShape: Qt.SizeAllCursor
    }

    // 内容
    Column {
        id: content
        property bool expanded: entryDelegate.height >= 48

        anchors.top: expanded ? parent.top : undefined
        // anchors.verticalCenter: !expanded ? parent.verticalCenter : undefined
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.margins: 12
        spacing: 4

        RowLayout {
            spacing: 8
            // 标题
            Text {
                typography: Typography.BodyStrong
                text: {
                    if (modelData.title) {
                        return modelData.title
                    }
                    if (modelData.subjectId) {
                        return AppCentral.scheduleEditor.subjectNameById(modelData.subjectId)
                    }
                    switch (modelData.type) {
                        case "class": return qsTr("Class")
                        case "break": return qsTr("Break")
                        case "activity": return qsTr("Activity")
                        default: return qsTr("Unknown Type")
                    }
                }
                color: checked ? Colors.proxy.textOnAccentColor : Colors.proxy.textColor
            }
            Text {
                // visible: !content.expanded
                text: `${minutesToTime(entryDelegate.tempStart)} - ${minutesToTime(entryDelegate.tempEnd)}` +
                    "    (" +(entryDelegate.tempEnd - entryDelegate.tempStart) + qsTr(" minutes") + ")"
                typography: Typography.Caption
                color: checked ? Colors.proxy.textOnAccentColor : Colors.proxy.textColor
                opacity: 0.7
            }
        }
        // Text {
        //     visible: content.expanded
        //     text: `${minutesToTime(entryDelegate.tempStart)} - ${minutesToTime(entryDelegate.tempEnd)}` +
        //         "    (" +(entryDelegate.tempEnd - entryDelegate.tempStart) + qsTr(" minutes") + ")"
        //     typography: Typography.Caption
        //     color: checked ? Colors.proxy.textOnAccentColor : Colors.proxy.textColor
        //     opacity: 0.7
        // }
    }

    Timer {
        id: updateTimer
        interval: 300
        onTriggered: {
            // 验证时间范围：结束时间不能早于开始时间
            if (entryDelegate.tempEnd <= entryDelegate.tempStart) {
                // 重置为原来的时间
                entryDelegate.tempStart = parseTime(entry.startTime)
                entryDelegate.tempEnd = parseTime(entry.endTime)
                
                // 显示错误提示
                floatLayer.createInfoBar({
                    title: qsTr("Invalid Time Range"),
                    text: qsTr("End time must be later than start time."),
                    severity: Severity.Error
                })
                return
            }
            
            entry.startTime = minutesToTime(entryDelegate.tempStart)
            entry.endTime = minutesToTime(entryDelegate.tempEnd)
            AppCentral.scheduleEditor.updateEntry(
                entry.id, entry.type, entry.startTime, entry.endTime,
                entry.subjectId, entry.title
            )
        }
    }
    
    function commitUpdate() {
        updateTimer.restart()
    }

    function updateListHoverState() {
        if (listViewRoot) {
            listViewRoot.selectedEntryHovered = checked && hoverHandler.hovered
        }
    }

    function parseTime(t) {
        let parts = t.split(":")
        return parseInt(parts[0]) * 60 + parseInt(parts[1])
    }
    function minutesToTime(m) {
        let h = Math.floor(m / 60)
        let mm = m % 60
        return (h < 10 ? "0" : "") + h + ":" + (mm < 10 ? "0" : "") + mm
    }
}
