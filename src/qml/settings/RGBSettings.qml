import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import RinUI
import ClassWidgets

Rectangle {
    id: rgbSettingsPage
    
    color: Theme.backgroundColor
    
    // RGB效果管理器
    property var rgbManager: null
    
    // 当前选中效果
    property string selectedEffect: "Static"
    property color selectedColor: "#ff0000"
    property real effectSpeed: 1.0
    property real effectBrightness: 1.0
    property bool rgbEnabled: false
    
    // 颜色对话框
    ColorDialog {
        id: colorDialog
        title: "选择颜色"
        selectedColor: selectedColor
        onAccepted: {
            selectedColor = colorDialog.selectedColor
            updateManagerColor()
        }
    }
    
    // 更新管理器颜色
    function updateManagerColor() {
        if (rgbManager) {
            rgbManager.setColor(selectedColor.r * 255, selectedColor.g * 255, selectedColor.b * 255)
        }
    }
    
    // 更新管理器效果
    function updateManagerEffect() {
        if (rgbManager) {
            rgbManager.setEffect(selectedEffect)
            rgbManager.speed = effectSpeed
            rgbManager.brightness = effectBrightness
        }
    }
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: 24
        contentWidth: availableWidth
        
        ColumnLayout {
            width: parent.width
            spacing: 24
            
            // 标题
            Label {
                text: "RGB 效果设置"
                font.pixelSize: 24
                font.weight: Font.Bold
            }
            
            // 启用开关
            GroupBox {
                title: "RGB 效果"
                Layout.fillWidth: true
                
                Switch {
                    id: enableSwitch
                    text: "启用 RGB 动态效果"
                    checkable: true
                    checked: rgbEnabled
                    onToggled: {
                        rgbEnabled = checked
                        if (rgbManager) {
                            rgbManager.enabled = checked
                        }
                    }
                }
                
                Label {
                    text: "启用后，小组件将跟随RGB效果实时变色（仅对RGB主题生效）"
                    font.pixelSize: 12
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                }
            }
            
            // 效果选择
            GroupBox {
                title: "效果类型"
                Layout.fillWidth: true
                enabled: rgbEnabled
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // OpenRGB标准效果
                    Label {
                        text: "OpenRGB 标准效果"
                        font.weight: Font.Medium
                    }
                    
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Repeater {
                            // OpenRGB标准效果（前5个）
                            model: rgbManager ? rgbManager.getEffectList().slice(0, 5) : []
                            
                            delegate: Button {
                                text: modelData.display || modelData.name
                                checkable: true
                                checked: selectedEffect === modelData.name
                                onClicked: {
                                    selectedEffect = modelData.name
                                    updateManagerEffect()
                                }
                            }
                        }
                    }
                    
                    // 扩展效果
                    Label {
                        text: "扩展效果"
                        font.weight: Font.Medium
                    }
                    
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        Repeater {
                            // 扩展效果（后5个）
                            model: rgbManager ? rgbManager.getEffectList().slice(5) : []
                            
                            delegate: Button {
                                text: modelData.display || modelData.name
                                checkable: true
                                checked: selectedEffect === modelData.name
                                onClicked: {
                                    selectedEffect = modelData.name
                                    updateManagerEffect()
                                }
                            }
                        }
                    }
                }
            }
            
            // 预设效果
            GroupBox {
                title: "预设效果"
                Layout.fillWidth: true
                enabled: rgbEnabled
                
                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Repeater {
                        model: rgbManager ? rgbManager.getPresetList() : []
                        
                        delegate: Button {
                            text: modelData.display || modelData.name
                            onClicked: {
                                if (rgbManager) {
                                    rgbManager.applyPreset(modelData.name)
                                }
                            }
                        }
                    }
                }
            }
            
            // 颜色设置
            GroupBox {
                title: "颜色设置"
                Layout.fillWidth: true
                enabled: rgbEnabled
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    // 主颜色
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Label { text: "主颜色" }
                        
                        Rectangle {
                            width: 48
                            height: 48
                            radius: 8
                            color: selectedColor
                            border.width: 1
                            border.color: "#80000000"
                        }
                        
                        Button {
                            text: "选择颜色"
                            onClicked: colorDialog.open()
                        }
                        
                        Item { Layout.fillWidth: true }
                    }
                    
                    // 速度
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Label { text: "速度" }
                        
                        Slider {
                            id: speedSlider
                            Layout.fillWidth: true
                            from: 0.1
                            to: 10.0
                            value: effectSpeed
                            onValueChanged: {
                                effectSpeed = value
                                updateManagerEffect()
                            }
                        }
                        
                        Label {
                            text: effectSpeed.toFixed(1)
                            width: 30
                        }
                    }
                    
                    // 亮度
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        
                        Label { text: "亮度" }
                        
                        Slider {
                            id: brightnessSlider
                            Layout.fillWidth: true
                            from: 0.0
                            to: 1.0
                            value: effectBrightness
                            onValueChanged: {
                                effectBrightness = value
                                updateManagerEffect()
                            }
                        }
                        
                        Label {
                            text: Math.round(effectBrightness * 100) + "%"
                            width: 30
                        }
                    }
                }
            }
            
            // 实时预览
            GroupBox {
                title: "实时预览"
                Layout.fillWidth: true
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 100
                    radius: 16
                    color: selectedColor
                    
                    // 发光效果
                    layer.enabled: true
                    layer.effect: Glow {
                        radius: 16
                        samples: 32
                        color: selectedColor
                        source: parent
                    }
                    
                    Label {
                        anchors.centerIn: parent
                        text: "预览颜色"
                        color: Qt.luma(selectedColor) > 0.5 ? "#000000" : "#ffffff"
                        font.weight: Font.Bold
                    }
                    
                    // 颜色动画
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
            }
        }
    }
    
    // 加载当前设置
    Component.onCompleted: {
        if (rgbManager) {
            rgbEnabled = rgbManager.enabled
            selectedEffect = rgbManager.currentEffect
            effectSpeed = rgbManager.speed
            effectBrightness = rgbManager.brightness
            var c = rgbManager.currentColor
            selectedColor = Qt.rgba(c[0]/255, c[1]/255, c[2]/255, 1)
        }
    }
}
