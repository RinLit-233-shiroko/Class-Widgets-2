.pragma library

function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, value))
}

function pinchZoom(startZoom, scale, minimum, maximum) {
    return clamp(startZoom * scale, minimum, maximum)
}

function wheelZoom(currentZoom, angleDelta, pixelDelta, minimum, maximum) {
    var step = angleDelta
        ? angleDelta / 1200
        : pixelDelta ? Math.sign(pixelDelta) * 0.02 : 0
    return clamp(currentZoom * (1 + step), minimum, maximum)
}

function steppedZoom(currentZoom, delta, minimum, maximum) {
    return clamp(currentZoom + delta, minimum, maximum)
}
