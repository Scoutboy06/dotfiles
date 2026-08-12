import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var theme
    required property var motion
    required property var audio
    required property var bluetooth
    required property var network
    required property var media
    required property var notifications
    required property var power
    property string activePanel: ""
    property string displayedPanel: "audio"
    property real requestedCenter: width / 2
    property real animatedCenter: requestedCenter
    property bool rendered: false
    property bool positionAnimationEnabled: false
    signal dismissRequested

    readonly property bool open: activePanel !== ""
    readonly property Item activeItem: panelLoader.item

    visible: rendered
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
        Region { x: 0; y: 0; width: root.rendered ? root.width : 0; height: root.rendered ? root.height : 0 }
        Region { x: 0; y: 0; width: root.width; height: 36; intersection: Intersection.Subtract }
    }

    onActivePanelChanged: {
        if (activePanel !== "")
            displayedPanel = activePanel;
    }

    onOpenChanged: {
        if (open) {
            closeTimer.stop();
            positionAnimationEnabled = false;
            rendered = true;
            positionAnimationTimer.restart();
        } else if (rendered) {
            positionAnimationEnabled = false;
            closeTimer.restart();
        }
    }

    Item {
        anchors.fill: parent
        focus: root.open
        Keys.onEscapePressed: root.dismissRequested()

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissRequested()
        }
    }

    Rectangle {
        id: card
        x: Math.max(8, Math.min(root.width - width - 8, root.animatedCenter - width / 2))
        y: 36
        width: root.activeItem?.implicitWidth ?? 320
        height: root.activeItem?.implicitHeight ?? 120
        radius: 12
        color: root.theme.background
        border.width: 1
        border.color: Qt.alpha(root.theme.foreground, 0.2)
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: Item.TopRight
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Loader {
            id: panelLoader
            anchors.fill: parent
            active: root.rendered
            opacity: root.open ? 1 : 0
            y: root.open ? 0 : -6

            function loadPanel() {
                if (!active) {
                    source = "";
                    return;
                }
                const names = {
                    audio: "AudioPopout.qml",
                    bluetooth: "BluetoothPopout.qml",
                    network: "NetworkPopout.qml",
                    calendar: "CalendarPopout.qml",
                    media: "MediaPopout.qml",
                    notifications: "NotificationPopout.qml",
                    power: "PowerPopout.qml"
                };
                const properties = { theme: root.theme, motion: root.motion };
                if (root.displayedPanel === "audio") properties.audio = root.audio;
                else if (root.displayedPanel === "bluetooth") properties.bluetooth = root.bluetooth;
                else if (root.displayedPanel === "network") properties.network = root.network;
                else if (root.displayedPanel === "media") properties.media = root.media;
                else if (root.displayedPanel === "notifications") properties.notifications = root.notifications;
                else if (root.displayedPanel === "power") properties.power = root.power;
                setSource(Qt.resolvedUrl(names[root.displayedPanel]), properties);
            }

            onActiveChanged: loadPanel()

            Connections {
                target: root
                function onDisplayedPanelChanged() { panelLoader.loadPanel(); }
            }

            Connections {
                target: panelLoader.item
                ignoreUnknownSignals: true
                function onCloseRequested() { root.dismissRequested(); }
            }

            Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            Behavior on y { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.spatialEasing } }
        }

        Behavior on width {
            enabled: root.positionAnimationEnabled
            NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing }
        }
        Behavior on height {
            enabled: root.positionAnimationEnabled
            NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing }
        }
        Behavior on opacity { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
        Behavior on scale { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing } }
    }

    Behavior on animatedCenter {
        enabled: root.positionAnimationEnabled
        NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing }
    }

    Timer {
        id: positionAnimationTimer
        interval: root.motion.normal + 40
        onTriggered: root.positionAnimationEnabled = true
    }

    Timer {
        id: closeTimer
        interval: root.motion.normal
        onTriggered: root.rendered = false
    }
}
