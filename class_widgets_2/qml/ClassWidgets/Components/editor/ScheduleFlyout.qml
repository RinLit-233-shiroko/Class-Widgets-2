import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Flyout {
    id: root
    property var entry: null
    property var selectedCell: null
    property var weekSelector: null

    property string currentSubjectId: ""
    property string currentTitle: ""

    position: Position.Right

    function getContext() {
        if (!entry || !selectedCell) return null;
        const weeks =
            weekSelector.selectedType === "all" ? "all"
            : weekSelector.selectedType === "round" ? weekSelector.currentWeek
            : [weekSelector.currentWeek];
        const dayOfWeek = [selectedCell.column + 1];
        return { weeks, dayOfWeek };
    }

    onEntryChanged: {
        currentSubjectId = entry && entry.subjectId ? entry.subjectId : "";
        currentTitle = entry && entry.title ? entry.title : "";
    }

    ColumnLayout {
        spacing: 12
        Layout.fillWidth: true

        ColumnLayout {
            spacing: 4
            Layout.fillWidth: true
            Text {
                text: qsTr("Edit")
                typography: Typography.BodyLarge
            }
            Text {
                text: {
                    if (entry) {
                        return entry.startTime + " - " + entry.endTime;
                    }
                    return "";
                }
                opacity: 0.5
                typography: Typography.Caption
                visible: entry
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: qsTr("Subject") }
            Item { Layout.fillWidth: true }

            DropDownButton {
                id: overrideSubjectBtn

                text: AppCentral.scheduleEditor.subjectNameById(root.currentSubjectId) || qsTr("Select Subject")
                onClicked: subjectsFlyout.open()

                Flyout {
                    id: subjectsFlyout
                    width: 300
                    position: Position.Left
                    Flow {
                        Layout.fillWidth: true
                        ButtonGroup { id: subjectsGroup; exclusive: true }

                        Repeater {
                            model: AppCentral.scheduleRuntime.subjects
                            ToggleButton {
                                property string sid: modelData.id
                                icon.name: modelData.icon
                                text: modelData.name
                                flat: true
                                ButtonGroup.group: subjectsGroup

                                // 通过 root.currentSubjectId 驱动 checked 状态（而不是依赖 JS 字段）
                                checked: sid === root.currentSubjectId

                                // 点击即生效：更新响应式属性并同步回 entry
                                onCheckedChanged: {
                                    if (checked) {
                                        root.currentSubjectId = sid;
                                        if (entry) entry.subjectId = sid; // 保持 entry 与 UI 同步
                                        subjectsFlyout.close();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: qsTr("Title") }
            Item { Layout.fillWidth: true }

            TextField {
                id: titleField
                Layout.minimumWidth: 200

                text: root.currentTitle

                onTextChanged: {
                    root.currentTitle = text;
                    if (entry) entry.title = text;
                }
            }
        }
    }

    buttonBox: [
        Button {
            highlighted: true
            text: qsTr("Set")
            onClicked: {
                const ctx = getContext();
                if (!ctx) return;

                const sid = root.currentSubjectId;
                const ttl = root.currentTitle;

                    const existingId = AppCentral.scheduleEditor.findOverride(entry.id, ctx.dayOfWeek, ctx.weeks);
                    if (existingId) {
                        AppCentral.scheduleEditor.updateOverride(existingId, sid, ttl);
                    } else {
                        AppCentral.scheduleEditor.addOverride(entry.id, ctx.dayOfWeek, ctx.weeks, sid, ttl);
                    }

                if (entry) {
                    entry.subjectId = sid;
                    entry.title = ttl;
                }

                root.close();
            }
        },
        Button {
            text: qsTr("Clear")
            onClicked: {
                const ctx = getContext();
                if (!ctx) return;

                const existingId = AppCentral.scheduleEditor.findOverride(entry.id, ctx.dayOfWeek, ctx.weeks);
                if (existingId) AppCentral.scheduleEditor.removeOverride(existingId);

                // 清空本地
                root.currentSubjectId = "";
                root.currentTitle = "";
                if (entry) {
                    entry.subjectId = "";
                    entry.title = "";
                }

                root.close();
            }
        }
    ]
}
