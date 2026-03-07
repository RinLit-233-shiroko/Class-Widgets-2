import QtQuick
import QtQuick.Controls
import QtQuick.Window as QQW
import QtQuick.Layouts
import RinUI
import ClassWidgets.Theme


Widget {
    id: root
    text: qsTr("测试组件")

    RowLayout {
        anchors.centerIn: parent
        spacing: 10
        Icon {
            icon: "ic_fluent_symbols_20_regular"
        }
        Button {
            text: "Open"
            onClicked: backend.sayHello(settings.name)
        }
        // Title {
        //     id: randomText
        //     text: generateRandomText()
        // }
    }

    // Timer {
    //     interval: 1000
    //     running: true
    //     repeat: true
    //     onTriggered: randomText.text = generateRandomText()
    // }
    //
    // function generateRandomText() {
    //     const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    //     const length = Math.floor(Math.random() * 20)  // 随机长度 5~25
    //     let str = ""
    //     for (let i = 0; i < length; i++) {
    //         str += chars.charAt(Math.floor(Math.random() * chars.length))
    //     }
    //     return str
    // }
}