import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme

Widget {
    id: root
    // text: qsTr("time")
    // property var dateTime: {
    //     "year": 1900,
    //     "month": 1,
    //     "day": 1,
    //     "weekday": 0,
    //     "hour": 0,
    //     "minute": 0,
    //     "second": 0
    // }

    text: qsTr("Text")
    readonly property bool editing: miniMode ? editingBtnMiniMode.checked : editingBtn.checked

    actions: ToggleButton {
        id: editingBtn
        flat: true
        implicitWidth: 20
        implicitHeight: 20
        icon.name: checked ? "ic_fluent_checkmark_20_regular" : "ic_fluent_edit_20_regular"
    }

    RowLayout {
        anchors.centerIn: parent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 12

        ToggleButton {
            id: editingBtnMiniMode
            flat: true
            implicitWidth: 28
            implicitHeight: 28
            icon.name: checked ? "ic_fluent_checkmark_20_regular" : "ic_fluent_edit_20_regular"
            visible: miniMode
        }

        RowLayout {
            visible: !editing
            opacity: settings.text ? 1 : 0.6
            MarqueeTitle {
                visible: settings && settings.marquee
                width: settings.max_width
                text: settings.text || qsTr("Enter Text")
            }
            Title {
                id: titleLabel
                width: !settings ? Math.max(titleLabel.contentWidth, 150) : 150
                visible: !settings || !settings.marquee
                text: settings.text || qsTr("Enter Text")
            }
        }

        TextField {
            Layout.fillHeight: true
            id: textTextField
            visible: editing
            Layout.preferredWidth: Math.max(settings.max_width, 150, titleLabel.contentWidth)
            font.pixelSize: miniMode ? 20 : 28

            onEditingFinished: {
                console.log(textTextField.text)
                console.log(settings.text)
                root.updateSettings({"text": textTextField.text})
                console.log(settings.text)
            }
            Component.onCompleted: {
                textTextField.text = settings.text
            }
        }
    }

    onSettingsChanged: {
        textTextField.text = settings.text
    }

    // Component.onCompleted: {
    //     Qt.callLater(function() {
    //         dateTime = backend.getDateTime()
    //     })
    // }
}
