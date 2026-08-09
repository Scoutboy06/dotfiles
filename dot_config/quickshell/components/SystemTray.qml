import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick

Row {
    id: root

    required property var theme
    required property var motion
    property bool hoverEnabled: true
    readonly property bool hasItems: SystemTray.items.values.length > 0
    signal activated
    signal menuRequested(var menu, var anchor)

    spacing: 3

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: trayItem
            required property var modelData
            width: 24
            height: 24
            radius: 12
            color: root.hoverEnabled && hover.hovered ? Qt.lighter(root.theme.surface, 1.25) : "transparent"

            IconImage {
                anchors.centerIn: parent
                implicitSize: 14
                source: trayItem.modelData.icon
            }

            HoverHandler { id: hover }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onSingleTapped: root.activated()
                onDoubleTapped: {
                    root.activated();
                    trayItem.modelData.activate();
                    const pattern = trayItem.modelData.title || trayItem.modelData.id;
                    if (pattern)
                        Quickshell.execDetached(["sh", "-c", "sleep 0.15; exec omarchy-launch-or-focus \"$1\" true", "tray-focus", pattern]);
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    if (trayItem.modelData.menu)
                        root.menuRequested(trayItem.modelData.menu, trayItem);
                    else {
                        root.activated();
                        trayItem.modelData.secondaryActivate();
                    }
                }
            }

            Behavior on color { ColorAnimation { duration: root.motion.fast } }
        }
    }
}
