import Quickshell
import QtQuick

Rectangle {
    id: root

    required property var theme
    required property var motion
    property bool highlighted: false
    property bool hoverEnabled: true
    signal clicked(var anchor)
    signal hovered(var anchor)

    implicitWidth: label.implicitWidth + 12
    implicitHeight: 24
    radius: height / 2
    color: highlighted || (hoverEnabled && hover.hovered) ? Qt.lighter(theme.surface, 1.25) : "transparent"
    scale: tap.pressed ? 0.96 : 1

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Text {
        id: label
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
        color: root.theme.foreground
        font.family: root.theme.fontFamily
        font.pixelSize: 13
        font.bold: true
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (hovered) root.hovered(root)
    }
    TapHandler { id: tap; onTapped: root.clicked(root) }

    Behavior on color { ColorAnimation { duration: root.motion.fast } }
    Behavior on scale { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
}
