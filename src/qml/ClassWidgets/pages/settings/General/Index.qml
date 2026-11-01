import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import Qt5Compat.GraphicalEffects
import ClassWidgets.Components


FluentPage {
    title: qsTr("General")
    id: generalPage

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Locale")
        }

        InfoBar {
            severity: Severity.Warning
            title: qsTr("Translation notice / 翻译提示")
            text: qsTr(
                "Some translations may be auto-generated and could be inaccurate. " +
                "Help us improve them on <a href='https://hosted.weblate.org/projects/class-widgets/cw2/'>Weblate</a>. <br>" +
                "部分翻译可能由自动翻译生成，存在不准确之处。欢迎在 <a href='https://hosted.weblate.org/projects/class-widgets/cw2/'>Weblate</a> 上参与改进"
            )
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Language")
            description: qsTr("Set the language of Class Widgets")
            icon.name: "ic_fluent_globe_20_regular"

            ComboBox {
                enabled: !Configs.isKeyLocked("locale.language")
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
                    currentIndex = data.indexOf(AppCentral.translator.getLanguage())
                    console.log("Language: " + AppCentral.translator.getLanguage())
                    initialized = true
                }

                onCurrentIndexChanged: {
                    if (!initialized) return
                    AppCentral.translator.setLanguage(data[currentIndex])
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Customize")
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("App Theme")
            description: qsTr("Select which app theme to display")
            icon.name: "ic_fluent_paint_brush_20_regular"

            ComboBox {
                enabled: !Configs.isKeyLocked("preferences.current_theme")
                property var data: [Theme.mode.Light, Theme.mode.Dark, Theme.mode.Auto]
                model: ListModel {
                    ListElement { text: qsTr("Light") }
                    ListElement { text: qsTr("Dark") }
                    ListElement { text: qsTr("Use system setting") }
                }
                currentIndex: data.indexOf(Theme.getTheme())
                onCurrentIndexChanged: {
                    Theme.setTheme(data[currentIndex])
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            icon.name: "ic_fluent_layer_20_regular"
            title: qsTr("Window Layer")
            description: qsTr("Let your widgets floating on top, or tuck them neatly behind other windows")

            ComboBox {
                model: ListModel {
                    ListElement {
                        text: qsTr("Pin on Top"); value: "top"
                    }
                    ListElement {
                        text: qsTr("Send to Back"); value: "bottom"
                    }
                }
                textRole: "text"

                enabled: !Configs.isKeyLocked("preferences.widgets_layer")
                onCurrentIndexChanged: if (focus) Configs.set("preferences.widgets_layer", model.get(currentIndex).value)
                Component.onCompleted: {
                    for (var i = 0; i < model.count; i++) {
                        if (model.get(i).value === Configs.data.preferences.widgets_layer) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Countdown Precision")
            description: qsTr("Choose how precisely the remaining time is displayed")
            icon.name: "ic_fluent_timer_20_regular"

            ComboBox {
                enabled: !Configs.isKeyLocked("preferences.countdown_precision")
                textRole: "text"
                model: ListModel {
                    ListElement { text: qsTr("To the Second"); value: "second" }
                    ListElement { text: qsTr("To the Minute"); value: "minute" }
                }

                onCurrentIndexChanged: {
                    if (focus && currentIndex >= 0)
                        Configs.set("preferences.countdown_precision", model.get(currentIndex).value)
                }

                Component.onCompleted: {
                    const saved = Configs.data.preferences.countdown_precision || "second"
                    for (let i = 0; i < model.count; i++) {
                        if (model.get(i).value === saved) {
                            currentIndex = i
                            break
                        }
                    }
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Mini Mode")
            description: qsTr("Use a more compact layout for smaller widgets")
            icon.name: "ic_fluent_resize_20_regular"

            Switch {
                id: miniModeSwitch
                enabled: !Configs.isKeyLocked("preferences.mini_mode")
                onCheckedChanged: Configs.set("preferences.mini_mode", checked)
                Component.onCompleted: {
                    checked = Configs.data.preferences.mini_mode
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Actions")
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("Run at Startup")
            description: qsTr("Run Class Widgets on startup")
            icon.name: "ic_fluent_open_20_regular"

            Switch {
                enabled: !Configs.isKeyLocked("app.auto_startup") && UtilsBackend.autostartSupported()
                onCheckedChanged: {
                    Configs.set("app.auto_startup", checked)
                    UtilsBackend.setAutostart(checked)
                }
                Component.onCompleted: {
                    if (!UtilsBackend.autostartEnabled()) {
                        checked = false
                        Configs.set("app.auto_startup", checked)
                        return
                    }
                    checked = Configs.data.app.auto_startup
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            typography: Typography.BodyStrong
            text: qsTr("Privacy")
        }

        SettingExpander {
            objectName: "telemetrySettingsCard"
            Layout.fillWidth: true
            title: qsTr("Telemetry & diagnostics")
            icon.name: "ic_fluent_data_usage_20_regular"

            action: DiagnosticConsent {}

            SettingItem {
                id: installationIdItem
                objectName: "telemetryInstallationIdItem"
                visible: Configs.data.telemetry.enabled
                actionIcon.name: "ic_fluent_copy_20_regular"
                clickable: true
                onClicked: UtilsBackend.copyToClipboard(Configs.data.telemetry.installation_id)

                RowLayout {
                    Layout.fillWidth: true
                    // 抵消 SettingItem 在空标题旁保留的间距，与相邻设置项标题对齐。
                    Layout.leftMargin: -16
                    spacing: 16

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Installation ID")
                    }

                    Text {
                        objectName: "telemetryInstallationId"
                        Layout.maximumWidth: installationIdItem.width * 0.6
                        Layout.alignment: Qt.AlignRight
                        font.family: "Consolas"
                        text: Configs.data.telemetry.installation_id
                        elide: Text.ElideRight
                        opacity: 0.8
                    }
                }
            }
        }
    }
}
