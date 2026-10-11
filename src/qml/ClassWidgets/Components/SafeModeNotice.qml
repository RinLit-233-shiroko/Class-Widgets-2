import QtQuick
import RinUI

// 安全模式提示条：常驻、不自动消失。
// 默认文案刻意只有一句——托盘面板那种"瞥一眼"的地方，写长了没人看；
// 设置窗口和插件页面空间充裕，由调用方覆盖 text 补充具体影响。
InfoBar {
    id: root

    visible: AppCentral.safeMode
    timeout: -1
    severity: Severity.Warning
    title: qsTr("Safe mode")
    text: qsTr("Third-party plugins, themes and Plugin Plaza are disabled.")

    // 默认不可关闭；设置窗口按浮层使用时覆盖为 true。
    closable: false
}
