import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

SettingsLayout {
    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_data_bar_vertical_20_regular"
        title: qsTr("Primary information")
        description: qsTr("Choose the main weather value shown by this Widget.")

        ComboBox {
            id: displayModeBox
            textRole: "label"
            valueRole: "value"
            model: [
                { label: qsTr("Temperature"), value: "temperature" },
                { label: qsTr("Feels like"), value: "apparent" },
                { label: qsTr("Humidity"), value: "humidity" },
                { label: qsTr("Wind"), value: "wind" },
                { label: qsTr("Pressure"), value: "pressure" }
            ]
            Component.onCompleted: {
                const saved = settings.display_mode || "temperature"
                for (let index = 0; index < model.length; index++) {
                    if (model[index].value === saved) {
                        currentIndex = index
                        break
                    }
                }
            }
            onActivated: settings.display_mode = currentValue
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_location_20_regular"
        title: qsTr("Show city")
        description: qsTr("Display the configured city name above the weather information.")
        Switch {
            id: citySwitch
            Component.onCompleted: checked = settings.show_city !== false
            onCheckedChanged: settings.show_city = checked
        }
    }

    SettingCard {
        Layout.fillWidth: true
        icon.name: "ic_fluent_weather_partly_cloudy_day_20_regular"
        title: qsTr("Show daily forecast")
        description: qsTr("Display today's high/low temperature and precipitation probability.")
        Switch {
            id: forecastSwitch
            Component.onCompleted: checked = settings.show_forecast !== false
            onCheckedChanged: settings.show_forecast = checked
        }
    }
}
