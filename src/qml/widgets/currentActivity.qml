import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme
import Qt5Compat.GraphicalEffects

Widget {
    id: root
    property string customTitle: AppCentral.scheduleRuntime.currentEntry.title || ""
    property string subjectName: AppCentral.scheduleRuntime.currentSubject.name || ""
    property string displayMode: settings && settings.display_mode
        ? settings.display_mode : "alternate"
    property int alternateInterval: {
        var value = settings ? Number(settings.alternate_interval) : 3
        return isNaN(value) ? 3 : Math.max(2, Math.min(10, value))
    }
    property bool showTitleInAlternateMode: true

    text: {
        AppCentral.translator.language
        return qsTr("Current Activity")
    }

    function fallbackText() {
        if (AppCentral.scheduleRuntime.currentStatus === "class") return qsTr("Class")
        if (AppCentral.scheduleRuntime.currentStatus === "activity") return qsTr("Activity")
        if (AppCentral.scheduleRuntime.currentStatus === "break") return qsTr("Take a break")
        return qsTr("Nothing right now")
    }

    function displayedActivityText() {
        if (displayMode === "title") return customTitle || subjectName || fallbackText()
        if (displayMode === "subject") return subjectName || customTitle || fallbackText()
        if (customTitle && subjectName) {
            return showTitleInAlternateMode ? customTitle : subjectName
        }
        return customTitle || subjectName || fallbackText()
    }

    function resetAlternateMode() {
        showTitleInAlternateMode = true
    }

    onCustomTitleChanged: resetAlternateMode()
    onSubjectNameChanged: resetAlternateMode()
    onDisplayModeChanged: resetAlternateMode()

    Timer {
        id: alternateTimer
        interval: root.alternateInterval * 1000
        running: root.displayMode === "alternate" && root.customTitle !== ""
            && root.subjectName !== ""
        repeat: true
        onTriggered: root.showTitleInAlternateMode = !root.showTitleInAlternateMode
    }

    // property color currentColor: AppCentral.scheduleRuntime.currentSubject.color
    //     ? AppCentral.scheduleRuntime.currentSubject.color
    //     : (AppCentral.scheduleRuntime.currentStatus === "free" ? "#46CEA3" : "#D28B59")
    property color currentColor: {
        if (AppCentral.scheduleRuntime.currentSubject.color) {
            return AppCentral.scheduleRuntime.currentSubject.color
        }
        switch (AppCentral.scheduleRuntime.currentStatus) {
            case "free": case "break": return "#46CEA3"
            case "class": return "#D28B59"
            case "preparation": return "#9151d8"
            default: return "#605ed2"
        }
    }

    backgroundArea: Rectangle {
        id: circle
        width: root.height * 0.4
        height: root.height * 0.4
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + 8
        radius: height / 2
        color: currentColor
        visible: lightingEffect

        layer.enabled: true
        layer.effect: FastBlur {
            anchors.fill: circle
            radius: 64
            opacity: 0.5
            transparentBorder: true
        }
    }


    RowLayout {
        anchors.centerIn: parent
        spacing: 10
        Icon {
            // icon: AppCentral.scheduleRuntime.currentSubject.icon
            //     || AppCentral.scheduleRuntime.currentStatus === "free" ?
            //     "ic_fluent_accessibility_20_regular"
            //     : "ic_fluent_shifts_activity_20_filled"
            icon: {
                if (AppCentral.scheduleRuntime.currentSubject.icon) {
                    return AppCentral.scheduleRuntime.currentSubject.icon
                }
                switch (AppCentral.scheduleRuntime.currentStatus) {
                    case "free": return "ic_fluent_accessibility_20_regular"
                    case "break": return "ic_fluent_shifts_activity_20_filled"
                    case "class": return "ic_fluent_class_20_regular"
                    case "preparation": return "ic_fluent_hourglass_half_20_regular"
                    case "activity": return "ic_fluent_alert_20_regular"
                    default: return "ic_fluent_clock_dismiss_20_regular"
                }
            }
            size: miniMode ? 24 : 32
        }
        Title {
            text: root.displayedActivityText()
        }
    }

    // 动画
    Behavior on currentColor { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad;} }
}
