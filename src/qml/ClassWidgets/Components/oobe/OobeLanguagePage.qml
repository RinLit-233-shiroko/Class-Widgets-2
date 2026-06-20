import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


ColumnLayout {
    id: root
    spacing: 20

    Item {
        Layout.fillHeight: true
    }

    Icon {
        Layout.alignment: Qt.AlignHCenter
        source: PathManager.images("logo.png")
        size: 88
    }

    Text {
        Layout.fillWidth: true
        typography: Typography.Subtitle
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("Welcome to Class Widgets 2")
    }

    InfoBar {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(root.width * 0.82, 760)
        closable: false
        severity: Severity.Warning
        title: qsTr("Notice")
        text: qsTr(
            "The setup wizard is still being improved.\n" +
            "This version is a test build, and some features may be incomplete."
        )
    }

    SettingCard {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Math.min(root.width * 0.72, 620)
        title: qsTr("Language")
        description: qsTr("Set the language of Class Widgets")
        icon.name: "ic_fluent_globe_20_regular"

        ComboBox {
            property var data: [AppCentral.translator.getSystemLanguage(), "en_US", "ja_JP", "zh_CN", "zh_HK"]
            property bool initialized: false
            model: ListModel {
                ListElement { text: qsTr("Use System Language") }
                ListElement { text: "English (US)" }
                ListElement { text: "日本語" }
                ListElement { text: "简体中文" }
                ListElement { text: "繁體中文（香港）" }
            }

            Component.onCompleted: {
                currentIndex = Math.max(0, data.indexOf(AppCentral.translator.getLanguage()))
                initialized = true
            }

            onCurrentIndexChanged: {
                if (!initialized) return
                AppCentral.translator.setLanguage(data[currentIndex])
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}