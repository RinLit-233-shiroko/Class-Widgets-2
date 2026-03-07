import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme 1.0


Text {
    id: title
    readonly property bool miniMode: Configs.data.preferences.mini_mode
    property int px: miniMode? 20 : 28

    // font.bold: true
    font: {
        var f = AppCentral.getQFont(Configs.data.preferences.font, Utils.fontFamily)
        f.pixelSize = px
        f.weight = Configs.data.preferences.font_weight || 600
        return f
    }

    Behavior on px { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
}
