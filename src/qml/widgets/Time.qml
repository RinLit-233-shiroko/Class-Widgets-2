import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root

    property var dateTime: {
        "year": 1900,
        "month": 1,
        "day": 1,
        "weekday": 0,
        "hour": 0,
        "minute": 0,
        "second": 0
    }

    readonly property bool animated: !settings || settings.digit_animation !== false
    readonly property bool showSeconds: !settings || settings.show_seconds !== false
    readonly property bool showDate: settings && settings.show_date === true
    readonly property bool showYear: !settings || settings.show_year !== false
    readonly property bool showMonth: !settings || settings.show_month !== false
    readonly property bool showDay: !settings || settings.show_day !== false
    readonly property bool showWeekday: settings && settings.show_weekday === true
    readonly property bool alternateLayout: settings && settings.title_mode === "alternate"
    readonly property int alternateInterval: settings && settings.alternate_interval ? settings.alternate_interval : 3000

    property int titleMode: 0

    // Build the date from the date parts enabled in settings and let Qt.locale()
    // paint the pattern, so the year is shown in every locale (e.g. "2026 十月 25").
    function dateString() {
        if (!showDate)
            return ""
        let parts = []
        if (showYear) parts.push("yyyy")
        if (showMonth) parts.push("MMMM")
        if (showDay) parts.push("d")
        if (parts.length === 0)
            return ""
        let jsDate = new Date(dateTime.year, dateTime.month - 1, dateTime.day)
        return Qt.locale().toString(jsDate, parts.join(" "))
    }

    function weekdayString() {
        return Qt.locale().dayName(dateTime.weekday, Locale.LongFormat)
    }

    text: {
        let datePart = dateString()
        let weekPart = showWeekday ? weekdayString() : ""
        if (datePart !== "" && weekPart !== "") {
            if (alternateLayout)
                return titleMode === 0 ? datePart : weekPart
            return datePart + "  " + weekPart
        }
        return datePart !== "" ? datePart : weekPart
    }

    Timer {
        id: titleTimer
        interval: Math.max(500, alternateInterval)
        running: root.alternateLayout && root.showDate && root.showWeekday
        repeat: true
        onTriggered: root.titleMode = (root.titleMode + 1) % 2
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 0

        Loader {
            id: hourDigits
            sourceComponent: root.animated ? animatedHour : staticHour
        }
        Title {
            Layout.bottomMargin: font.pixelSize * 0.1
            text: ":"
        }
        Loader {
            id: minuteDigits
            sourceComponent: root.animated ? animatedMinute : staticMinute
        }
        Title {
            Layout.bottomMargin: font.pixelSize * 0.1
            text: ":"
            visible: root.showSeconds
        }
        Loader {
            id: secondDigits
            sourceComponent: root.animated ? animatedSecond : staticSecond
            visible: root.showSeconds
        }

        Timer {
            interval: 500
            running: true
            repeat: true
            onTriggered: {
                dateTime = backend.getDateTime()
            }
        }
    }

    Component {
        id: animatedHour
        AnimatedDigits {
            value: dateTime.hour || "00"
        }
    }
    Component {
        id: animatedMinute
        AnimatedDigits {
            value: dateTime.minute || "00"
        }
    }
    Component {
        id: animatedSecond
        AnimatedDigits {
            value: dateTime.second || "00"
        }
    }
    Component {
        id: staticHour
        Title {
            text: dateTime.hour || "00"
        }
    }
    Component {
        id: staticMinute
        Title {
            text: dateTime.minute || "00"
        }
    }
    Component {
        id: staticSecond
        Title {
            text: dateTime.second || "00"
        }
    }

    Component.onCompleted: {
        Qt.callLater(function() {
            if (backend) dateTime = backend.getDateTime()
        })
    }
}
