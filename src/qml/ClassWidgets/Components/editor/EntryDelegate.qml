import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Clip {
    id: entryDelegate
    property int index
    property var entry
    property real pxPerMin
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

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutQuint
            }
        }
    }

    property int tempStart: parseTime(entry.startTime)
    property int tempEnd: parseTime(entry.endTime)

    x: 52
    width: parent.width - x
    y: tempStart * pxPerMin
    height: (tempEnd - tempStart) * pxPerMin + 1

    HoverHandler {
        id: hoverHandler
    }

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

    onClicked: currentIndex = entryDelegate.index

    // 上拖拽调整
    Item {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width / 6
        height: 8

        Rectangle {
            anchors.top: parent.top
            anchors.margins: 3
            width: parent.width
            height: 3
            radius: height / 2
            color: Qt.alpha("white", 0.4)
        }

        DragHandler {
            target: null
            yAxis.enabled: true
            grabPermissions: PointerHandler.CanTakeOverFromAnything  // 优先级
            onTranslationChanged: {
                let deltaMins = Math.round(translation.y / pxPerMin / 5) * 5
                let newStart = parseTime(entry.startTime) + deltaMins
                if (newStart < entryDelegate.tempEnd - 5) {
                    entryDelegate.tempStart = newStart
                }
            }
            onActiveChanged: if (!active) commitUpdate()
        }

        HoverHandler {
            cursorShape: Qt.SizeVerCursor
        }
    }

    // 下拖拽调整时间
    Item {
        width: parent.width / 6
        height: 8
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.margins: 3
            width: parent.width
            height: 3
            radius: height / 2
            color: Qt.alpha("white", 0.4)
        }

        DragHandler {
            target: null
            yAxis.enabled: true
            grabPermissions: PointerHandler.CanTakeOverFromAnything
            onTranslationChanged: {
                let deltaMins = Math.round(translation.y / pxPerMin / 5) * 5
                let newEnd = parseTime(entry.endTime) + deltaMins
                if (newEnd > entryDelegate.tempStart + 5) {
                    entryDelegate.tempEnd = newEnd
                }
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
        enabled: checked
        target: null
        yAxis.enabled: true
        // grabPermissions: PointerHandler.TakeOverForbidden

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
        anchors.verticalCenter: !expanded ? parent.verticalCenter : undefined
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
                visible: !content.expanded
                text: `${minutesToTime(entryDelegate.tempStart)} - ${minutesToTime(entryDelegate.tempEnd)}` +
                    "    (" +(entryDelegate.tempEnd - entryDelegate.tempStart) + qsTr(" minutes") + ")"
                typography: Typography.Caption
                color: checked ? Colors.proxy.textOnAccentColor : Colors.proxy.textColor
                opacity: 0.7
            }
        }
        Text {
            visible: content.expanded
            text: `${minutesToTime(entryDelegate.tempStart)} - ${minutesToTime(entryDelegate.tempEnd)}` +
                "    (" +(entryDelegate.tempEnd - entryDelegate.tempStart) + qsTr(" minutes") + ")"
            typography: Typography.Caption
            color: checked ? Colors.proxy.textOnAccentColor : Colors.proxy.textColor
            opacity: 0.7
        }
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
