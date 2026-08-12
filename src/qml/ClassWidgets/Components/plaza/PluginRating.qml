import QtQuick
import QtQuick.Layouts
import RinUI
import ClassWidgets.Components

// 插件评级信息：平均分支柱 + 星级分布 + 最近评论（与网页端「评分和评价」样式一致）
ColumnLayout {
    id: root

    property var ratings: []
    property bool loading: false

    spacing: 12

    readonly property int total: ratings instanceof Array ? ratings.length : 0
    readonly property real average: {
        if (total === 0)
            return 0
        var sum = 0
        for (var i = 0; i < ratings.length; i++)
            sum += Number(ratings[i].rating) || 0
        return sum / total
    }
    readonly property color starColor: Theme.isDark() ? "#FFD780" : "#d39300"

    function countForScore(score) {
        var count = 0
        for (var i = 0; i < total; i++) {
            if (Number(ratings[i].rating) === score)
                count++
        }
        return count
    }

    function commentReviews() {
        var result = []
        for (var i = 0; i < total && result.length < 2; i++) {
            if (ratings[i].comment)
                result.push(ratings[i])
        }
        return result
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

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        visible: root.loading

        ProgressRing {
            anchors.centerIn: parent
            size: 38
            indeterminate: true
        }
    }

    // 平均分 + 星级分布
    RowLayout {
        Layout.fillWidth: true
        spacing: 16
        visible: !root.loading && root.total > 0

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                text: root.average.toFixed(1)
                typography: Typography.Title
            }

            Text {
                text: qsTr("%1 ratings").arg(root.total)
                typography: Typography.Caption
                color: Colors.proxy.textSecondaryColor
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [5, 4, 3, 2, 1]

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.preferredWidth: 36
                        spacing: 2

                        Text {
                            text: modelData
                            typography: Typography.Caption
                            color: root.starColor
                        }

                        Icon {
                            name: "ic_fluent_star_20_filled"
                            size: 12
                            color: root.starColor
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        radius: 4
                        color: Qt.rgba(root.starColor.r, root.starColor.g, root.starColor.b, 0.22)

                        Rectangle {
                            width: parent.width * (root.countForScore(modelData) / Math.max(root.total, 1))
                            height: parent.height
                            radius: parent.radius
                            color: root.starColor
                        }
                    }
                }
            }
        }
    }

    // 最近评论
    Repeater {
        model: !root.loading ? root.commentReviews() : []

        delegate: ColumnLayout {
            id: reviewItem
            Layout.fillWidth: true
            spacing: 6

            readonly property var review: modelData

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Colors.proxy.controlBorderColor
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.reviewName(reviewItem.review)
                    typography: Typography.BodyStrong
                    elide: Text.ElideRight
                    maximumLineCount: 1
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
                        color: index < Number(reviewItem.review.rating || 0) ? root.starColor : Colors.proxy.controlBorderColor
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: reviewItem.review.comment || ""
                typography: Typography.Body
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }

    Text {
        Layout.fillWidth: true
        visible: !root.loading && root.total === 0
        text: qsTr("No ratings yet")
        typography: Typography.Caption
        color: Colors.proxy.textSecondaryColor
    }
}
