import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root

    required property var theme
    required property var motion
    required property var audio
    required property var bluetooth
    property string activePanel: ""
    property string displayedPanel: "audio"
    property bool rendered: false
    signal dismissRequested

    readonly property bool open: activePanel !== ""
    readonly property Item activeItem: displayedPanel === "audio" ? audioPanel : bluetoothPanel

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
            rendered = true;
        } else if (rendered) {
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
        anchors { top: parent.top; topMargin: 36; right: parent.right; rightMargin: 8 }
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

            Behavior on opacity { NumberAnimation { duration: root.motion.fast } }
            Behavior on y { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.spatialEasing } }
        }

        Behavior on width { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing } }
        Behavior on height { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing } }
        Behavior on opacity { NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing } }
        Behavior on scale { NumberAnimation { duration: root.motion.normal; easing.type: root.motion.emphasizedEasing } }
    }

    Timer {
        id: closeTimer
        interval: root.motion.normal
        onTriggered: root.rendered = false
    }
}
