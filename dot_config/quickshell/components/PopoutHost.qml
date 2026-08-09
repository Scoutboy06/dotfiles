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
    property string activePanel: ""
    property string displayedPanel: "audio"
    property real requestedCenter: width / 2
    property bool rendered: false
    property bool positionAnimationEnabled: false
    signal dismissRequested

    readonly property bool open: activePanel !== ""
    readonly property Item activeItem: displayedPanel === "audio" ? audioPanel : displayedPanel === "bluetooth" ? bluetoothPanel : displayedPanel === "network" ? networkPanel : calendarPanel

    visible: rendered
    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    mask: Region {
        Region { x: 0; y: 0; width: root.width; height: root.height }
        Region { x: 0; y: 0; width: root.width; height: 40; intersection: Intersection.Subtract }
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
        x: Math.max(8, Math.min(root.width - width - 8, root.requestedCenter - width / 2))
        y: 36
        width: root.activeItem.implicitWidth
        height: root.activeItem.implicitHeight
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

        AudioPopout {
            id: audioPanel
            anchors.fill: parent
            audio: root.audio
            theme: root.theme
            motion: root.motion
            opacity: root.open && root.displayedPanel === "audio" ? 1 : 0
            y: root.open && root.displayedPanel === "audio" ? 0 : -6
            enabled: root.open && root.displayedPanel === "audio"
            onCloseRequested: root.dismissRequested()

            Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            Behavior on y { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.spatialEasing } }
        }

        BluetoothPopout {
            id: bluetoothPanel
            anchors.fill: parent
            bluetooth: root.bluetooth
            theme: root.theme
            motion: root.motion
            opacity: root.open && root.displayedPanel === "bluetooth" ? 1 : 0
            y: root.open && root.displayedPanel === "bluetooth" ? 0 : -6
            enabled: root.open && root.displayedPanel === "bluetooth"
            onCloseRequested: root.dismissRequested()

            Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            Behavior on y { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.spatialEasing } }
        }

        NetworkPopout {
            id: networkPanel
            anchors.fill: parent
            network: root.network
            theme: root.theme
            motion: root.motion
            opacity: root.open && root.displayedPanel === "network" ? 1 : 0
            y: root.open && root.displayedPanel === "network" ? 0 : -6
            enabled: root.open && root.displayedPanel === "network"
            onCloseRequested: root.dismissRequested()

            Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            Behavior on y { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.spatialEasing } }
        }

        CalendarPopout {
            id: calendarPanel
            anchors.fill: parent
            theme: root.theme
            motion: root.motion
            opacity: root.open && root.displayedPanel === "calendar" ? 1 : 0
            y: root.open && root.displayedPanel === "calendar" ? 0 : -6
            enabled: root.open && root.displayedPanel === "calendar"

            Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            Behavior on y { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.spatialEasing } }
        }

        Behavior on x {
            enabled: root.positionAnimationEnabled
            NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing }
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
