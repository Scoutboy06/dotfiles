import QtQuick
import QtQuick.Controls

Slider {
    id: root

    required property var theme
    required property var motion

    implicitHeight: 28
    from: 0
    to: 1.1

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: 3
        color: root.theme.surface

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.theme.accent
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.pressed ? 18 : 16
        height: width
        radius: width / 2
        color: root.theme.accent
        border.width: 2
        border.color: root.theme.background

        Behavior on width {
            NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing }
        }
    }
}
