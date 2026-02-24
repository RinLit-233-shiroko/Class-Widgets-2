import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

import QtQuick.Effects  // shadow

Item {
    id: root
    width: saveBackground.width
    height: saveBackground.height
    RectangularShadow {
        anchors.fill: saveBackground
        offset.y: 5
        radius: saveBackground.radius
        blur: 12
        color: Qt.darker(saveBackground.color, 1.3)
    }

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.margins: 8
    z: 99

    property bool collapsed: parent.width < 500

    Frame {
        id: saveBackground
        color: Colors.proxy.backgroundAcrylicColor

        RowLayout {
            spacing: 24
            RowLayout {
                visible: !collapsed
                spacing: 8
                Icon {
                    Layout.alignment: Qt.AlignCenter
                    name: "ic_fluent_calendar_day_20_regular"
                    size: 24
                }
                Text {
                    Layout.alignment: Qt.AlignCenter
                    text: AppCentral.scheduleEditor.filename
                    font.pixelSize: 14
                }
            }
            Button {
                highlighted: true
                icon.name: "ic_fluent_save_20_regular"
                text: "Save"
                onClicked: {
                    let result = AppCentral.scheduleManager.save()
                    if (result) {
                        floatLayer.createInfoBar({
                            title: qsTr("Saved"),
                            severity: Severity.Success,
                            text: qsTr("Schedule saved successfully")
                        })
                    } else {
                        floatLayer.createInfoBar({
                            title: qsTr("Save Failed"),
                            severity: Severity.Error,
                            text: qsTr("Failed to save schedule, see log for details")
                        })
                    }
                }
            }
        }
    }
}