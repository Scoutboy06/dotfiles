import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Row {
    id: root
    required property var theme
    required property var motion
    property bool hoverEnabled: true
    spacing: 3

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            required property var modelData
            width: 24
            height: 24
            radius: 12
            color: root.hoverEnabled && hover.hovered ? Qt.lighter(root.theme.surface, 1.25) : "transparent"

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: modelData.icon
            }

            HoverHandler { id: hover }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: eventPoint => {
                    if (eventPoint.event.button === Qt.RightButton)
                        modelData.secondaryActivate();
                    else
                        modelData.activate();
                }
            }

            Behavior on color { ColorAnimation { duration: root.motion.fast } }
        }
    }
}
