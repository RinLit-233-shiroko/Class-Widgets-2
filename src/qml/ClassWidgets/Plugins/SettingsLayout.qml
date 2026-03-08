import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import RinUI
import ClassWidgets.Theme

ColumnLayout {
    id: settingsLayout

    // 属性
    property var settings: null
    property string instanceId: ""

    spacing: 4
}
