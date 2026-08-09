import QtQuick

Rectangle {
    id: root

    required property string label
    required property bool active
    required property var theme
    required property var motion
    property bool hoverEnabled: true
    signal activated

    readonly property bool hovered: hoverEnabled && hover.hovered
    readonly property real compactWidth: Math.max(22, labelText.implicitWidth + 12)

    width: compactWidth + (active ? 12 : 0)
    height: 22
    radius: height / 2
    scale: tap.pressed ? 0.88 : hovered ? 1.08 : 1
    color: active ? theme.accent : hovered ? Qt.lighter(theme.surface, 1.25) : "transparent"

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        color: root.active ? root.theme.background : root.theme.foreground
        font.family: root.theme.fontFamily
        font.pixelSize: 12
        font.bold: root.active

        Behavior on color {
            ColorAnimation { duration: root.motion.fast }
        }
    }

    HoverHandler { id: hover }

    TapHandler {
        id: tap
        onTapped: root.activated()
    }

    Behavior on x {
        NumberAnimation {
            duration: root.motion.normal
            easing.type: root.motion.spatialEasing
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: root.motion.normal
            easing.type: root.motion.emphasizedEasing
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: root.motion.fast
            easing.type: root.motion.spatialEasing
        }
    }

    Behavior on color {
        ColorAnimation { duration: root.motion.fast }
    }
}
