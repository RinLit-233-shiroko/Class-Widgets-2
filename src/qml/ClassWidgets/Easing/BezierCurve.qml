pragma Singleton
import QtQuick 2.15

QtObject {
    // 尺寸变化（主题 Widget 的 implicitWidth / height）
    property var liquidBack: [0.175, 0.885, 0.32, 1.2, 1, 1]

    // 入场回弹（scale 0.8 → 1）
    // 起步果断，约 30% 处越过目标形成回弹，43% 左右就收敛，
    // 不像 liquidBack 那样一路拖到 66% 才见峰值、96% 才停稳。
    property var popBack: [0.15, 0.85, 0.35, 1.2, 1, 1]

    // popBack 的镜像，用于退场（scale 1 → 0.8）
    property var popBackIn: [0.65, -0.2, 0.85, 0.15, 1, 1]
}