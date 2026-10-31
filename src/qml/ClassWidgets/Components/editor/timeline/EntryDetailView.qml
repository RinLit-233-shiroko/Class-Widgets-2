import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

Flyout {
    id: root
    property var currentEntry: null
    property Item sourceItem: null
    property Item acrylicSourceItem: null
    property var subjects: AppCentral.scheduleRuntime.subjects || []
    readonly property real anchorY: {
        if (!sourceItem)
            return y
        const scene = sourceItem.mapToItem(null, 0, 0)
        const overlay = Overlay.overlay
        if (!overlay || !parent)
            return scene.y
        const origin = sourceItem.mapToItem(overlay, 0, 0)
        const local = overlay.mapToItem(parent, 0, origin.y)
        return Math.max(8, Math.min(
            parent.height - height - 8,
            local.y
        ))
    }

    background: Item {
        id: backgroundContainer
        clip: true

        layer.enabled: true
        layer.effect: Shadow {
            style: "flyout"
            source: backgroundContainer
        }

        AcrylicBrush {
            anchors.fill: parent
            sourceItem: root.acrylicSourceItem || root.sourceItem
            enabled: sourceItem !== null
            radius: parent.radius || 8
            z: 0
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius || 8
            color: "transparent"
            border.color: Theme.currentTheme.colors.flyoutBorderColor
            border.width: 1
            z: 1
        }
    }


    function refresh(entry) {
        if (!entry) return;

        root.currentEntry = entry
        entryId.text = currentEntry.id || ""
        entrySubject.subjectId = currentEntry.subjectId || ""
        entryTitle.text = currentEntry.title || ""

        Qt.callLater(function() {
            startTimePicker.setTime(currentEntry.startTime || "08:00")
            endTimePicker.setTime(currentEntry.endTime || "09:00")

            if (currentEntry.type === "class") btnClass.checked = true
            else if (currentEntry.type === "break") btnBreak.checked = true
            else btnActivity.checked = true

            // Wait for the new card's geometry before asking Popup to place
            // itself; otherwise a freshly inserted entry can anchor on stale
            // coordinates and choose the wrong side of the timeline.
            root.open()
        });
    }

    function alignToAnchorPoint() {
        y = anchorY
    }

    function applyChanges() {
        if (!currentEntry) return false

        const newType = typeSegmented.currentIndex === 0 ? "class"
                  : typeSegmented.currentIndex === 1 ? "break"
                  : "activity"

        const startTime = startTimePicker.time.toString("hh:mm")
        const endTime = endTimePicker.time.toString("hh:mm")

        if (endTime <= startTime) {
            floatLayer.createInfoBar({
                title: qsTr("Invalid Time Range"),
                text: qsTr("End time must be later than start time."),
                severity: Severity.Error
            })

            Qt.callLater(function() {
                startTimePicker.setTime(currentEntry.startTime || "08:00")
                endTimePicker.setTime(currentEntry.endTime || "09:00")
            })
            return false
        }

        const result = AppCentral.scheduleEditor.updateEntryChecked(
            currentEntry.id, newType,
            startTime,
            endTime,
            entrySubject.subjectId || null,
            entryTitle.text || null
        )
        if (!result.ok) {
            if (result.reason === "conflict") {
                const conflict = result.conflict
                floatLayer.createInfoBar({
                    title: qsTr("Conflict with existing schedule"),
                    text: qsTr("This time overlaps with an existing schedule (%1 – %2)")
                        .arg(conflict ? conflict.startTime : "")
                        .arg(conflict ? conflict.endTime : ""),
                    severity: Severity.Warning
                })
            }
            return false
        }
        return true
    }

    anchorItem: root.sourceItem
    position: Position.Right
    width: Math.min(320,
        Overlay.overlay ? Overlay.overlay.width - 48 : 320)
    onOpened: alignToAnchorPoint()
    onAnchorYChanged: {
        if (opened)
            Qt.callLater(alignToAnchorPoint)
    }

    Connections {
        target: root.sourceItem
        function onYChanged() {
            if (root.opened)
                Qt.callLater(root.alignToAnchorPoint)
        }
        function onHeightChanged() {
            if (root.opened)
                Qt.callLater(root.alignToAnchorPoint)
        }
    }

    enter: Transition {
        SequentialAnimation {
            // Let Popup's deferred auto-reposition run before overriding y.
            PauseAnimation { duration: 16 }
            ScriptAction {
                script: root.alignToAnchorPoint()
            }
            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Utils.appearanceSpeed
                    easing.type: Easing.OutQuint
                }
                NumberAnimation {
                    target: root
                    property: "x"
                    from: root.posX + (root._resolvedPosition === Position.Left
                        ? 15 : root._resolvedPosition === Position.Right ? -15 : 0)
                    to: root.posX
                    duration: Utils.animationSpeedMiddle * 1.25
                    easing.type: Easing.OutQuint
                }
            }
        }
    }
    // width: 460

    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true

        // Button {
        //     Layout.alignment: Qt.AlignRight
        //     icon.name: "ic_fluent_dismiss_20_regular"
        //     flat: true
        //     onClicked: root.close()
        // }

        // Text {
        //     typography: Typography.Subtitle
        //     text: {
        //         let result = qsTr("Edit ")
        //         if (entryTitle.text) {
        //             result += entryTitle.text
        //             return result
        //         }
        //         if (entrySubject.checkedId) {
        //             result += entrySubject.text
        //             return result
        //         }
        //         switch (typeSegmented.currentIndex) {
        //             case 0: result += qsTr("Class"); break
        //             case 1: result += qsTr("Break"); break
        //             case 2: result += qsTr("Activity"); break
        //             default: result += qsTr("Unknown Type")
        //         }
        //         return result
        //     }
        // }

        // 类型选择
        ButtonGroup {
            id: typeSegmented
            readonly property int currentIndex: checkedButton ? checkedButton.index : -1
        }

        RowLayout {
            Layout.fillWidth: true

            RadioButton {
                id: btnClass
                text: qsTr("Class"); icon.name: "ic_fluent_calendar_20_regular"
                ButtonGroup.group: typeSegmented
                property int index: 0
            }
            RadioButton {
                id: btnBreak
                text: qsTr("Break"); icon.name: "ic_fluent_clock_sparkle_20_regular"
                ButtonGroup.group: typeSegmented
                property int index: 1
            }
            RadioButton {
                id: btnActivity
                text: qsTr("Activity"); icon.name: "ic_fluent_shifts_activity_20_regular"
                ButtonGroup.group: typeSegmented
                property int index: 2
            }
        }

        RowLayout {
            Text { text: qsTr("ID"); width: 80 }
            TextField {
                id: entryId
                Layout.fillWidth: true
                readOnly: true
            }
            visible: false
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                id: subjectGroup
                spacing: 8
                visible: typeSegmented.currentIndex === 0

                Text { text: qsTr("Subject") }
                SubjectPickerButton {
                    id: entrySubject
                    Layout.preferredWidth: 95
                    Layout.minimumWidth: 80
                    subjects: root.subjects
                    placeholderText: qsTr("Select")
                    onSubjectSelected: entrySubject.subjectId = subjectId
                }

                onVisibleChanged: {
                    if (!visible)
                        entrySubject.subjectId = ""
                }
            }

            Text { text: qsTr("Title") }

            TextField {
                id: entryTitle
                Layout.fillWidth: true
                Layout.minimumWidth: 100
                placeholderText: {
                    switch (typeSegmented.currentIndex) {
                        case 0:
                            return qsTr("Class")
                        case 1:
                            return qsTr("Break")
                        case 2:
                            return qsTr("Activity")
                        default:
                            return qsTr("Type a title")
                    }
                }
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
            }
        }

        // Item {
        //     Layout.fillHeight: true
        // }


    }

    buttonBox: [
        Button {
            highlighted: true
            icon.name: "ic_fluent_checkmark_20_regular"
            text: qsTr("OK")
            onClicked: {
                if (root.applyChanges())
                    root.close()
            }
        },
        Button {
            Layout.alignment: Qt.AlignRight
            icon.name: "ic_fluent_delete_20_regular"
            text: qsTr("Remove")
            onClicked: {
                AppCentral.scheduleEditor.removeEntry(currentEntry.id)
                root.close()
            }
        }
    ]
}
