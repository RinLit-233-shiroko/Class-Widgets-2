import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root

    // 时间数据，由内置 backend.getDateTime() 返回
    property var dateTime: {
        "year": 1900,
        "month": 1,
        "day": 1,
        "weekday": 0,
        "hour": 0,
        "minute": 0,
        "second": 0
    }

    // —— 组件设置（见 widgets/settings/Time.qml）；未配置时按官方原有观感处理 ——
    readonly property bool animated: !settings || settings.digit_animation !== false
    readonly property bool showSeconds: !settings || settings.show_seconds !== false
    // 日期/星期副标题属于新增增强，默认关闭，保持官方外观
    readonly property bool showDate: settings && settings.show_date === true
    readonly property bool showYear: !settings || settings.show_year !== false
    readonly property bool showMonth: !settings || settings.show_month !== false
    readonly property bool showDay: !settings || settings.show_day !== false
    readonly property bool showWeekday: settings && settings.show_weekday === true
    readonly property bool alternateLayout: settings && settings.title_mode === "alternate"
    readonly property int alternateInterval: settings && settings.alternate_interval ? settings.alternate_interval : 3000
    readonly property bool alternateAnimation: settings && settings.alternate_animation === true
    readonly property int fadeDuration: alternateAnimation ? 300 : 0

    // —— 标题：沿用官方行为，日期与星期每 3 秒交替 ——
    property int titleMode: 0

    text: {
        let jsDate = new Date(dateTime.year, dateTime.month - 1, dateTime.day)

        if (titleMode === 0) {
            let localDate = Qt.locale().toString(jsDate, "MMMM d")
            return enabled ? localDate : dateTime.month + "/" + dateTime.day
        } else {
            return Qt.locale().dayName(dateTime.weekday, Locale.LongFormat)
        }
    }

    Timer {
        id: titleTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.titleMode = (root.titleMode + 1) % 2
    }

    // 交替模式下当前是否显示星期那一行
    property bool showWeekdayLine: false

    // 按设置拼接日期，格式交给 Qt.locale()，不拼死年月日
    function dateString() {
        let parts = []
        if (showYear) parts.push("yyyy")
        if (showMonth) parts.push("MMMM")
        if (showDay) parts.push("d")
        if (parts.length === 0) return ""
        let jsDate = new Date(dateTime.year, dateTime.month - 1, dateTime.day)
        return Qt.locale().toString(jsDate, parts.join(" "))
    }

    function weekdayString() {
        return Qt.locale().dayName(dateTime.weekday, Locale.LongFormat)
    }

    // 日期总开关开启且至少展示一个日期部分
    function hasDate() {
        return showDate && root.dateString() !== ""
    }

    // 标题区：并排模式单行展示；交替模式锁定宽度（取两者较宽），居中轮流切换
    subtitle: [
        Subtitle {
            id: combinedText
            visible: !root.alternateLayout
            text: {
                if (root.hasDate() && root.showWeekday)
                    return root.dateString() + "  " + root.weekdayString()
                if (root.hasDate()) return root.dateString()
                if (root.showWeekday) return root.weekdayString()
                return ""
            }
        },
        Item {
            visible: root.alternateLayout
            implicitWidth: Math.max(dateText.implicitWidth, weekText.implicitWidth)
            implicitHeight: Math.max(dateText.implicitHeight, weekText.implicitHeight)

            Subtitle {
                id: dateText
                anchors.centerIn: parent
                text: root.dateString()
                visible: root.hasDate()
                opacity: (!root.hasDate() || !root.showWeekday)
                         ? 1
                         : (root.showWeekdayLine ? 0 : 1)
                Behavior on opacity {
                    NumberAnimation { duration: root.fadeDuration; easing.type: Easing.OutQuad }
                }
            }
            Subtitle {
                id: weekText
                anchors.centerIn: parent
                text: root.weekdayString()
                visible: root.showWeekday
                opacity: (!root.hasDate() || !root.showWeekday)
                         ? 1
                         : (root.showWeekdayLine ? 1 : 0)
                Behavior on opacity {
                    NumberAnimation { duration: root.fadeDuration; easing.type: Easing.OutQuad }
                }
            }
        }
    ]

    // 交替展示定时器
    Timer {
        id: alternateTimer
        interval: Math.max(500, root.alternateInterval)
        running: root.hasDate() && root.showWeekday && root.alternateLayout
        repeat: true
        onTriggered: root.showWeekdayLine = !root.showWeekdayLine
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
            dateTime = backend.getDateTime()
        })
    }
}
