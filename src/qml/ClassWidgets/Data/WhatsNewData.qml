pragma Singleton
import QtQuick 2.15
import ClassWidgets.Components

QtObject {
    id: whatsNewData
    
    // New feature introduction content
    property var features: [
        {
            "title": qsTr("Brand New What's New Feature"),
            "description": qsTr("Introducing our brand new feature introduction page that allows users to quickly learn about the latest features of Class Widgets 2.0. Supports multi-page display, smooth animations, and smart navigation for a better new user experience."),
            "image": PathManager.images("whatsnew/whatsnew.png"),
            "icon": "ic_fluent_info_20_regular"
        },
        {
            "title": qsTr("Comprehensive Notification System Upgrade"),
            "description": qsTr("A completely rebuilt notification system that supports in-app notification toggles, intelligent ringtone configuration, and customizable notification providers. Bringing users a more flexible and intelligent notification experience."),
            "image": PathManager.images("whatsnew/notification.png"),
            "icon": "ic_fluent_alert_badge_20_regular",
            "actionButtonText": qsTr("Add \"Dynamic Notifications\" to Widgets Screen"),
            "actionButtonAction": "toggleWidgetsEditMode"
        },
        {
            "title": qsTr("Enhanced Plugin System"),
            "description": qsTr("A comprehensive plugin system architecture that supports third-party library imports, web-based plugin plaza, PluginAPI and UIAPI. Added edit mode detection properties to make plugin development more convenient."),
            "image": PathManager.images("whatsnew/plugin.png"),
            "icon": "ic_fluent_apps_add_in_20_regular",
            "actionButtonText": qsTr("Visit Extension Plaza"),
            "actionButtonAction": "openPluginPlaza"
        },
        {
            "title": qsTr("Extended Multi-language Support"),
            "description": qsTr("Added Japanese and Traditional Chinese (Hong Kong) language support, improved internationalization (i18n) system. Translation management through Weblate platform allows more users to enjoy the convenience of Class Widgets."),
            "image": PathManager.images("whatsnew/whatsnew.png"),
            "icon": "ic_fluent_translate_20_regular"
        },
        // {
        //     "title": qsTr("UI Experience Optimization"),
        //     "description": qsTr("Optimized settings interface font preview display, improved AnimatedDigits control clarity, enhanced Win10 device window effect processing, comprehensively improving user interface visual effects and user experience."),
        //     "image": PathManager.images("whatsnew/ui_optimization.png"),
        //     "icon": "ic_fluent_design_ideas_20_regular",
        //     "actionButtonText": qsTr("Customize Appearance"),
        //     "actionButtonAction": "openAppearanceSettings"
        // }
    ]
    
    // 计算属性
    property int totalPages: features.length
    
    // 获取指定索引的功能信息
    function getFeature(index) {
        if (index >= 0 && index < features.length) {
            return features[index]
        }
        return null
    }
    
    // 获取功能标题列表（用于快速导航）
    function getFeatureTitles() {
        var titles = []
        for (var i = 0; i < features.length; i++) {
            titles.push(features[i].title)
        }
        return titles
    }

    // 处理操作按钮点击
    function handleAction(action) {
        if (!action) return
        
        switch(action) {
            case "toggleWidgetsEditMode":
                AppCentral.toggleWidgetsEditMode()
                break
            case "openPluginPlaza":
                Qt.openExternalUrl("https://plaza.cw.rinlit.cn")
                break
            default:
                console.log("Unknown action:", action)
        }
    }
}