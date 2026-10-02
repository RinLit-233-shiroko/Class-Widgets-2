/*
 * Shared course palette.
 *
 * ScheduleCourseCard, SubjectClip and the class-swap cards all tint a subject
 * the same way: keep the subject's hue, cap its saturation, and move the colour
 * to a pinned *relative luminance* so surface/text contrast never depends on
 * how bright the chosen subject colour happens to be.
 *
 * No `.pragma library` here on purpose: the Qt JS parser used by this project
 * rejects that directive and then fails to load the whole file.
 */

// QML hands subject colours over either as a real color value or as the raw
// string from the schedule, so normalize before reading any channel.
function toColor(value) {
    if (value === null || value === undefined)
        return null
    if (value.hslHue !== undefined)
        return value
    try {
        const converted = Qt.darker(value, 1.0)
        if (converted && converted.hslHue !== undefined)
            return converted
    } catch (error) {
    }
    return null
}

function channelLuminance(channel) {
    return channel <= 0.04045
        ? channel / 12.92
        : Math.pow((channel + 0.055) / 1.055, 2.4)
}

function relativeLuminance(color) {
    return 0.2126 * channelLuminance(color.r)
        + 0.7152 * channelLuminance(color.g)
        + 0.0722 * channelLuminance(color.b)
}

// Rebuild `base` at a target relative luminance by bisecting on HSL lightness,
// which rises monotonically with luminance for a fixed hue and saturation.
// An unusable colour is returned untouched so a missing theme cannot turn a
// binding error into a broken card.
function atLuminance(base, target, saturationCap) {
    const source = toColor(base)
    if (!source)
        return base
    const cap = saturationCap === undefined ? 0.8 : saturationCap
    const hue = source.hslHue < 0 ? 0 : source.hslHue
    const saturation = Math.min(source.hslSaturation, cap)
    let low = 0.0
    let high = 1.0
    for (let i = 0; i < 20; ++i) {
        const middle = (low + high) / 2
        if (relativeLuminance(Qt.hsla(hue, saturation, middle, 1.0)) < target)
            low = middle
        else
            high = middle
    }
    return Qt.hsla(hue, saturation, (low + high) / 2, 1.0)
}

// Muted variant of a subject colour: same hue and lightness with a fraction of
// the saturation. An unavailable course still reads as that subject instead of
// turning grey, and the quieter tone survives a translucent card surface.
function muted(base, factor) {
    const source = toColor(base) || Qt.rgba(0.5, 0.5, 0.5, 1.0)
    const hue = source.hslHue < 0 ? 0 : source.hslHue
    const amount = factor === undefined ? 0.35 : factor
    return Qt.hsla(hue, Math.min(source.hslSaturation, 0.8) * amount,
                   source.hslLightness, 1.0)
}
