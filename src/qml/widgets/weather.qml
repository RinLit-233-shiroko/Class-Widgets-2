import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root
    text: qsTr("Weather")
    implicitWidth: miniMode ? 176 : 278

    property string displayMode: settings.display_mode || "temperature"
    property bool showCity: settings.show_city !== false
    property bool showForecast: settings.show_forecast !== false
    property string primaryValue: {
        if (!WeatherService.available)
            return "--"
        switch (displayMode) {
        case "humidity": return WeatherService.humidity + "%"
        case "wind": return Math.round(WeatherService.windSpeed) + " km/h"
        case "pressure": return Math.round(WeatherService.pressure) + " hPa"
        case "apparent": return Math.round(WeatherService.apparentTemperature) + "°"
        default: return Math.round(WeatherService.temperature) + "°"
        }
    }
    property string primaryLabel: {
        switch (displayMode) {
        case "humidity": return qsTr("Humidity")
        case "wind": return qsTr("Wind")
        case "pressure": return qsTr("Pressure")
        case "apparent": return qsTr("Feels like")
        default: return qsTr("Temperature")
        }
    }

    backgroundArea: Rectangle {
        width: root.height * 0.75
        height: width
        radius: width / 2
        x: parent.width - width * 0.7
        y: -height * 0.25
        color: WeatherService.available ? Theme.themeColor : "#7C8AA5"
        opacity: root.lightingEffect ? 0.20 : 0
        visible: opacity > 0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: miniMode ? 12 : 16
        anchors.rightMargin: miniMode ? 12 : 16
        spacing: miniMode ? 9 : 13

        Text {
            Layout.preferredWidth: miniMode ? 34 : 48
            Layout.preferredHeight: miniMode ? 34 : 48
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: WeatherService.loading ? "↻" : (WeatherService.available ? WeatherService.weatherIcon : "☁")
            font.pixelSize: miniMode ? 25 : 36
            rotation: WeatherService.loading ? 0 : 0

            RotationAnimation on rotation {
                running: WeatherService.loading
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 850
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Label {
                    Layout.fillWidth: true
                    visible: root.showCity && !miniMode
                    text: WeatherService.available ? WeatherService.city : qsTr("Weather")
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    color: Theme.isDark() ? "#B9C5DB" : "#67758C"
                }
                Label {
                    visible: WeatherService.available && !miniMode
                    text: WeatherService.updatedAt
                    font.pixelSize: 10
                    color: Theme.isDark() ? "#71809B" : "#9AA6B8"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Label {
                    text: root.primaryValue
                    font.pixelSize: miniMode ? 23 : 30
                    font.bold: true
                    color: Theme.isDark() ? "#F5F7FC" : "#1D2A3D"
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Label {
                        text: WeatherService.available ? WeatherService.weatherText : qsTr("Set a city in Weather settings")
                        elide: Text.ElideRight
                        font.pixelSize: miniMode ? 11 : 13
                        color: Theme.isDark() ? "#D6DEED" : "#3E4E66"
                    }
                    Label {
                        visible: !miniMode
                        text: root.primaryLabel
                        font.pixelSize: 10
                        color: Theme.isDark() ? "#8190A8" : "#8290A4"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.showForecast && !miniMode && WeatherService.available
                spacing: 8
                Label {
                    text: "↑" + Math.round(WeatherService.high) + "°  ↓" + Math.round(WeatherService.low) + "°"
                    font.pixelSize: 11
                    color: Theme.isDark() ? "#ACC9EB" : "#46739C"
                }
                Label {
                    text: "☂ " + WeatherService.precipitationProbability + "%"
                    font.pixelSize: 11
                    color: Theme.isDark() ? "#ACC9EB" : "#46739C"
                }
                Item { Layout.fillWidth: true }
            }
        }
    }

    TapHandler {
        enabled: !root.editMode && !WeatherService.loading
        onTapped: WeatherService.refresh()
    }

    ToolTip.visible: hoverHandler.hovered && WeatherService.error.length > 0
    ToolTip.text: WeatherService.error
    HoverHandler { id: hoverHandler }
}
