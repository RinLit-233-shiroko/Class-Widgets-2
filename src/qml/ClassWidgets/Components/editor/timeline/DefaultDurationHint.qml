import QtQuick
import QtQuick.Layouts
import RinUI

InfoBar {
    Layout.fillWidth: true
    position: Position.BottomRight
    severity: Severity.Info
    timeout: 10000
    isDynamic: true
    title: qsTranslate("Timeline", "Customize default durations")
    text: qsTranslate("Timeline", "Choose default durations for new classes, breaks, and activities to speed up editing.")

    customContent: Hyperlink {
        text: qsTranslate("Timeline", "Open Editor Settings")
        onClicked: {
            navigationView.push(PathManager.qml("pages/editor/Settings.qml"))
        }
    }
}
