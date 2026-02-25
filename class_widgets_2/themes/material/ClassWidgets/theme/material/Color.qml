pragma Singleton
import QtQuick
import "../../../js/Md3Theme.js" as Md3
import RinUI
import ClassWidgets.Theme

QtObject { // 直接使用 QtObject，不要用 Item
    id: root

    // --- 输入 (Input) ---
    property bool isDark: (Theme.currentTheme) ? Theme.currentTheme.isDark : false
    property var seedColor: Theme ? Theme.getThemeColor() : "#6750A4"

    // 只要 seedColor 变了，就强制重构
    onSeedColorChanged: {
        console.log("Color Singleton: Seed color changed to", seedColor)
        _rebuild()
    }

    property Timer _utilsWatcher: Timer {
        id: refreshTimer
        interval: 200 // 0.2秒检查一次
        running: true
        repeat: true
        onTriggered: {
            if (typeof Utils !== "undefined") {
                var latestColor = Theme.getThemeColor();
                if (latestColor !== root.seedColor) {
                    console.log("Timer detected color change:", root.seedColor, "->", latestColor);
                    root.seedColor = latestColor;
                    // seedColor 改变会自动触发下面的 onSeedColorChanged -> _rebuild
                }
            }
        }
    }
    onIsDarkChanged: _rebuild()
    // Component.onCompleted: {
    //     console.log("I am:", Qt.resolvedUrl("."), this)
    //     _rebuild()
    // }

    // --- 输出 Tokens (直接定义，无需 alias) ---
    // Surface colors
    property color background
    property color onBackground
    property color surface
    property color surfaceDim
    property color surfaceBright
    property color surfaceContainerLowest
    property color surfaceContainerLow
    property color surfaceContainer
    property color surfaceContainerHigh
    property color surfaceContainerHighest
    property color onSurface
    property color surfaceVariant
    property color onSurfaceVariant
    property color inverseSurface
    property color inverseOnSurface
    property color outline
    property color outlineVariant
    property color shadow
    property color scrim
    property color surfaceTint

    // Primary colors
    property color primary
    property color onPrimary
    property color primaryContainer
    property color onPrimaryContainer
    property color primaryFixed
    property color primaryFixedDim
    property color onPrimaryFixed
    property color onPrimaryFixedVariant
    property color inversePrimary

    // Secondary colors
    property color secondary
    property color onSecondary
    property color secondaryContainer
    property color onSecondaryContainer
    property color secondaryFixed
    property color secondaryFixedDim
    property color onSecondaryFixed
    property color onSecondaryFixedVariant

    // Tertiary colors
    property color tertiary
    property color onTertiary
    property color tertiaryContainer
    property color onTertiaryContainer
    property color tertiaryFixed
    property color tertiaryFixedDim
    property color onTertiaryFixed
    property color onTertiaryFixedVariant

    // Error colors
    property color error
    property color onError
    property color errorContainer
    property color onErrorContainer

    // --- 内部逻辑 ---

    function _toHexString(c) {
        if (!c) return "#6750A4";
        // 转换为字符串 hex
        var s = c.toString();
        if (s.indexOf("#") === 0) return s;

        // 处理 Qt 对象 {r, g, b, a}
        if (typeof c === "object" && c.hasOwnProperty("r")) {
            var toHex = function(v) {
                var hex = Math.round(v * 255).toString(16).toUpperCase();
                return hex.length === 1 ? "0" + hex : hex;
            }
            return "#" + toHex(c.r) + toHex(c.g) + toHex(c.b);
        }
        return "#6750A4"; // Fallback
    }

    function _rebuild() {
        var seedHex = _toHexString(seedColor);

        if (seedHex === "#00000000" || seedHex === "#000000") {
             seedHex = "#6750A4";
        }

        console.log("Rebuilding MD3 Theme... Seed:", seedHex, "Dark:", isDark);

        var t = Md3.generateTheme(seedHex, isDark);

        if (!t || !t.primary) {
            console.warn("MD3 Theme generation returned empty.");
            return;
        }

        // 批量赋值 (QtObject 内部赋值效率很高)
        // Surface
        background = t.background
        onBackground = t.onBackground
        surface = t.surface
        surfaceDim = t.surfaceDim
        surfaceBright = t.surfaceBright
        surfaceContainerLowest = t.surfaceContainerLowest
        surfaceContainerLow = t.surfaceContainerLow
        surfaceContainer = t.surfaceContainer
        surfaceContainerHigh = t.surfaceContainerHigh
        surfaceContainerHighest = t.surfaceContainerHighest
        onSurface = t.onSurface
        surfaceVariant = t.surfaceVariant
        onSurfaceVariant = t.onSurfaceVariant
        inverseSurface = t.inverseSurface
        inverseOnSurface = t.inverseOnSurface
        outline = t.outline
        outlineVariant = t.outlineVariant
        shadow = t.shadow
        scrim = t.scrim
        surfaceTint = t.surfaceTint

        // Primary
        primary = t.primary
        onPrimary = t.onPrimary
        primaryContainer = t.primaryContainer
        onPrimaryContainer = t.onPrimaryContainer
        primaryFixed = t.primaryFixed
        primaryFixedDim = t.primaryFixedDim
        onPrimaryFixed = t.onPrimaryFixed
        onPrimaryFixedVariant = t.onPrimaryFixedVariant
        inversePrimary = t.inversePrimary

        // Secondary
        secondary = t.secondary
        onSecondary = t.onSecondary
        secondaryContainer = t.secondaryContainer
        onSecondaryContainer = t.onSecondaryContainer
        secondaryFixed = t.secondaryFixed
        secondaryFixedDim = t.secondaryFixedDim
        onSecondaryFixed = t.onSecondaryFixed
        onSecondaryFixedVariant = t.onSecondaryFixedVariant

        // Tertiary
        tertiary = t.tertiary
        onTertiary = t.onTertiary
        tertiaryContainer = t.tertiaryContainer
        onTertiaryContainer = t.onTertiaryContainer
        tertiaryFixed = t.tertiaryFixed
        tertiaryFixedDim = t.tertiaryFixedDim
        onTertiaryFixed = t.onTertiaryFixed
        onTertiaryFixedVariant = t.onTertiaryFixedVariant

        // Error
        error = t.error
        onError = t.onError
        errorContainer = t.errorContainer
        onErrorContainer = t.onErrorContainer
    }
}