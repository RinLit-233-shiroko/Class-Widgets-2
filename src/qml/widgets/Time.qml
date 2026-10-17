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
    readonly property bool alternateLayout: settings && settings.title_mode === "alternate"
    readonly property int alternateInterval: settings && settings.alternate_interval ? settings.alternate_interval : 3000

    // —— 标题：并排模式同屏显示日期与星期，交替模式按设定间隔轮流切换 ——
    property int titleMode: 0

    text: {
        let jsDate = new Date(dateTime.year, dateTime.month - 1, dateTime.day)
        let datePart = enabled
            ? Qt.locale().toString(jsDate, "MMMM d")
            : dateTime.month + "/" + dateTime.day
        let weekPart = Qt.locale().dayName(dateTime.weekday, Locale.LongFormat)

        if (!alternateLayout)
            return datePart + "  " + weekPart
        return titleMode === 0 ? datePart : weekPart
    }

    Timer {
        id: titleTimer
        interval: Math.max(500, alternateInterval)
        running: alternateLayout
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
            // backend 可能尚未注入，稍后才可用，此处不能直接解引用
            if (backend) dateTime = backend.getDateTime()
        })
    }
}
