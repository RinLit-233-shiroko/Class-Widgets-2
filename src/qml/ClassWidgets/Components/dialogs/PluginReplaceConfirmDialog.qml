import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI


Dialog {
    id: pluginReplaceDialog
    property string pluginName: ""
    property string pluginId: ""
    property string newVersion: ""
    property string existingVersion: ""
    property bool isUpdate: true  // true=更新, false=替换不同版本
    
    title: isUpdate ? qsTr("Update Plugin") : qsTr("Replace Plugin")
    modal: true
    width: Math.min(450, Screen.width * 0.3)
    height: Math.min(300, Screen.height * 0.3)
    standardButtons: Dialog.Ok | Dialog.Cancel

    contentItem: ColumnLayout {
        // spacing: 16
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            
            Icon {
                Layout.alignment: Qt.AlignTop
                name: "ic_fluent_warning_20_filled"
                color: Colors.proxy.systemCriticalColor
                size: 32
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                
                Text {
                    Layout.fillWidth: true
                    text: pluginName ? 
                        (isUpdate ?
                            qsTr("A newer version of '%1' is available.").arg(pluginName) :
                            qsTr("A plugin with the same ID '%1' already exists.").arg(pluginId)
                        ) : qsTr("Plugin Replacement")
                    wrapMode: Text.WordWrap
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }
                
                Text {
                    Layout.fillWidth: true
                    text: qsTr(
                        "Current version: %1\nNew version: %2\n\nDo you want to %3 this plugin?"
                    ).arg(existingVersion).arg(newVersion).arg(isUpdate ? qsTr("update") : qsTr("replace"))
                    wrapMode: Text.WordWrap
                    color: Colors.proxy.textSecondaryColor
                    font.pixelSize: 14
                }
            }
        }
        
        MenuSeparator {
            Layout.fillWidth: true
        }
        
        Text {
            Layout.fillWidth: true
            text: qsTr("Note: Replacing a plugin will remove the old version completely.")
            wrapMode: Text.WordWrap
            color: Colors.proxy.textSecondaryColor
            font.pixelSize: 12
            // font.italic: true
        }
    }
}