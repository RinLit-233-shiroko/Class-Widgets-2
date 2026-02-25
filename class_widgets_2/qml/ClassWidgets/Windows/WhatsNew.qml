import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components
import ClassWidgets.Data

ApplicationWindow {
    id: whatsNewWindow
    icon: PathManager.assets("images/icons/cw2_whatsnew.png")
    title: qsTr("What's New ╰(*°▽°*)╯")
    width: Screen.width * 0.4
    height: Screen.height * 0.6
    
    property int currentPage: 0
    property int pendingPage: -1
    property bool isAnimating: false

    // 拦截关闭事件
    onClosing: function(event) {
        event.accepted = false
        whatsNewWindow.hide()
    }

    Component.onCompleted: {
        updateContent()
    }

    Item {
        Timer {
            id: pageSwitchTimer
            interval: 150
            repeat: false
            onTriggered: {
                currentPage = pendingPage
                pendingPage = -1
                updateContent()
                contentRect.opacity = 1
                isAnimating = false
            }
        }
    }

    /* ================== Core Logic ================== */
    function updateContent() {
        if (currentPage < 0 || currentPage >= WhatsNewData.totalPages)
            return

        // Direct array access to avoid function call type annotation issues
        var featuresList = WhatsNewData.features
        if (currentPage < 0 || currentPage >= featuresList.length)
            return

        var feature = featuresList[currentPage]
        if (!feature) return

        titleText.text = feature.title
        descriptionText.text = feature.description
        featureIcon.name = feature.icon

        // Update action button if exists
        if (feature.actionButtonText && feature.actionButtonAction) {
            actionButton.text = feature.actionButtonText
            actionButton.visible = true
        } else {
            actionButton.visible = false
        }

        featureImage.source = feature.image && feature.image !== ""
            ? feature.image
            : PathManager.images("whatsnew/template.png")

        updatePageIndicator()
    }

    function updatePageIndicator() {
        pageIndicatorText.text =
            (currentPage + 1) + " / " + WhatsNewData.totalPages

        previousButton.visible = currentPage > 0
        nextButton.visible = currentPage < WhatsNewData.totalPages - 1
        doneButton.visible = currentPage == WhatsNewData.totalPages - 1
    }

    function switchToPage(pageIndex) {
        if (isAnimating) return
        if (pageIndex < 0 || pageIndex >= WhatsNewData.totalPages) return

        isAnimating = true
        pendingPage = pageIndex
        contentRect.opacity = 0
        pageSwitchTimer.restart()
    }

    function nextPage() {
        switchToPage(currentPage + 1)
    }

    function previousPage() {
        switchToPage(currentPage - 1)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        anchors.bottomMargin: 16

        Image {
            id: featureImage
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: 400
            source: PathManager.images("whatsnew/template.png")
            fillMode: Image.PreserveAspectCrop
        }

        // Rectangle {
        //     id: contentRect
        //     Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        //     Layout.fillWidth: true
        //     Layout.fillHeight: true
        //     Layout.maximumWidth: 600
        //     color: "transparent"
        //
        //     Behavior on opacity {
        //         PropertyAnimation {
        //             duration: 150
        //         }
        //     }
        //
        //
        // }
        ColumnLayout {
            id: contentRect
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: 500
            Layout.minimumHeight: 150

            Behavior on opacity {
                PropertyAnimation {
                    duration: 150
                }
            }
            spacing: 12

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Icon {
                    id: featureIcon
                    name: "ic_fluent_star_20_regular"
                    size: 18
                }

                Text {
                    id: pageIndicatorText
                    // Layout.fillWidth: true
                    typography: Typography.Caption
                    horizontalAlignment: Text.AlignHCenter
                    text: "1 / " + WhatsNewData.totalPages
                }
            }

            Text {
                id: titleText
                Layout.fillWidth: true
                typography: Typography.Subtitle
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Feature Title")
                wrapMode: Text.WordWrap
            }

            Text {
                id: descriptionText
                Layout.fillWidth: true
                typography: Typography.Body
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Feature description will appear here...")
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            Hyperlink {
                id: actionButton
                Layout.alignment: Qt.AlignHCenter
                icon.name: "ic_fluent_arrow_right_20_regular"
                highlighted: true
                visible: false
                
                onClicked: {
                    var featuresList = WhatsNewData.features
                    var feature = featuresList[currentPage]
                    if (feature && feature.actionButtonAction) {
                        WhatsNewData.handleAction(feature.actionButtonAction)
                    }
                }
            }
        }

        Flow {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            spacing: 12
            
            ToolButton {
                id: previousButton
                size: 28
                implicitWidth: 36
                implicitHeight: 36
                icon.name: "ic_fluent_chevron_left_20_regular"
                visible: false
                
                onClicked: {
                    previousPage()
                }
            }
            
            ToolButton {
                id: nextButton
                highlighted: true
                size: 28
                implicitWidth: 36
                implicitHeight: 36
                icon.name: "ic_fluent_chevron_right_20_regular"
                visible: true
                
                onClicked: {
                    nextPage()
                }

                Behavior on x {
                    NumberAnimation { duration: 200 }
                }
            }

            ToolButton {
                id: doneButton
                highlighted: true
                size: 24
                implicitWidth: 36
                implicitHeight: 36
                icon.name: "ic_fluent_checkmark_20_regular"
                visible: false

                onClicked: {
                    whatsNewWindow.hide()
                }
            }
        }
    }

    // 测试水印
    Watermark {
        anchors.centerIn: parent
    }
}