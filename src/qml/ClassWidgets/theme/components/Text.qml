import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme 1.0


Text {
    id: text

    font: {
        var f = AppCentral.getQFont(Configs.data.preferences.font, Utils.fontFamily)
        f.weight = Configs.data.preferences.font_weight || 600
        return f
    }
}
