.pragma library
.import "./material-color-utilities.js" as MaterialUtils

/**
 * QML-friendly MD3 generator
 * @param {string} seedHex  "#RRGGBB"
 * @param {boolean} dark
 * @returns {Object<string,string>}
 */
function generateTheme(seedHex, dark) {
    var argb = MaterialUtils.MaterialCore.argbFromHex(seedHex)
    var hct = MaterialUtils.MaterialCore.Hct.fromInt(argb)
    
    console.log("MD3 Theme generation - seedHex:", seedHex, "dark:", dark)
    console.log("  Source ARGB:", argb)
    console.log("  Source HCT - hue:", hct.hue, "chroma:", hct.chroma, "tone:", hct.tone)
    
    var scheme = new MaterialUtils.MaterialCore.SchemeTonalSpot(hct, dark, 0)

    console.log("  Primary Palette - hue:", scheme.primaryPalette.hue, "chroma:", scheme.primaryPalette.chroma)
    console.log("  Primary tone (dark):", dark ? 80 : 40)
    console.log("  Primary ARGB:", scheme.primary)

    var result = {
        // Surface colors
        background: _hexFromArgb(scheme.background),
        onBackground: _hexFromArgb(scheme.onBackground),
        surface: _hexFromArgb(scheme.surface),
        surfaceDim: _hexFromArgb(scheme.surfaceDim),
        surfaceBright: _hexFromArgb(scheme.surfaceBright),
        surfaceContainerLowest: _hexFromArgb(scheme.surfaceContainerLowest),
        surfaceContainerLow: _hexFromArgb(scheme.surfaceContainerLow),
        surfaceContainer: _hexFromArgb(scheme.surfaceContainer),
        surfaceContainerHigh: _hexFromArgb(scheme.surfaceContainerHigh),
        surfaceContainerHighest: _hexFromArgb(scheme.surfaceContainerHighest),
        onSurface: _hexFromArgb(scheme.onSurface),
        surfaceVariant: _hexFromArgb(scheme.surfaceVariant),
        onSurfaceVariant: _hexFromArgb(scheme.onSurfaceVariant),
        inverseSurface: _hexFromArgb(scheme.inverseSurface),
        inverseOnSurface: _hexFromArgb(scheme.inverseOnSurface),
        outline: _hexFromArgb(scheme.outline),
        outlineVariant: _hexFromArgb(scheme.outlineVariant),
        shadow: _hexFromArgb(scheme.shadow),
        scrim: _hexFromArgb(scheme.scrim),
        surfaceTint: _hexFromArgb(scheme.surfaceTint),

        // Primary colors
        primary: _hexFromArgb(scheme.primary),
        onPrimary: _hexFromArgb(scheme.onPrimary),
        primaryContainer: _hexFromArgb(scheme.primaryContainer),
        onPrimaryContainer: _hexFromArgb(scheme.onPrimaryContainer),
        primaryFixed: _hexFromArgb(scheme.primaryFixed),
        primaryFixedDim: _hexFromArgb(scheme.primaryFixedDim),
        onPrimaryFixed: _hexFromArgb(scheme.onPrimaryFixed),
        onPrimaryFixedVariant: _hexFromArgb(scheme.onPrimaryFixedVariant),
        inversePrimary: _hexFromArgb(scheme.inversePrimary),

        // Secondary colors
        secondary: _hexFromArgb(scheme.secondary),
        onSecondary: _hexFromArgb(scheme.onSecondary),
        secondaryContainer: _hexFromArgb(scheme.secondaryContainer),
        onSecondaryContainer: _hexFromArgb(scheme.onSecondaryContainer),
        secondaryFixed: _hexFromArgb(scheme.secondaryFixed),
        secondaryFixedDim: _hexFromArgb(scheme.secondaryFixedDim),
        onSecondaryFixed: _hexFromArgb(scheme.onSecondaryFixed),
        onSecondaryFixedVariant: _hexFromArgb(scheme.onSecondaryFixedVariant),

        // Tertiary colors
        tertiary: _hexFromArgb(scheme.tertiary),
        onTertiary: _hexFromArgb(scheme.onTertiary),
        tertiaryContainer: _hexFromArgb(scheme.tertiaryContainer),
        onTertiaryContainer: _hexFromArgb(scheme.onTertiaryContainer),
        tertiaryFixed: _hexFromArgb(scheme.tertiaryFixed),
        tertiaryFixedDim: _hexFromArgb(scheme.tertiaryFixedDim),
        onTertiaryFixed: _hexFromArgb(scheme.onTertiaryFixed),
        onTertiaryFixedVariant: _hexFromArgb(scheme.onTertiaryFixedVariant),

        // Error colors
        error: _hexFromArgb(scheme.error),
        onError: _hexFromArgb(scheme.onError),
        errorContainer: _hexFromArgb(scheme.errorContainer),
        onErrorContainer: _hexFromArgb(scheme.onErrorContainer)
    }

    console.log("  Generated colors - primary:", result.primary, "surface:", result.surface, "background:", result.background)

    return result
}

function _hexFromArgb(argb) {
    var r = MaterialUtils.MaterialCore.redFromArgb(argb);
    var g = MaterialUtils.MaterialCore.greenFromArgb(argb);
    var b = MaterialUtils.MaterialCore.blueFromArgb(argb);
    var rHex = r.toString(16);
    var gHex = g.toString(16);
    var bHex = b.toString(16);
    if (rHex.length === 1) rHex = "0" + rHex;
    if (gHex.length === 1) gHex = "0" + gHex;
    if (bHex.length === 1) bHex = "0" + bHex;
    return "#" + rHex + gHex + bHex;
}
