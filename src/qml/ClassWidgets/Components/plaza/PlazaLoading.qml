import QtQuick
import QtQuick.Layouts
import RinUI

ProgressRing {
    id: root
    Layout.alignment: Qt.AlignHCenter
    property int ringSize: 48

    size: root.ringSize
    indeterminate: true
}