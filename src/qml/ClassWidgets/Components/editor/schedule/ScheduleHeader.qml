import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

Item {
    id: root

    required property date weekStart
    required property real itemWidth
    required property real contentX

    implicitHeight: 60

    function isToday(date) {
        var now = new Date()
        return date.getFullYear() === now.getFullYear()
            && date.getMonth() === now.getMonth()
            && date.getDate() === now.getDate()
    }

    function columnDate(columnIndex) {
        return new Date(weekStart.getTime() + columnIndex * 86400000)
    }

    // A CJK short month name is bare digits, which reads as a number rather
    // than as a month name, so those locales fall back to the written name.
    // Latin locales keep their abbreviation, uppercased ("SEP").
    function monthLabel(month) {
        const shortName = Qt.locale().monthName(month, Locale.ShortFormat)
        return /\d/.test(shortName)
            ? Qt.locale().monthName(month, Locale.LongFormat)
            : shortName.toUpperCase()
    }

    x: -contentX

    Row {
        anchors.fill: parent

        Repeater {
            model: 7
            delegate: Item {
                id: dayHeaderDelegate
                width: root.itemWidth
                height: parent.height

                property date dayDate: root.columnDate(index)
                property bool showMonth: dayDate.getDate() === 1
                property bool isToday: root.isToday(dayDate)

                // 日期圆 + 星期名（横排，垂直居中）
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: dayHeaderDelegate.isToday ? 6 : 0

                    // 日期圆
                    Item {
                        width: 36
                        height: 36

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            // color: Colors.proxy.primaryColor
                            color: dayHeaderDelegate.isToday ? Colors.proxy.primaryColor : "transparent"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayHeaderDelegate.dayDate.getDate()
                            // font.pixelSize: 14
                            color: dayHeaderDelegate.isToday ? Colors.proxy.textOnAccentColor : Colors.proxy.textColor
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 1
                            text: root.monthLabel(dayHeaderDelegate.dayDate.getMonth())
                            font.pixelSize: 8
                            color: dayHeaderDelegate.isToday ? Colors.proxy.textOnAccentColor : Colors.proxy.textSecondaryColor
                            visible: dayHeaderDelegate.showMonth
                        }
                    }

                    // 星期名
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.locale().dayName(dayHeaderDelegate.dayDate.getDay() === 0 ? 7 : dayHeaderDelegate.dayDate.getDay(), Locale.ShortFormat)
                        color: Colors.proxy.textColor
                        // font.pixelSize: 12
                    }
                }
            }
        }
    }
}
