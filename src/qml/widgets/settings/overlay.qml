import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Plugins

// 重叠组件设置页：轮播间隔 + 成员组件管理
// 成员组件主要入口：桌面组件编辑界面右键 → “编辑重叠组件”
// 排版按主程序 ClassWidgets/pages/editor/Settings.qml 的写法：
//   SettingExpander（外层卡片，带 title/description）
//     └ SettingItem { action: <内容> }（内层行，内容必须放 action:）
SettingsLayout {
    spacing: 0
    property int secValue: 5
    onSecValueChanged: settings.interval_ms = secValue * 1000
    Component.onCompleted: {
        secValue = (settings.interval_ms || 5000) / 1000
        reloadFrame()
    }

    // 插件后端：优先用主程序补丁注入的 backendObj（WidgetsContainer 打开设置时注入），
    // 兜底再从组件定义列表中查找
    property var backendObj: null
    property var overlayBackend: {
        if (backendObj) return backendObj
        if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
            var defs = WidgetsModel.definitionsList
            for (var i = 0; i < defs.length; i++) {
                if (defs[i].typeId === "classwidgets.overlay") return defs[i].backendObj || defs[i].backend_obj
                if (defs[i].id === "classwidgets.overlay") return defs[i].backendObj || defs[i].backend_obj
            }
        }
        return null
    }

    // 成员 typeId -> 显示名
    function nameOf(typeId) {
        if (typeof WidgetsModel !== "undefined" && WidgetsModel.definitionsList) {
            var defs = WidgetsModel.definitionsList
            for (var i = 0; i < defs.length; i++) {
                if (defs[i].id === typeId || defs[i].typeId === typeId)
                    return defs[i].name || typeId
            }
        }
        return typeId
    }

    // 组件框尺寸（按实例保存于后端）
    property int frameW: 0
    property int frameH: 0

    function reloadFrame() {
        if (!overlayBackend) return
        var f = overlayBackend.getFrameSize(instanceId)
        frameW = f ? (f.w || 0) : 0
        frameH = f ? (f.h || 0) : 0
    }
    function stepFrame(dw, dh) {
        if (!overlayBackend) return
        var w = frameW
        if (dw !== 0) {
            w = w > 0 ? w + dw : 400 + (dw > 0 ? dw : 0)
            if (w < 60) w = 60
        }
        var h = frameH
        if (dh !== 0) {
            h = h > 0 ? h + dh : 200 + (dh > 0 ? dh : 0)
            if (h < 40) h = 40
        }
        overlayBackend.setFrameSize(instanceId, w, h)
        reloadFrame()
    }
    function resetFrame() {
        if (!overlayBackend) return
        overlayBackend.setFrameSize(instanceId, 0, 0)
        frameW = 0
        frameH = 0
    }

    SettingExpander {
        Layout.fillWidth: true
        title: "轮播间隔"
        description: "每个组件停留后切换到下一个的时间（秒），加减按钮以 1 秒调整。"
        expanded: true

        SettingItem {
            action: RowLayout {
                Layout.preferredWidth: 260
                spacing: 8

                Button {
                    text: "−"
                    implicitWidth: 36
                    onClicked: secValue = Math.max(1, secValue - 1)
                }
                Text {
                    Layout.preferredWidth: 70
                    horizontalAlignment: Text.AlignHCenter
                    text: secValue + " 秒"
                    font.bold: true
                }
                Button {
                    text: "+"
                    implicitWidth: 36
                    onClicked: secValue = Math.min(60, secValue + 1)
                }
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: "组件框大小模式"
        description: "固定为最大组件：始终以最大成员组件的边框为组件框大小；跟随当前组件：组件框随当前展示组件的大小平滑变化。"
        expanded: true

        SettingItem {
            action: ComboBox {
                Layout.preferredWidth: 240
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "固定为最大组件", value: "max" },
                    { text: "跟随当前组件", value: "auto" }
                ]
                Component.onCompleted: {
                    var v = settings.frame_mode || "max"
                    var i = indexOfValue(v)
                    currentIndex = i >= 0 ? i : 0
                }
                onActivated: settings.frame_mode = currentValue
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: "组件框尺寸"
        description: "自定义本堆叠组件的框宽高（自适应 = 跟随内容）。"
        expanded: true

        SettingItem {
            action: ColumnLayout {
                spacing: 8
                Text {
                    text: (frameW > 0 && frameH > 0) ? frameW + " × " + frameH
                          : (frameW > 0) ? frameW + " × 自动"
                          : (frameH > 0) ? "自动 × " + frameH : "自适应"
                    font.bold: true
                }
                RowLayout {
                    spacing: 6
                    Button { text: "宽−"; onClicked: stepFrame(-10, 0) }
                    Button { text: "宽+"; onClicked: stepFrame(10, 0) }
                    Button { text: "高−"; onClicked: stepFrame(0, -10) }
                    Button { text: "高+"; onClicked: stepFrame(0, 10) }
                    Button { text: "自适应"; onClicked: resetFrame() }
                }
            }
        }
    }

    SettingExpander {
        Layout.fillWidth: true
        title: "显示切换条"
        description: "在组件右侧显示“切换”按钮，点击可手动切换到下一个成员组件。"
        expanded: true

        SettingItem {
            action: Switch {
                primaryColor: Colors.proxy.controlStrongColor
                checked: settings.show_switch_bar !== false
                onCheckedChanged: settings.show_switch_bar = checked
            }
        }
    }


    SettingExpander {
        Layout.fillWidth: true
        title: "成员组件"
        description: "已叠加到本组件内的成员，可在桌面组件编辑界面中右键“编辑重叠组件”添加/移除。"
        expanded: true

        SettingItem {
            action: ColumnLayout {
                spacing: 4
                Repeater {
                    model: overlayBackend ? overlayBackend.getMembers(instanceId) : []
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: (index + 1) + ". " + nameOf(modelData.typeId)
                            elide: Text.ElideMiddle
                        }
                        Button {
                            text: "移除"
                            implicitWidth: 52
                            implicitHeight: 26
                            onClicked: {
                                if (overlayBackend) overlayBackend.removeMember(instanceId, modelData.key)
                            }
                        }
                    }
                }
            }
        }
    }
}
