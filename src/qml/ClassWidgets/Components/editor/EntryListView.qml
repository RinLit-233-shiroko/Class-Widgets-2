import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

ColumnLayout {
    id: root
    property int currentDayIndex: -1
    property var subjects: AppCentral.scheduleRuntime.subjects || []

    property real pxPerMin: zoomSlider.value

    // 暴露
    property int currentIndex: -1

    Layout.fillWidth: true
    Layout.fillHeight: true

    // 空白提示
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !flickable.visible

        ColumnLayout {
            width: parent.width
            anchors.centerIn: parent
            opacity: 0.5

            Icon {
                Layout.alignment: Qt.AlignCenter
                name: "ic_fluent_square_hint_sparkles_20_regular"
                size: 46
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                typography: Typography.BodyLarge
                text: qsTr("No timeline selected")
            }
            Text {
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                typography: Typography.Caption
                text: qsTr(
                    "Please select a timeline first to add a new schedule."
                )
            }
        }
    }

    // 时间轴
    Flickable {
        visible: currentDayIndex >= 0

        id: flickable
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentHeight: 24 * 60 * pxPerMin

        Behavior on contentY {
            NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
        }

        ScrollBar.vertical: ScrollBar {}

        // 时间线
        Repeater {
            model: 24 * 2
            delegate: Item {
                width: flickable.width
                height: 1
                y: index * 30 * pxPerMin  // 每30分钟

                // 刻度线
                Rectangle {
                    height: 1
                    width: parent.width
                    color: Colors.proxy.dividerBorderColor
                    opacity: index % 2 === 0 ? 1.0 : 0.4
                }

                Text {
                    visible: index % 2 === 0 && index !== 0
                    width: 48
                    text: {
                        let hour = index / 2
                        if (hour > 12) {
                            return hour + qsTr(" PM")
                        } else {
                            return hour === 0 ? "12 AM" : hour + qsTr(" AM")
                        }
                    }
                    horizontalAlignment: Text.AlignRight
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                }
            }
        }

        // 日程
        Repeater {
            id: entryList
            model: currentDayIndex >= 0 ? AppCentral.scheduleEditor.days[currentDayIndex].entries : []

            property int prevLength: 0

            onModelChanged: {
                if (prevLength !== model.length) {
                    currentIndex = -1
                }
                if (model.length === 0) {
                    currentIndex = -1
                }
                prevLength = model.length
            }
            
            delegate: EntryDelegate {
                index: model.index
                entry: modelData
                pxPerMin: root.pxPerMin
            }
        }
    }

    // 顶(huadiao 底部工具栏
    RowLayout {
        id: toolBar
        Layout.fillWidth: true
        spacing: 4
        property bool expanded: toolBar.width > 600
        enabled: currentDayIndex >= 0

        Button {
            flat: true
            icon.name: "ic_fluent_class_20_regular"
            text: qsTr("Class")
            onClicked: addEntry("class")
            visible: parent.expanded
        }

        Button {
            flat: true
            icon.name: "ic_fluent_drink_coffee_20_regular"
            text: qsTr("Break")
            onClicked: addEntry("break")
            visible: parent.expanded
        }

        Button {
            flat: true
            icon.name: "ic_fluent_alert_20_regular"
            text: qsTr("Activity")
            onClicked: addEntry("activity")
            visible: parent.expanded
        }

        DropDownButton {
            flat: true
            icon.name: "ic_fluent_add_20_regular"
            text: qsTr("New Schedule")
            visible: !parent.expanded

            MenuItem {
                icon.name: "ic_fluent_class_20_regular"
                text: qsTr("Class")
                onTriggered: addEntry("class")
            }

            MenuItem {
                icon.name: "ic_fluent_drink_coffee_20_regular"
                text: qsTr("Break")
                onTriggered: addEntry("break")
            }

            MenuItem {
                icon.name: "ic_fluent_alert_20_regular"
                text: qsTr("Activity")
                onTriggered: addEntry("activity")
            }
        }

        Item {
            Layout.fillWidth: true
        }


        Text {
            Layout.alignment: Qt.AlignCenter
            text: (zoomSlider.value * 80).toFixed() + "%"
        }
        Slider {
            id: zoomSlider
            from: 0.5
            to: 5
            stepSize: 0.05
            value: 1.25
            showTooltip: false
        }
    }


    function toTimeString(minutes) {
        let h = Math.floor(minutes / 60)
        let m = minutes % 60
        return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m)
    }

    function toMinutes(timeStr) {
        let parts = timeStr.split(":")
        return parseInt(parts[0]) * 60 + parseInt(parts[1])
    }

    function addEntry(type) {
        if (root.currentDayIndex < 0) return;

        let day = AppCentral.scheduleEditor.days[root.currentDayIndex]
        let entries = day.entries || []

        let startTimeMin = 8 * 60  // 默认 08:00
        let duration = Configs.data.schedule.default_duration.class_ || 40
        if (type === "break") duration = Configs.data.schedule.default_duration.break_ || 10
        else if (type === "activity") duration = Configs.data.schedule.default_duration.activity || 30

        if (entries.length > 0) {
            if (root.currentIndex >= 0) {
                let selected = entries[root.currentIndex]
                startTimeMin = toMinutes(selected.endTime)

                let endTimeMin = startTimeMin + duration
                for (let e of entries) {
                    let eStart = toMinutes(e.startTime)
                    let eEnd = toMinutes(e.endTime)

                    if (!(endTimeMin <= eStart || startTimeMin >= eEnd)) {  // 冲突
                        floatLayer.createInfoBar({
                            title: qsTr("Conflict with existing schedule"),
                            severity: Severity.Warning,
                            text: qsTr("This time overlaps with an existing schedule (%1 – %2)")
                                .arg(e.startTime).arg(e.endTime)
                        })
                        return
                    }
                }
            } else {
                let last = entries[entries.length - 1]
                startTimeMin = toMinutes(last.endTime)
            }
        }

        let endTimeMin = startTimeMin + duration
        let startTimeStr = toTimeString(startTimeMin)
        let endTimeStr = toTimeString(endTimeMin)

        // 获取新id
        let newId = AppCentral.scheduleEditor.addEntry(
            day.id,
            type,
            startTimeStr,
            endTimeStr,
            "",
            ""
        )

        // 选中新项
        if (newId) {
            let idx = day.entries.findIndex(e => e.id === newId)
            if (idx >= 0) {
                root.currentIndex = idx

                // 滚木
                let targetY = startTimeMin * pxPerMin
                flickable.contentY = Math.max(0, targetY - flickable.height / 3)
            }
        }
    }
}
