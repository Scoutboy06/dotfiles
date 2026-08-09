import QtQuick

Rectangle {
    id: root

    required property var workspace
    required property var theme
    required property var motion
    property bool hoverEnabled: true
    signal activated

    readonly property bool active: workspace.active
    readonly property bool hovered: hoverEnabled && hover.hovered

    width: active ? 34 : 22
    height: 22
    radius: height / 2
    scale: tap.pressed ? 0.88 : hovered ? 1.08 : 1
    color: active ? theme.accent : hovered ? Qt.lighter(theme.surface, 1.25) : theme.surface

    Text {
        anchors.centerIn: parent
        text: root.workspace.id
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
        onTapped: {
            root.activated();
            root.workspace.activate();
        }
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
