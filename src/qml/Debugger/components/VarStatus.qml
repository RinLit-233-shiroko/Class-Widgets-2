import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


GridLayout {
    id: varStatusLayout
    property alias model: varStatusRepeater.model
    columns: 2
    rowSpacing: 8
    columnSpacing: 12

    Repeater {
        id: varStatusRepeater
        model: [
            {"name": "current_time", "value": "null", tips: "当前时间"}
        ]

        delegate: ColumnLayout {
            // Layout.fillWidth: true
            Layout.preferredWidth: parent.width / parent.columns
            Layout.alignment: Qt.AlignTop
            // top
            Text {
                color: Colors.proxy.textSecondaryColor
                text: modelData.name + ":"
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop

                HoverHandler {
                    id: hoverHandler
                    enabled: modelData.hasOwnProperty("tips")
                }

                ToolTip {
                    id: toolTip
                    text: modelData.hasOwnProperty("tips") ? modelData.tips : ""
                    visible: hoverHandler.hovered
                }
            }
            // btm
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                text: modelData.value
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 3  // max lines of text

                HoverHandler {
                    id: fullValueContentHoverHandler
                }

                ToolTip {
                    id: fullValueContentToolTip
                    text: modelData.value
                    visible: fullValueContentHoverHandler.hovered
                }
            }
        }
    }
}