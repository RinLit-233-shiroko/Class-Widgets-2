import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme
import Qt5Compat.GraphicalEffects

Widget {
    id: root
    text: qsTr("Upcoming")
    property bool isExternalClass: AppCentral.scheduleRuntime.currentSubject.isLocalClassroom === false
    property bool showLeaveHint: false

    property var entries: AppCentral.scheduleRuntime.nextEntries || []
    property var subjects: AppCentral.scheduleRuntime.subjects || []
    property int entriesLength: {
        if (entries.length !== 0 && settings.max_activities !== null) {
            return entries.length < settings.max_activities ? entries.length : settings.max_activities
        } else {
            return 0
        }
    }
    property string title: {
        let result = ""
        for (let i = 0; i < entriesLength; i++) {
            let entry = entries[i]
            let entryText = entry.title
                            || subjectNameById(entry.subjectId)
                            || (entry.type === "class" ? qsTr("Class")
                                : entry.type === "activity" ? qsTr("Activity")
                                : qsTr("Unset"))
            result += entryText + (i === entries.length - 1 ? "" : "  ")
        }
        if (!result) {
            return qsTr("Nothing ahead")
        }
        return result
    }

    function subjectNameById(id) {
        for (let i = 0; i < subjects.length; i++) {
            if (subjects[i].id === id) {
                if (!settings.full_name) {
                    return subjects[i].simplifiedName || subjects[i].name.substring(0, 3)
                }
                return subjects[i].name
            }
        }
        return null
    }

    MarqueeTitle {
        visible: settings && settings.marquee
        anchors.centerIn: parent
        width: 275
        text: root.title
    }

    Title {
        width: !settings || !settings.marquee ? implicitWidth : 0
        visible: !settings || !settings.marquee
        anchors.centerIn: parent
        text: root.title
    }
}