import QtQuick
import QtQuick.Controls
import RinUI

/*
 * One logical schedule entry.
 *
 * A card owns exactly one entry and one hit area. Adjacent cards may look
 * visually connected, but selection, clicks, and the flyout anchor remain
 * independent per card.
 */
Item {
    id: root
    // Content may extend beyond the first segment of a merged course group.
    clip: false

    property var entry: null
    // Courses without an explicit subject color (the default course) use
    // RinUI's neutral system color instead of the theme accent color.
    readonly property color defaultCourseColor: Colors.proxy.systemNeutralColor
    property color cardColor: defaultCourseColor

    // --- Derived card palette -------------------------------------------
    // `cardColor` is subject data: any hue at any brightness. Stacking it at
    // different alpha values makes every card read at a different strength,
    // so instead each tone below is rebuilt at a pinned *relative luminance*
    // while keeping the subject's hue and saturation. Cards keep their
    // identity, but surface and text contrast stop depending on how dark or
    // how bright the chosen color happens to be.
    readonly property bool darkTheme: Theme.currentTheme
        ? Theme.currentTheme.isDark
        : false

    // Pinning luminance rather than HSL lightness is the whole point: at
    // equal HSL lightness a yellow is far more luminous than a blue, which
    // is exactly the drift that leaves some labels unreadable.
    //
    // The two themes are deliberately asymmetric. Contrast wants the label at
    // the far end of the range, but chroma collapses as luminance rises: at
    // text luminance 0.95 every hue is forced to near-white, because blue
    // contributes only 0.0722 to luminance. So the dark tones are kept as dim
    // as 4.5:1 allows and the selected surface is kept dim too, which is what
    // lets a dark-theme label stay recognisably coloured instead of white.
    readonly property real surfaceLuminance: darkTheme ? 0.05 : 0.72
    readonly property real highlightLuminance: darkTheme ? 0.11 : 0.40
    // Never inherited from the subject: a near-black or near-white subject
    // color must not be able to make its own label unreadable.
    readonly property real textLuminance: darkTheme ? 0.60 : 0.05
    readonly property real toneSaturationCap: 0.8
    readonly property real surfaceAlpha: 0.75

    function channelLuminance(c) {
        return c <= 0.04045
            ? c / 12.92
            : Math.pow((c + 0.055) / 1.055, 2.4)
    }

    // WCAG relative luminance of a color.
    function relativeLuminance(c) {
        return 0.2126 * channelLuminance(c.r)
            + 0.7152 * channelLuminance(c.g)
            + 0.0722 * channelLuminance(c.b)
    }

    // Rebuild `base` at a target luminance, keeping its hue and saturation.
    // Relative luminance rises monotonically with HSL lightness for a fixed
    // hue/saturation, so a bisection converges on the wanted tone. Returns
    // the input untouched when it is not a usable color, so an unresolved
    // theme cannot turn a binding error into a broken card.
    function atLuminance(base, target) {
        if (!base || base.hslHue === undefined)
            return base
        const hue = base.hslHue < 0 ? 0 : base.hslHue
        const saturation = Math.min(base.hslSaturation, toneSaturationCap)
        let lo = 0.0
        let hi = 1.0
        for (let i = 0; i < 20; ++i) {
            const mid = (lo + hi) / 2
            if (relativeLuminance(Qt.hsla(hue, saturation, mid, 1.0)) < target)
                lo = mid
            else
                hi = mid
        }
        return Qt.hsla(hue, saturation, (lo + hi) / 2, 1.0)
    }

    readonly property color cardSurfaceColor: Qt.alpha(
        atLuminance(cardColor, surfaceLuminance),
        surfaceAlpha
    )
    readonly property color cardHighlightColor: Qt.alpha(
        atLuminance(cardColor, highlightLuminance),
        surfaceAlpha
    )
    readonly property color cardTextColor: atLuminance(cardColor, textLuminance)

    property string cardTitle: ""
    property string timeText: ""
    property var timeTexts: []
    property string iconName: ""

    property real startY: 0
    property real cardHeight: 2
    property bool tightAbove: false
    property bool tightBelow: false
    property real tightTopInset: 0
    property real tightBottomInset: 0
    property bool hasJoinAbove: false
    property bool hasJoinBelow: false
    property bool showContent: true
    property real groupContentHeight: 0
    property real groupTailBottomInset: 0
    property int hiddenGroupTimeIndex: -1
    property bool showOnlyFirstTime: false
    // `selected` is the logical entry that owns the flyout/content. A merged
    // run may highlight every segment while only this entry reveals its time.
    property bool selected: false
    property bool highlighted: selected
    property int cornerRadius: 6
    property int topInset: 4
    property int horizontalInset: 4
    readonly property var cardEntry: entry
    readonly property int titleLineHeight: 18
    readonly property int timeLineHeight: 14
    readonly property int contentSpacing: 4
    readonly property bool isGroupLead: groupContentHeight > 0
    readonly property bool isMergedEntry: isGroupLead
        || hasJoinAbove || hasJoinBelow
    readonly property bool isGroupTail: hasJoinAbove && !hasJoinBelow
    readonly property int contentTopInset: isMergedEntry ? 12 : 8
    readonly property real contentLayoutHeight: isGroupLead
        ? groupContentHeight
        : height
    readonly property var resolvedTimeTexts: timeTexts && timeTexts.length > 0
        ? timeTexts
        : (timeText.length > 0 ? [timeText] : [])
    readonly property var displayedTimeTexts: {
        const source = resolvedTimeTexts || []
        if (showOnlyFirstTime && source.length > 1)
            return source.slice(0, 1)
        const hiddenIndex = hiddenGroupTimeIndex
        if (hiddenIndex < 0 || hiddenIndex >= source.length)
            return source
        const filtered = []
        for (let i = 0; i < source.length; ++i) {
            if (i !== hiddenIndex)
                filtered.push(source[i])
        }
        return filtered
    }
    readonly property bool showTitle: showContent
        && contentLayoutHeight >= contentTopInset + titleLineHeight
    // A joined continuation is visually transparent by default. Selecting
    // that segment temporarily reveals only its own time, without repeating
    // the title or icon.
    readonly property bool showSelectedTime: !showContent && selected
    readonly property bool timeContentEnabled: showContent || showSelectedTime
    readonly property int availableTimeLines: showTitle
        ? Math.max(
            0,
            Math.floor(
                (contentLayoutHeight - contentTopInset - titleLineHeight)
                    / (timeLineHeight + contentSpacing)
            )
        )
        : Math.max(
            0,
            Math.floor(
                (contentLayoutHeight - contentTopInset + contentSpacing)
                    / (timeLineHeight + contentSpacing)
            )
        )
    readonly property int visibleTimeLineCount: timeContentEnabled
        ? Math.min(
            showSelectedTime ? 1 : displayedTimeTexts.length,
            availableTimeLines
        )
        : 0
    readonly property var visibleTimeTexts: displayedTimeTexts.slice(
        0,
        visibleTimeLineCount
    )
    readonly property bool showTime: visibleTimeLineCount > 0
    readonly property real contentHeight: showTitle
        ? titleLineHeight
            + visibleTimeLineCount * (timeLineHeight + contentSpacing)
        : visibleTimeLineCount * timeLineHeight
            + Math.max(0, visibleTimeLineCount - 1) * contentSpacing
    // Below this height a card cannot spare the usual top inset without
    // pushing its content into the lower half, so the content is centred in
    // the card instead of being pinned to the top.
    readonly property int minimumTopAlignedHeight: 36
    // A merged group lead is excluded: its content is laid out across the whole
    // group (contentLayoutHeight), not inside its own segment, so its own
    // height is not the box the content should be centred in.
    readonly property bool centerContentVertically: !isGroupLead
        && height < minimumTopAlignedHeight
    readonly property real contentY: centerContentVertically
        ? Math.max(0, (height - contentHeight) / 2)
        : contentTopInset

    signal clicked(var entry, Item card)

    readonly property real effectiveTopInset: hasJoinAbove
        ? (tightAbove ? tightTopInset : 0)
        : (tightAbove ? tightTopInset : topInset)
    readonly property real effectiveBottomInset: hasJoinBelow
        ? (tightBelow ? tightBottomInset : 0)
        : (tightBelow ? tightBottomInset : topInset)

    x: horizontalInset
    y: startY + effectiveTopInset
    width: Math.max(1, parent.width - horizontalInset * 2)
    height: Math.max(
        2,
        cardHeight - effectiveTopInset - effectiveBottomInset
    )
    z: highlighted ? 4 : (groupContentHeight > 0 ? 3 : 2)

    // A merged course paints its translucent base exactly once, on the group
    // lead, and stretches it across every segment. This avoids double-alpha
    // seams where adjacent semi-transparent delegates meet.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.isGroupLead
            ? Math.max(
                parent.height,
                root.groupContentHeight
                    - root.effectiveTopInset
                    - root.groupTailBottomInset
            )
            : parent.height
        visible: root.isGroupLead || (!root.hasJoinAbove && !root.hasJoinBelow)
        topLeftRadius: root.cornerRadius
        topRightRadius: root.cornerRadius
        bottomLeftRadius: root.cornerRadius
        bottomRightRadius: root.cornerRadius
        color: root.cardSurfaceColor
    }

    // Selection remains per logical entry, but a merged run is highlighted as
    // one visual course. The overlay is a brighter tone of the same base,
    // not a more opaque copy of it, so selecting a card no longer changes how
    // much of the panel shows through. Each segment supplies its own corners
    // so the overlay still follows the rounded silhouette of the whole run.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        // The group base now stops at the tail's effective bottom edge, and
        // the tail delegate already ends there. No extra bottom margin is
        // needed, so the selected highlight matches the unselected geometry.
        anchors.bottomMargin: 0
        visible: root.highlighted
        topLeftRadius: root.hasJoinAbove ? 0 : root.cornerRadius
        topRightRadius: root.hasJoinAbove ? 0 : root.cornerRadius
        bottomLeftRadius: root.hasJoinBelow ? 0 : root.cornerRadius
        bottomRightRadius: root.hasJoinBelow ? 0 : root.cornerRadius
        color: root.cardHighlightColor
    }

    Column {
        id: cardContent
        x: 12
        y: root.contentY
        width: Math.max(1, parent.width - 24)
        height: root.contentHeight
        spacing: root.contentSpacing
        visible: root.showTitle || root.showTime
        clip: true

        Row {
            id: titleRow
            width: parent.width
            height: root.titleLineHeight
            spacing: 10
            clip: true
            visible: root.showTitle

            Icon {
                id: cardIcon
                name: root.iconName
                size: 16
                width: 16
                height: 16
                color: root.cardTextColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: cardTitleText
                width: Math.max(1, parent.width - cardIcon.width - 10)
                height: root.titleLineHeight
                text: root.cardTitle
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                clip: true
                color: root.cardTextColor
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Repeater {
            model: root.visibleTimeTexts

            delegate: Text {
                width: parent.width
                height: root.timeLineHeight
                text: modelData
                wrapMode: Text.NoWrap
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                clip: true
                color: root.cardTextColor
                font.pixelSize: 10
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    MouseArea {
        id: lineHitArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.clicked(root.cardEntry, root)
    }
}
