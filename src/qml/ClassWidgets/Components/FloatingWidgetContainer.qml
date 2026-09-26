import QtQuick

Item {
    id: root

    property bool floatingMode: false
    property real edgeMargin: 24
    property real scaleFactor: Configs.data.preferences.scale_factor || 1.0
    property real screenWidth: parent ? parent.width : 0
    property real screenHeight: parent ? parent.height : 0
    property bool positionInitialized: false
    property real positionX: 0
    property real positionY: 0
    property real velocityX: 0
    property real velocityY: 0
    property real friction: 0.86
    property real springStrength: 115
    property real springDamping: 18
    property real stopVelocity: 6
    property bool animationReady: false
    property var dragSamples: []
    readonly property int maxDragSamples: 20
    readonly property int sampleWindowMs: 100

    property real contentWidth: floatingLoader.item
        ? (floatingLoader.item.implicitWidth || floatingLoader.item.width || 0)
        : 0
    property real contentHeight: floatingLoader.item
        ? (floatingLoader.item.implicitHeight || floatingLoader.item.height || 0)
        : 0

    objectName: "floatingWidgetContainer"
    visible: animationReady
    z: 100
    width: contentWidth * scaleFactor
    height: contentHeight * scaleFactor

    signal clicked()
    signal geometryChanged()

    onXChanged: {
        positionX = x
        geometryChanged()
    }
    onYChanged: {
        positionY = y
        geometryChanged()
    }
    onVisibleChanged: geometryChanged()
    onScaleChanged: geometryChanged()
    onWidthChanged: {
        ensurePosition()
        reconcilePosition()
        geometryChanged()
    }
    onHeightChanged: {
        ensurePosition()
        reconcilePosition()
        geometryChanged()
    }
    onScreenWidthChanged: reconcilePosition()
    onScreenHeightChanged: reconcilePosition()

    function clampToBounds(posX, posY) {
        var maxX = Math.max(edgeMargin, screenWidth - width - edgeMargin)
        var maxY = Math.max(edgeMargin, screenHeight - height - edgeMargin)
        return {
            x: Math.max(edgeMargin, Math.min(maxX, posX)),
            y: Math.max(edgeMargin, Math.min(maxY, posY))
        }
    }

    function ensurePosition() {
        if (positionInitialized || width <= 0 || height <= 0
                || screenWidth <= 0 || screenHeight <= 0)
            return

        var savedX = Configs.data.preferences.floating_widget_x
        var savedY = Configs.data.preferences.floating_widget_y
        var position = clampToBounds(
            savedX != null && savedX >= 0 ? savedX : screenWidth - width - edgeMargin,
            savedY != null && savedY >= 0 ? savedY : (screenHeight - height) / 2
        )
        positionX = position.x
        positionY = position.y
        x = position.x
        y = position.y
        positionInitialized = true
    }

    function reconcilePosition() {
        if (!positionInitialized || width <= 0 || height <= 0
                || screenWidth <= 0 || screenHeight <= 0)
            return

        var position = clampToBounds(x, y)
        positionX = position.x
        positionY = position.y
        x = position.x
        y = position.y
    }

    function persistPosition() {
        if (!Configs.isKeyLocked("preferences.floating_widget_x"))
            Configs.set("preferences.floating_widget_x", Math.round(positionX))
        if (!Configs.isKeyLocked("preferences.floating_widget_y"))
            Configs.set("preferences.floating_widget_y", Math.round(positionY))
    }

    property int themeReloadSerial: 0

    function cacheBustedThemeUrl(url) {
        themeReloadSerial += 1
        var separator = url.indexOf("?") >= 0 ? "&" : "?"
        return url + separator + "t=" + Date.now() + "-" + themeReloadSerial
    }
    function reloadTheme() {
        var oldSource = floatingLoader.source.toString()
        if (!oldSource)
            return

        if (floatingMode) {
            enterAnimation.stop()
            exitAnimation.stop()
            root.opacity = 0
            root.scale = 0.8
            root.animationReady = true
        }
        floatingLoader.source = ""
        Qt.callLater(function() {
            floatingLoader.source = cacheBustedThemeUrl(oldSource)
        })
    }

    function enterFloatingMode() {
        exitAnimation.stop()
        root.opacity = 0
        root.scale = 0.8
        animationReady = true
        enterAnimation.restart()
    }

    function exitFloatingMode() {
        enterAnimation.stop()
        exitAnimation.restart()
    }

    SequentialAnimation {
        id: enterAnimation

        PropertyAction { target: root; property: "opacity"; value: 0 }
        PropertyAction { target: root; property: "scale"; value: 0.8 }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "scale"
                from: 0.8
                to: 1
                duration: 400
                easing.type: Easing.OutBack
            }
        }
    }

    SequentialAnimation {
        id: exitAnimation

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                from: 1
                to: 0
                duration: 220
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "scale"
                from: 1
                to: 0.8
                duration: 260
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: {
                root.animationReady = false
                root.scale = 1
                root.opacity = 1
            }
        }
    }

    function startInertia() {
        if (Math.abs(root.velocityX) > root.stopVelocity
                || Math.abs(root.velocityY) > root.stopVelocity)
            physicsAnimation.running = true
        else
            persistPosition()
    }

    function draggedPosition(pos, minimum, maximum) {
        if (pos < minimum)
            return minimum + (pos - minimum) * 0.22
        if (pos > maximum)
            return maximum + (pos - maximum) * 0.22
        return pos
    }

    // Integrates velocity and a spring force outside the usable screen area.
    FrameAnimation {
        id: physicsAnimation
        running: false

        onTriggered: {
            // Use the actual render-frame duration so the motion stays smooth
            // when the desktop event loop is briefly busy.
            var dt = Math.min(frameTime, 0.05)
            var minX = root.edgeMargin
            var minY = root.edgeMargin
            var maxX = Math.max(minX, root.screenWidth - root.width - root.edgeMargin)
            var maxY = Math.max(minY, root.screenHeight - root.height - root.edgeMargin)
            var forceX = 0
            var forceY = 0

            if (root.x < minX)
                forceX = (minX - root.x) * root.springStrength - root.velocityX * root.springDamping
            else if (root.x > maxX)
                forceX = (maxX - root.x) * root.springStrength - root.velocityX * root.springDamping
            if (root.y < minY)
                forceY = (minY - root.y) * root.springStrength - root.velocityY * root.springDamping
            else if (root.y > maxY)
                forceY = (maxY - root.y) * root.springStrength - root.velocityY * root.springDamping

            root.velocityX += forceX * dt
            root.velocityY += forceY * dt
            var damping = Math.pow(root.friction, dt * 60)
            root.velocityX *= damping
            root.velocityY *= damping
            root.x += root.velocityX * dt
            root.y += root.velocityY * dt

            var insideX = root.x >= minX && root.x <= maxX
            var insideY = root.y >= minY && root.y <= maxY
            var stoppedX = insideX && Math.abs(root.velocityX) < root.stopVelocity
            var stoppedY = insideY && Math.abs(root.velocityY) < root.stopVelocity
            if (stoppedX)
                root.velocityX = 0
            if (stoppedY)
                root.velocityY = 0
            if (stoppedX && stoppedY) {
                physicsAnimation.running = false
                root.positionX = root.x
                root.positionY = root.y
                root.persistPosition()
            }
        }
    }

    Loader {
        id: floatingLoader
        objectName: "floatingWidgetLoader"
        source: PathManager.qml("Theme/components/FloatingWidget.qml")
        asynchronous: true
        width: root.contentWidth
        height: root.contentHeight
        scale: root.scaleFactor
        transformOrigin: Item.TopLeft

        onStatusChanged: {
            if (status === Loader.Error) {
                console.error("Failed to load FloatingWidget")
                AppCentral.reportThemeLoadFailure("FloatingWidget.qml")
            } else if (status === Loader.Ready) {
                AppCentral.reportThemeLoadReady()
                root.ensurePosition()
                root.reconcilePosition()
                if (root.floatingMode)
                    root.enterFloatingMode()
            }
        }
    }

    DragHandler {
        id: dragHandler
        target: null
        property real startX: 0
        property real startY: 0
        property real lastTranslationX: 0
        property real lastTranslationY: 0
        property real lastTranslationTime: 0
        property real sampledVelocityX: 0
        property real sampledVelocityY: 0
        property bool dragged: false
        property bool suppressTap: false

        onActiveChanged: {
            if (active) {
                physicsAnimation.running = false
                root.velocityX = 0
                root.velocityY = 0
                startX = root.x
                startY = root.y
                lastTranslationX = 0
                lastTranslationY = 0
                lastTranslationTime = Date.now()
                root.dragSamples = []
                dragged = false
                suppressTap = false
                return
            }

            if (!root.positionInitialized)
                return

            suppressTap = dragged
            if (suppressTap)
                suppressTapTimer.restart()
            if (dragged) {
                var now = Date.now()
                var cutoff = now - root.sampleWindowMs
                var samples = root.dragSamples
                while (samples.length > 0 && samples[0].t < cutoff)
                    samples.shift()
                if (samples.length >= 2) {
                    var first = samples[0]
                    var last = samples[samples.length - 1]
                    var dt = Math.max(1, last.t - first.t)
                    root.velocityX = (last.x - first.x) * 1000 / dt
                    root.velocityY = (last.y - first.y) * 1000 / dt
                } else {
                    root.velocityX = 0
                    root.velocityY = 0
                }
                root.startInertia()
            }
        }

        onTranslationChanged: {
            if (!active)
                return

            var now = Date.now()
            lastTranslationX = translation.x
            lastTranslationY = translation.y
            lastTranslationTime = now

            var minimumX = root.edgeMargin
            var minimumY = root.edgeMargin
            var maximumX = Math.max(minimumX, root.screenWidth - root.width - root.edgeMargin)
            var maximumY = Math.max(minimumY, root.screenHeight - root.height - root.edgeMargin)
            var rawX = startX + translation.x
            var rawY = startY + translation.y
            var positionX = root.draggedPosition(rawX, minimumX, maximumX)
            var positionY = root.draggedPosition(rawY, minimumY, maximumY)
            var samples = root.dragSamples
            samples.push({ t: now, x: positionX, y: positionY })
            if (samples.length > root.maxDragSamples)
                samples.shift()
            root.x = positionX
            root.y = positionY
            dragged = dragged || Math.abs(translation.x) > 8 || Math.abs(translation.y) > 8
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            if (!dragHandler.suppressTap)
                root.clicked()
        }
    }

    Timer {
        id: suppressTapTimer
        interval: 200
        repeat: false
        onTriggered: dragHandler.suppressTap = false
    }

    Connections {
        target: CWThemeManager
        function onThemeReadyToReload() {
            root.reloadTheme()
        }
    }

    onFloatingModeChanged: {
        if (floatingMode)
            enterFloatingMode()
        else if (animationReady)
            exitFloatingMode()
    }

    Component.onCompleted: {
        ensurePosition()
    }
}
