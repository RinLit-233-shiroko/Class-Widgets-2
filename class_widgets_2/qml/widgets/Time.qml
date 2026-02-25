import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root
    // text: qsTr("time")
    property var dateTime: {
        "year": 1900,
        "month": 1,
        "day": 1,
        "weekday": 0,
        "hour": 0,
        "minute": 0,
        "second": 0
    }

    property int titleMode: 0

    text: {
        let jsDate = new Date(dateTime.year, dateTime.month - 1, dateTime.day)

        if (titleMode === 0) {
            let localDate = Qt.locale().toString(jsDate, "MMMM d")
            return enabled ? localDate : dateTime.month + "/" + dateTime.day
        } else {
            let localDay = Qt.locale().dayName(dateTime.weekday, Locale.LongFormat)
            return localDay
        }
    }

    Timer {
        id: titleTimer
        interval: 3000   // 每 3 秒切换一次
        running: true
        repeat: true
        onTriggered: root.titleMode = (root.titleMode + 1) % 2
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 0
        AnimatedDigits {
            id: hour
            value: dateTime.hour || "00"
        }
        Title {
            Layout.bottomMargin: font.pixelSize * 0.1
            text: ":"
        }
        AnimatedDigits {
            id: minute
            value: dateTime.minute || "00"
        }
        Title {
            Layout.bottomMargin: font.pixelSize * 0.1
            text: ":"
        }
        AnimatedDigits {
            id: second
            value: dateTime.second || "00"
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

    Component.onCompleted: {
        Qt.callLater(function() {
            dateTime = backend.getDateTime()
        })
    }
}