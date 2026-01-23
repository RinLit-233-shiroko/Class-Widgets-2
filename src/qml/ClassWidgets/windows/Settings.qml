import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components


FluentWindow {
    id: settingsWindow
    icon: PathManager.assets("images/icons/cw2_settings.png")
    title: qsTr("Settings")
    width: Screen.width * 0.5
    height: Screen.height * 0.6
    minimumWidth: 600
    // visible: true

    onClosing: function(event) {
        event.accepted = false
        settingsWindow.visible = false
    }

    navigationItems: [
        {
            title: qsTr("Home"),
            page: PathManager.qml("pages/settings/Home.qml"),
            icon: "ic_fluent_board_20_regular",
        },
        {
            title: qsTr("General"),
            icon: "ic_fluent_settings_20_regular",
            page: PathManager.qml("pages/settings/general/Index.qml"),
            subItems: [
                {
                    title: qsTr("Widgets"),
                    page: PathManager.qml("pages/settings/general/Widgets.qml"),
                    icon: "ic_fluent_apps_20_regular"
                },
                {
                    title: qsTr("Interactions"),
                    page: PathManager.qml("pages/settings/general/Interactions.qml"),
                    icon: "ic_fluent_hand_draw_20_regular"
                }
            ]
        },
        {
            title: qsTr("Personalization"),
            icon: "ic_fluent_paint_brush_sparkle_20_regular",
            page: PathManager.qml("pages/settings/Personalization.qml"),
        },
        {
            title: qsTr("Notification & Time"),
            icon: "ic_fluent_alert_badge_20_regular",
            subItems: [
                {
                    title: qsTr("Notification"),
                    page: PathManager.qml("pages/settings/notificationAndTime/Notification.qml"),
                    icon: "ic_fluent_alert_badge_20_regular"
                },
                {
                    title: qsTr("Time"),
                    page: PathManager.qml("pages/settings/notificationAndTime/Time.qml"),
                    icon: "ic_fluent_clock_20_regular"
                }
            ]
        },
        {
            title: qsTr("Plugins"),
            page: PathManager.qml("pages/settings/Plugins.qml"),
            icon: "ic_fluent_apps_add_in_20_regular",
            subItems: UtilsBackend && UtilsBackend.extraSettings && UtilsBackend.extraSettings.length > 0 ? UtilsBackend.extraSettings : null
        },
        {
            title: qsTr("About"),
            page: PathManager.qml("pages/settings/About.qml"),
            icon: "ic_fluent_info_20_regular",
        },
        {
            title: qsTr("Update"),
            page: PathManager.qml("pages/settings/Update.qml"),
            icon: "ic_fluent_arrow_sync_20_regular",
        }
    ]

    // 测试水印
    Watermark {
        anchors.centerIn: parent
    }
}