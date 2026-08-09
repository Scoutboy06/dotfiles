import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var motion
    property alias text: label.text
    property color textColor: theme.foreground
    property string command: ""
    property string tooltip: ""
    signal clicked

    implicitWidth: Math.max(26, label.implicitWidth + 12)
    implicitHeight: 24
    radius: height / 2
    color: hover.hovered ? Qt.lighter(theme.surface, 1.25) : "transparent"
    scale: tap.pressed ? 0.9 : 1

    Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        font.pixelSize: 13
        font.family: "FiraCode Nerd Font"
    }

    HoverHandler { id: hover }
    TapHandler { id: tap; onTapped: root.clicked() }

    Behavior on color { ColorAnimation { duration: root.motion.fast } }
    Behavior on scale { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
}
