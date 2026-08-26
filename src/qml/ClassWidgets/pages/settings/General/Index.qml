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

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("启动动画")
            description: qsTr("启动 Class Widgets 时，在屏幕中央显示紧凑的动画")
            icon.name: "ic_fluent_play_circle_20_regular"

            Switch {
                id: startupAnimationSwitch
                property bool initialized: false
                enabled: !Configs.isKeyLocked("app.startup_animation_enabled")
                onCheckedChanged: if (initialized) Configs.set("app.startup_animation_enabled", checked)
                Component.onCompleted: {
                    checked = Configs.data.app.startup_animation_enabled
                    initialized = true
                }
            }
        }

        SettingCard {
            id: startupMediaCard
            Layout.fillWidth: true
            title: qsTr("启动动画媒体")
            description: qsTr("选择本地图片，或不超过 10 秒的视频")
            icon.name: "ic_fluent_image_20_regular"

            property string selectError: ""

            ColumnLayout {
                spacing: 6

                RowLayout {
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: AppCentral.startupAnimation.hasCustomMedia
                              ? AppCentral.startupAnimation.mediaName
                              : qsTr("未选择本地媒体")
                        color: Colors.proxy.textSecondaryColor
                        elide: Text.ElideMiddle
                    }

                    Button {
                        text: qsTr("选择媒体")
                        enabled: !Configs.isKeyLocked("app.startup_animation_media_path")
                        onClicked: {
                            startupMediaCard.selectError = AppCentral.startupAnimation.selectMedia()
                        }
                    }

                    Button {
                        text: qsTr("清除")
                        enabled: AppCentral.startupAnimation.hasCustomMedia
                                 && !Configs.isKeyLocked("app.startup_animation_media_path")
                        onClicked: {
                            AppCentral.startupAnimation.clearMedia()
                            startupMediaCard.selectError = ""
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: startupMediaCard.selectError !== ""
                    text: startupMediaCard.selectError
                    color: "#c42b1c"
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            visible: AppCentral.startupAnimation.mediaType === "video"
            title: qsTr("强制播放完视频")
            description: qsTr("开启后会忽略默认展示时长，直到所选视频播放结束。")
            icon.name: "ic_fluent_video_clip_20_regular"

            Switch {
                property bool initialized: false
                enabled: !Configs.isKeyLocked("app.startup_animation_force_video_completion")
                onCheckedChanged: if (initialized) Configs.set("app.startup_animation_force_video_completion", checked)
                Component.onCompleted: {
                    checked = Configs.data.app.startup_animation_force_video_completion
                    initialized = true
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("显示 ClassWidgets 信息")
            description: AppCentral.startupAnimation.hasCustomMedia
                         ? qsTr("在自定义启动媒体上显示图标、软件名称和版本信息")
                         : qsTr("未选择本地图片或视频时，始终显示此信息")
            icon.name: "ic_fluent_info_20_regular"

            Switch {
                property bool initialized: false
                enabled: AppCentral.startupAnimation.hasCustomMedia
                         && !Configs.isKeyLocked("app.startup_animation_show_info")
                onCheckedChanged: if (initialized) Configs.set("app.startup_animation_show_info", checked)
                Component.onCompleted: {
                    checked = Configs.data.app.startup_animation_show_info
                    initialized = true
                }
            }
        }

        SettingCard {
            Layout.fillWidth: true
            title: qsTr("预览启动动画")
            description: qsTr("弹出独立的启动动画预览窗口；不会隐藏、暂停或重新加载当前小组件。")
            icon.name: "ic_fluent_play_20_regular"

            Button {
                text: AppCentral.startupAnimation.previewing ? qsTr("正在预览…") : qsTr("预览")
                enabled: !AppCentral.startupAnimation.previewing
                onClicked: AppCentral.startupAnimation.preview()
            }
        }
    }
}
