import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI

// Persistent editor chrome. This is intentionally an Item rather than a
// transient popup: the toolbar belongs to the expanded timeline and stays in
// the same place while the timeline is being edited.
Item {
    id: root

    property bool toolbarVisible: false
    property bool compactLayout: false
    property real zoomValue: 2.2
    property real overviewScale: 0.5
    property bool undoAvailable: false
    property bool redoAvailable: false
    property Item sourceItem: null

    readonly property real cornerRadius: 8
    readonly property real panelGap: 8
    readonly property real panelPadding: 6
    readonly property real baseZoom: 2.2
    readonly property real recommendedMinZoom: 1.5
    readonly property real overviewMinZoom: Math.max(0.25,
        Math.min(baseZoom - 0.1, overviewScale))
    readonly property real minZoom: Math.max(recommendedMinZoom,
        overviewMinZoom)
    readonly property real maxZoom: baseZoom * 2 - overviewMinZoom
    readonly property real zoomRange: Math.max(0.001, maxZoom - minZoom)
    readonly property int zoomSnapIntervals: 12
    readonly property real normalizedZoom: Math.max(0,
        Math.min(1, (zoomValue - minZoom) / zoomRange))
    readonly property real controlsContentHeight: Math.max(
        zoomSlider.implicitHeight,
        undoButton.implicitHeight,
        redoButton.implicitHeight,
        controlsSeparator.implicitHeight
    )
    readonly property real actionsContentHeight: Math.max(
        classButton.implicitHeight,
        breakButton.implicitHeight,
        activityButton.implicitHeight
    )
    readonly property real contentHeight: Math.max(
        controlsContentHeight, actionsContentHeight
    )

    signal undoRequested()
    signal redoRequested()
    signal addRequested(string type)
    signal zoomRequested(real value)

    visible: root.toolbarVisible
    enabled: visible
    z: 20
    opacity: root.toolbarVisible ? 1 : 0
    implicitWidth: controlsPanel.implicitWidth + panelGap
        + actionsPanel.implicitWidth
    implicitHeight: contentHeight + panelPadding * 2
    width: parent ? Math.min(implicitWidth, Math.max(0, parent.width - 16))
        : implicitWidth
    height: implicitHeight
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 16
    anchors.horizontalCenter: parent.horizontalCenter

    transform: Translate {
        y: root.toolbarVisible ? 0 : 8
        Behavior on y {
            NumberAnimation {
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    RowLayout {
        id: panelLayout
        anchors.fill: parent
        spacing: root.panelGap

        Item {
            id: controlsPanel
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: controlsContent.implicitWidth
                + root.panelPadding * 2
            implicitWidth: controlsContent.implicitWidth
                + root.panelPadding * 2
            implicitHeight: root.controlsContentHeight + root.panelPadding * 2
            Layout.preferredHeight: implicitHeight
            Layout.fillHeight: true

            Item {
                id: controlsBackground
                anchors.fill: parent
                clip: true
                layer.enabled: true
                layer.effect: Shadow {
                    style: "flyout"
                    source: controlsBackground
                }

                AcrylicBrush {
                    anchors.fill: parent
                    sourceItem: root.sourceItem
                    enabled: root.sourceItem !== null
                    radius: root.cornerRadius
                }
                Rectangle {
                    anchors.fill: parent
                    radius: root.cornerRadius
                    color: "transparent"
                    border.color: Theme.currentTheme.colors.flyoutBorderColor
                    border.width: 1
                }
            }

            RowLayout {
                id: controlsContent
                anchors.fill: parent
                anchors.margins: root.panelPadding
                spacing: 8

                Slider {
                    id: zoomSlider
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    from: 0.25
                    to: 0.75
                    stepSize: 1 / root.zoomSnapIntervals
                    value: root.normalizedZoom
                    onMoved: root.zoomRequested(
                        root.minZoom + value * root.zoomRange
                    )
                    toolTip.text: `${Math.round((value * 2 * 100))} %`
                    snapMode: Slider.SnapAlways
                    tickmarks: true
                }
                ToolSeparator { id: controlsSeparator }
                Button {
                    id: undoButton
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    flat: true
                    text: root.compactLayout ? "" : qsTr("Undo")
                    icon.name: "ic_fluent_arrow_undo_20_regular"
                    enabled: root.undoAvailable
                    onClicked: root.undoRequested()
                    ToolTip {
                        text: qsTr("Undo")
                        visible: root.compactLayout && parent.hovered
                    }
                }
                Button {
                    id: redoButton
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    flat: true
                    text: root.compactLayout ? "" : qsTr("Redo")
                    icon.name: "ic_fluent_arrow_redo_20_regular"
                    enabled: root.redoAvailable
                    onClicked: root.redoRequested()
                    ToolTip {
                        text: qsTr("Redo")
                        visible: root.compactLayout && parent.hovered
                    }
                }
            }
        }

        Item {
            id: actionsPanel
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: actionsContent.implicitWidth
                + root.panelPadding * 2
            implicitWidth: actionsContent.implicitWidth
                + root.panelPadding * 2
            implicitHeight: root.actionsContentHeight + root.panelPadding * 2
            Layout.preferredHeight: implicitHeight
            Layout.fillHeight: true

            Item {
                id: actionsBackground
                anchors.fill: parent
                clip: true
                layer.enabled: true
                layer.effect: Shadow {
                    style: "flyout"
                    source: actionsBackground
                }

                AcrylicBrush {
                    anchors.fill: parent
                    sourceItem: root.sourceItem
                    enabled: root.sourceItem !== null
                    radius: root.cornerRadius
                }
                Rectangle {
                    anchors.fill: parent
                    radius: root.cornerRadius
                    color: "transparent"
                    border.color: Theme.currentTheme.colors.flyoutBorderColor
                    border.width: 1
                }
            }

            RowLayout {
                id: actionsContent
                anchors.fill: parent
                anchors.margins: root.panelPadding
                spacing: 4

                Button {
                    id: classButton
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    flat: true
                    text: root.compactLayout ? "" : qsTr("Class")
                    icon.name: "ic_fluent_class_20_regular"
                    onClicked: root.addRequested("class")
                    ToolTip {
                        text: qsTr("Class")
                        visible: root.compactLayout && parent.hovered
                    }
                }
                Button {
                    id: breakButton
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    flat: true
                    text: root.compactLayout ? "" : qsTr("Break")
                    icon.name: "ic_fluent_drink_coffee_20_regular"
                    onClicked: root.addRequested("break")
                    ToolTip {
                        text: qsTr("Break")
                        visible: root.compactLayout && parent.hovered
                    }
                }
                Button {
                    id: activityButton
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    flat: true
                    text: root.compactLayout ? "" : qsTr("Activity")
                    icon.name: "ic_fluent_alert_20_regular"
                    onClicked: root.addRequested("activity")
                    ToolTip {
                        text: qsTr("Activity")
                        visible: root.compactLayout && parent.hovered
                    }
                }
            }
        }
    }
}
