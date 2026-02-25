import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme 1.0


Icon {
    id: text
    readonly property bool miniMode: Configs.data.preferences.mini_mode
    size: miniMode? 22 : 28
}
