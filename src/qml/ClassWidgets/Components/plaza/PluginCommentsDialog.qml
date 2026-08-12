import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import RinUI
import ClassWidgets.Components

// 查看全部评论对话框（与网页端「评分和评价」弹窗样式一致）
Dialog {
    id: root

    property var ratings: []
    property bool loading: false

    title: qsTr("Ratings and reviews")
    width: Math.min(680, parent ? parent.width * 0.92 : 600)
    height: Math.min(parent ? parent.height * 0.82 : 600, 700)
    modal: true
    standardButtons: Dialog.Ok

    // 排序方式：recent / highest / lowest
    property string sortValue: "recent"

    readonly property int totalWithComment: {
        var count = 0
        for (var i = 0; i < ratings.length; i++) {
            if (ratings[i].comment)
                count++
        }
        return count
    }

    readonly property var sortedReviews: {
        var filtered = []
        for (var i = 0; i < ratings.length; i++) {
            if (ratings[i].comment)
                filtered.push(ratings[i])
        }

        filtered.sort(function(a, b) {
            if (root.sortValue === "highest")
                return Number(b.rating || 0) - Number(a.rating || 0) || new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
            if (root.sortValue === "lowest")
                return Number(a.rating || 0) - Number(b.rating || 0) || new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
            return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
        })

        return filtered
    }

    function reviewName(review) {
        return review && review.profile && review.profile.display_name ? review.profile.display_name : qsTr("Anonymous user")
    }

    function reviewDate(review) {
        var date = new Date(review ? review.created_at : "")
        if (isNaN(date.getTime()))
            return ""
        return date.toLocaleDateString(Qt.locale(), "yyyy/M/d")
    }

    contentItem: ColumnLayout {
        spacing: 16

        // 排序选择器
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            Text {
                text: qsTr("Sort by:") + " "
                typography: Typography.Caption
                color: Colors.proxy.textSecondaryColor
            }

            ComboBox {
                model: [qsTr("Most recent"), qsTr("Highest rating"), qsTr("Lowest rating")]
                currentIndex: root.sortValue === "highest" ? 1 : root.sortValue === "lowest" ? 2 : 0
                onCurrentIndexChanged: {
                    root.sortValue = currentIndex === 1 ? "highest" : currentIndex === 2 ? "lowest" : "recent"
                }
            }
        }

        // 评论列表
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                width: parent.width
                height: contentHeight
                interactive: height < contentHeight
                spacing: 16
                clip: true

                delegate: Item {
                    id: reviewItem
                    width: ListView.view.width
                    height: childrenRect.height

                    readonly property var review: modelData

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: root.reviewName(reviewItem.review)
                                typography: Typography.BodyStrong
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.reviewDate(reviewItem.review)
                                typography: Typography.Caption
                                color: Colors.proxy.textSecondaryColor
                            }
                        }

                        RowLayout {
                            spacing: 2

                            Repeater {
                                model: 5

                                delegate: Icon {
                                    name: "ic_fluent_star_20_filled"
                                    size: 14
                                    color: index < Number(reviewItem.review.rating || 0) ? Theme.isDark() ? "#FFD780" : "#986F04" : Colors.proxy.controlBorderColor
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: reviewItem.review.comment || ""
                            typography: Typography.Body
                            wrapMode: Text.Wrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Colors.proxy.controlBorderColor
                            visible: index < root.sortedReviews.length - 1
                        }
                    }
                }

                model: root.sortedReviews

                header: Item {
                    width: parent.width
                    height: root.loading ? 100 : 0

                    ProgressRing {
                        anchors.centerIn: parent
                        size: 38
                        indeterminate: true
                        visible: root.loading
                    }
                }

                footer: Item {
                    width: parent.width
                    height: root.totalWithComment === 0 && !root.loading ? 80 : 0

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("No written reviews yet")
                        typography: Typography.Caption
                        color: Colors.proxy.textSecondaryColor
                        visible: root.totalWithComment === 0 && !root.loading
                    }
                }
            }
        }
    }
}
