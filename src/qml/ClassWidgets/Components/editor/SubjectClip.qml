import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

Clip {
    id: subjectClip
    width: subjectsGrid.cellWidth - 8
    height: subjectsGrid.cellHeight - 6

    // 选择模式：由 Subjects.qml 顶部工具栏切换；selected 表示本卡片已被选中。
    property bool selectionMode: false
    property bool selected: false
    property bool readOnly: false

    signal editRequested(string subjectId, string name, string simplifiedName, string teacher,
                         string icon, string color, string location, bool isLocalClassroom)
    signal selectionToggled(string subjectId)
    signal deleteRequested(string subjectId)

    // 选择模式下点击切换选中状态，否则打开编辑窗口。
    onClicked: {
        if (subjectClip.selectionMode)
            selectionToggled(subjectId)
        else
            editRequested(
                subjectId, subjectNameText, subjectSimplifiedNameText, subjectTeacherText,
                subjectIcon, subjectColorText, subjectLocationText, subjectIsLocal
            )
    }

    // 选中/悬停高亮。用覆盖层而不是改写 Frame 的 border：
    // Clip 的 border 别名指向 RinUI Frame 内部已绑定的属性，外部再写会与其绑定冲突。
    Rectangle {
        anchors.fill: parent
        z: 1
        color: "transparent"
        radius: subjectClip.radius
        border.width: subjectClip.selected || subjectClip.hovered ? 1 : 0
        border.color: subjectClip.selected ? Colors.proxy.primaryColor
                                           : Colors.proxy.controlBorderColor
    }

    // 右键删除（替代原先编辑窗口内的删除按钮）
    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: contextMenu.open()
    }

    Menu {
        id: contextMenu
        objectName: "subjectContextMenu"

        MenuItem {
            icon.name: "ic_fluent_edit_20_regular"
            text: qsTr("Edit")
            enabled: !subjectClip.selectionMode
            onTriggered: subjectClip.editRequested(
                subjectClip.subjectId, subjectClip.subjectNameText, subjectClip.subjectSimplifiedNameText,
                subjectClip.subjectTeacherText, subjectClip.subjectIcon, subjectClip.subjectColorText,
                subjectClip.subjectLocationText, subjectClip.subjectIsLocal
            )
        }
        MenuItem {
            icon.name: "ic_fluent_delete_20_regular"
            text: qsTr("Remove")
            enabled: !subjectClip.readOnly
            onTriggered: subjectClip.deleteRequested(subjectClip.subjectId)
        }
    }

    // 选择模式的勾选框，覆盖在卡片右上角。
    CheckBox {
        z: 2
        visible: subjectClip.selectionMode
        checked: subjectClip.selected
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 6
        onClicked: subjectClip.selectionToggled(subjectClip.subjectId)
    }

    property string subjectId: modelData.id
    property string subjectIcon: modelData.icon || ""
    property string subjectSimplifiedNameText: modelData.simplifiedName || ""
    property string subjectNameText: modelData.name
    property string subjectTeacherText: modelData.teacher || ""
    property string subjectLocationText: modelData.location || ""
    property string subjectColorText: modelData.color || ""
    property bool subjectIsLocal: modelData.isLocalClassroom !== false

    // Keep the card frame's default background. These colors are only used by
    // the subject icon tile, following ScheduleCourseCard's color palette.
    readonly property color subjectBaseColor: subjectColorText || Colors.proxy.systemNeutralColor
    readonly property bool darkTheme: Theme.currentTheme
        ? Theme.currentTheme.isDark
        : false
    readonly property real surfaceLuminance: darkTheme ? 0.05 : 0.72
    readonly property real textLuminance: darkTheme ? 0.60 : 0.05
    readonly property real toneSaturationCap: 0.8

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

    function atLuminance(base, target) {
        if (!base || base.hslHue === undefined)
            return base
        const hue = base.hslHue < 0 ? 0 : base.hslHue
        const saturation = Math.min(base.hslSaturation, toneSaturationCap)
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

    readonly property color subjectIconBackgroundColor: atLuminance(
        subjectBaseColor, surfaceLuminance
    )
    readonly property color subjectIconColor: atLuminance(
        subjectBaseColor, textLuminance
    )

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            // radius: 14
            radius: width / 2
            color: subjectIconBackgroundColor

            Icon {
                anchors.centerIn: parent
                size: 24
                color: subjectIconColor
                name: subjectIcon || "ic_fluent_hexagon_three_20_regular"
            }

            // 非本班课程提示
            Rectangle {
                visible: !subjectIsLocal
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: 26
                height: 26
                radius: width / 2
                color: Colors.proxy.systemCautionBackgroundColor

                Icon {
                    anchors.centerIn: parent
                    color: Colors.proxy.systemCautionColor
                    size: 18
                    name: "ic_fluent_sign_out_20_filled"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                typography: Typography.Body
                text: subjectNameText
                font.pixelSize: 15
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            RowLayout {
                visible: subjectTeacherText.length > 0
                Layout.fillWidth: true
                spacing: 6

                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    size: 14
                    opacity: 0.7
                    name: "ic_fluent_person_20_regular"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 0
                    typography: Typography.Caption
                    opacity: 0.85
                    text: subjectTeacherText
                    elide: Text.ElideRight
                    color: Theme.currentTheme.colors.textSecondaryColor
                    maximumLineCount: 1
                }
            }

            RowLayout {
                visible: subjectLocationText.length > 0
                Layout.fillWidth: true
                spacing: 6

                Icon {
                    Layout.alignment: Qt.AlignVCenter
                    size: 14
                    opacity: 0.7
                    name: "ic_fluent_location_20_regular"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.minimumWidth: 0
                    typography: Typography.Caption
                    opacity: 0.85
                    color: Theme.currentTheme.colors.textSecondaryColor
                    text: subjectLocationText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }
    }
}
