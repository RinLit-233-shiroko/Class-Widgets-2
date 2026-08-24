import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    id: root

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_weather_partly_cloudy_day_20_regular"
        title: qsTr("Enable Weather")
        description: qsTr("Enable shared weather data for Weather Widgets. Weather is fetched from a public service without an API key.")
        Switch {
            id: enabledSwitch
            Component.onCompleted: checked = Configs.data.weather.enabled
            onCheckedChanged: {
                Configs.set("weather.enabled", checked)
                if (checked)
                    WeatherService.refreshFromSettings()
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_location_20_regular"
        title: qsTr("City")
        description: qsTr("Enter a city name, such as Beijing, Shanghai, Tokyo, or London. The service will resolve it to a location automatically.")

        TextField {
            id: cityInput
            Layout.fillWidth: true
            placeholderText: qsTr("Enter city name")
            text: Configs.data.weather.city || ""
            onAccepted: WeatherService.setCity(text)
            onActiveFocusChanged: {
                if (!activeFocus && text.trim() !== (Configs.data.weather.city || ""))
                    WeatherService.setCity(text)
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_arrow_sync_20_regular"
        title: qsTr("Refresh interval")
        description: qsTr("Choose how often CW2 refreshes weather in the background. The minimum interval is 5 minutes.")

        SpinBox {
            id: refreshInterval
            from: 5
            to: 180
            stepSize: 5
            editable: true
            Component.onCompleted: value = Configs.data.weather.refresh_interval_minutes || 15
            onValueModified: {
                Configs.set("weather.refresh_interval_minutes", value)
                WeatherService.refreshFromSettings()
            }
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_weather_sunny_20_regular"
        title: qsTr("Weather status")
        description: WeatherService.error.length > 0
                     ? WeatherService.error
                     : (WeatherService.available
                        ? qsTr("Updated at %1 · %2").arg(WeatherService.updatedAt).arg(WeatherService.city)
                        : qsTr("Set a city and refresh to preview weather data."))

        Button {
            enabled: !WeatherService.loading && enabledSwitch.checked
            text: WeatherService.loading ? qsTr("Refreshing…") : qsTr("Refresh now")
            onClicked: WeatherService.refresh()
        }
    }
}
