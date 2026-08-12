import QtQuick
import QtQuick.Layouts
import RinUI

GridLayout {
    id: root

    property var items: []
    property int minimumColumnWidth: 250

    columns: width >= minimumColumnWidth * 2 ? 2 : 1
    columnSpacing: 20
    rowSpacing: 16

    Repeater {
        model: root.items

        delegate: RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Icon {
                Layout.alignment: Qt.AlignTop
                name: modelData.icon || "ic_fluent_info_20_regular"
                size: 20
                color: Colors.proxy.textSecondaryColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: modelData.label || ""
                    typography: Typography.Caption
                    color: Colors.proxy.textSecondaryColor
                }

                // 支持超链接：当 modelData.valueUrl 存在时显示为 Hyperlink，否则显示普通 Text
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: modelData.valueUrl ? hyperlinkComponent : textComponent
                }

                Component {
                    id: textComponent
                    Text {
                        Layout.fillWidth: true
                        text: modelData.value || ""
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        maximumLineCount: 2
                    }
                }

                Component {
                    id: hyperlinkComponent
                    Hyperlink {
                        Layout.fillWidth: true
                        text: modelData.value || modelData.valueUrl
                        url: modelData.valueUrl
                    }
                }
            }
        }
    }
}
