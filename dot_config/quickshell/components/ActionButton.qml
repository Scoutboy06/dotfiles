import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var motion
    property alias text: label.text
    property color textColor: theme.foreground
    property string command: ""
    property string tooltip: ""
    property bool highlighted: false
    property bool hoverEnabled: true
    readonly property alias hovered: hover.hovered
    signal clicked

    implicitWidth: Math.max(26, label.implicitWidth + 12)
    implicitHeight: 24
    radius: height / 2
    color: highlighted || (hoverEnabled && hover.hovered) ? Qt.lighter(theme.surface, 1.25) : "transparent"
    scale: tap.pressed ? 0.9 : 1

    Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        font.pixelSize: 13
        font.family: root.theme.fontFamily
    }

    HoverHandler { id: hover }
    TapHandler { id: tap; onTapped: root.clicked() }

    Behavior on color { ColorAnimation { duration: root.motion.fast } }
    Behavior on scale { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
}
