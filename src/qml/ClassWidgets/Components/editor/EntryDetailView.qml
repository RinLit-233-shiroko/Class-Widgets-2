import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

ColumnLayout {
    id: root
    property var currentEntry: null
    property var subjects: AppCentral.scheduleRuntime.subjects || []

    function subjectIdByName(name) {
        for (let i = 0; i < subjects.length; i++) {
            if (subjects[i].name === name) return subjects[i].id
        }
        return null
    }

    function refresh(entry) {
        if (!entry) {
            currentEntry = null
            return;
        }
        
        Qt.callLater(function() {
            root.currentEntry = entry
            entryId.text = currentEntry.id || ""
            entrySubject.checkedId = currentEntry.subjectId || null
            entryTitle.text = currentEntry.title || ""

            Qt.callLater(function() {
                startTimePicker.setTime(currentEntry.startTime || "08:00")
                endTimePicker.setTime(currentEntry.endTime || "09:00")

                if (currentEntry.type === "class") typeSegmented.currentIndex = 0
                else if (currentEntry.type === "break") typeSegmented.currentIndex = 1
                else typeSegmented.currentIndex = 2
            });
        });
    }

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: {
            if (!currentEntry) return;
            
            const newType = typeSegmented.currentIndex === 0 ? "class"
                          : typeSegmented.currentIndex === 1 ? "break"
                          : "activity"

            const startTime = startTimePicker.time.toString("hh:mm")
            const endTime = endTimePicker.time.toString("hh:mm")
            
            // 验证时间范围：结束时间不能早于开始时间
            if (endTime <= startTime) {
                // 显示错误提示
                floatLayer.createInfoBar({
                    title: qsTr("Invalid Time Range"),
                    text: qsTr("End time must be later than start time."),
                    severity: Severity.Error
                })
                
                // 重置为原来的时间
                Qt.callLater(function() {
                    startTimePicker.setTime(currentEntry.startTime || "08:00")
                    endTimePicker.setTime(currentEntry.endTime || "09:00")
                })
                return
            }

            AppCentral.scheduleEditor.updateEntry(
                currentEntry.id, newType,
                startTime,
                endTime,
                entrySubject.checkedId || null,
                entryTitle.text || null
            )
        }
    }
    
    function saveChanges() {
        saveTimer.restart()
    }

    visible: currentEntry
    spacing: 12
    Layout.fillWidth: true
    Layout.fillHeight: true

    Button {
        Layout.alignment: Qt.AlignRight
        icon.name: "ic_fluent_dismiss_20_regular"
        flat: true
        onClicked: {
            currentEntry = null
            entryList.currentIndex = -1
        }
    }

    Text {
        typography: Typography.Subtitle
        text: {
            let result = qsTr("Edit ")
            if (entryTitle.text) {
                result += entryTitle.text
                return result
            }
            if (entrySubject.checkedId) {
                result += entrySubject.text
                return result
            }
            switch (typeSegmented.currentIndex) {
                case 0: result += qsTr("Class"); break
                case 1: result += qsTr("Break"); break
                case 2: result += qsTr("Activity"); break
                default: result += qsTr("Unknown Type")
            }
            return result
        }
    }

    // 类型选择
    Segmented {
        id: typeSegmented
        Layout.fillWidth: true
        onCurrentIndexChanged: root.saveChanges()

        SegmentedItem { text: qsTr("Class"); icon.name: "ic_fluent_calendar_20_regular" }
        SegmentedItem { text: qsTr("Break"); icon.name: "ic_fluent_clock_sparkle_20_regular" }
        SegmentedItem { text: qsTr("Activity"); icon.name: "ic_fluent_shifts_activity_20_regular" }
    }

    RowLayout {
        Layout.fillWidth: true
        Text { text: qsTr("ID"); width: 80 }
        TextField {
            id: entryId
            Layout.fillWidth: true
            readOnly: true
        }
    }

    RowLayout {
        visible: typeSegmented.currentIndex === 0
        Text { text: qsTr("Default Subject");}

        Item { Layout.fillWidth: true }

        DropDownButton {
            id: entrySubject
            text: checkedId ? AppCentral.scheduleEditor.subjectNameById(checkedId) : qsTr("Select Subject")
            property string checkedId: ""
            onClicked: subjectsFlyout.open()

            Flyout {
                id: subjectsFlyout
                position: Position.Left
                width: 300

                Flow {
                    Layout.fillWidth: true
                    ButtonGroup {
                        id: subjectsGroup
                        exclusive: true
                    }
                    Repeater {
                        model: root.subjects
                        ToggleButton {
                            property string checkedId: modelData.id
                            icon.name: modelData.icon
                            text: modelData.name
                            flat: true
                            ButtonGroup.group: subjectsGroup
                        }
                    }
                }

                buttonBox: Button {
                    highlighted: true
                    text: qsTr("Set Subject")
                    onClicked: {
                        entrySubject.checkedId = subjectsGroup.checkedButton.checkedId
                        saveChanges()
                        subjectsFlyout.close()
                    }
                }
            }
        }

        onVisibleChanged: {
            if (!visible) entrySubject.checkedId = null
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text { text: qsTr("Title"); width: 80 }

        Item { Layout.fillWidth: true }

        TextField {
            id: entryTitle
            Layout.minimumWidth: 200
            onTextChanged: root.saveChanges()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Text { text: qsTr("Start Time") }

        Item { Layout.fillWidth: true }

        TimePicker {
            id: startTimePicker
            Layout.preferredWidth: 200
            use24Hour: true
            onTimeChanged: root.saveChanges()
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Text { text: qsTr("End Time") }

        Item { Layout.fillWidth: true }

        TimePicker {
            id: endTimePicker
            Layout.preferredWidth: 200
            use24Hour: true
            onTimeChanged: root.saveChanges()
        }
    }

    Item {
        Layout.fillHeight: true
    }

    Button {
        Layout.alignment: Qt.AlignRight
        icon.name: "ic_fluent_delete_20_regular"
        text: qsTr("Remove")
        onClicked: {
            AppCentral.scheduleEditor.removeEntry(currentEntry.id)
        }
    }
}
