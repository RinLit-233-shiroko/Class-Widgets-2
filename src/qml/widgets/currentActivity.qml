import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme
import Qt5Compat.GraphicalEffects

Widget {
    id: root
    text: qsTr("Current Activity")

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
        // layer.effect: RadialGradient {
        //     anchors.fill: circle
        //     gradient: Gradient {
        //         GradientStop { position: 0.0; color: Qt.alpha(currentColor, 0.4) }
        //         GradientStop { position: 0.05; color: Qt.alpha(currentColor, 0.45) }
        //         GradientStop { position: 0.25; color: Qt.alpha(currentColor, 0.12) }
        //         GradientStop { position: 0.5; color: Qt.alpha(currentColor, 0) }
        //     }
        // }
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
            text: AppCentral.scheduleRuntime.currentEntry.title
                || AppCentral.scheduleRuntime.currentSubject.name
                || (AppCentral.scheduleRuntime.currentStatus === "class"
                  ? qsTr("Class")
                    : AppCentral.scheduleRuntime.currentStatus === "activity"
                  ? qsTr("Activity")
                    : AppCentral.scheduleRuntime.currentStatus === "break"
                  ? qsTr("Take a break")
                    : qsTr("Nothing right now"))
        }
    }

    // 动画
    Behavior on currentColor { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad;} }
}