import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "components"

PanelWindow {
    id: root

    required property var theme
    required property var motion
    required property var audio
    required property var bluetooth
    required property var network
    required property var popupState
    property bool exiting: false
    property bool shown: false
    readonly property bool popoutOpen: popupState.activeScreen === screen && popupState.activePanel !== ""

    function requestedCenter(anchor) {
        return anchor.mapToItem(panel, anchor.width / 2, 0).x + panel.x;
    }

    function togglePanel(panelName, anchor) {
        if (popupState.activeScreen === screen && popupState.activePanel === panelName) {
            popupState.activePanel = "";
            popupState.activeScreen = null;
        } else {
            popupState.requestedCenter = requestedCenter(anchor);
            popupState.activeScreen = screen;
            popupState.activePanel = panelName;
        }
    }

    function hoverPanel(panelName, anchor) {
        if (popupState.activeScreen === screen && popupState.activePanel !== "") {
            popupState.requestedCenter = requestedCenter(anchor);
            popupState.activePanel = panelName;
        }
    }

    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    exclusiveZone: 40
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    Component.onCompleted: reveal.start()
    Timer { id: reveal; interval: 1; onTriggered: root.shown = true }

    Rectangle {
        id: panel
        x: 8
        y: root.shown && !root.exiting ? 4 : -height - 4
        width: parent.width - 16
        height: 32
        radius: 10
        opacity: root.shown && !root.exiting ? 1 : 0
        color: root.theme.background

        Row {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 5

            ActionButton {
                theme: root.theme
                motion: root.motion
                text: "󰣇"
                textColor: root.theme.foreground
                hoverEnabled: !root.popoutOpen
                onClicked: Quickshell.execDetached(["omarchy-launch-walker"])
            }

            WorkspaceList {
                anchors.verticalCenter: parent.verticalCenter
                screen: root.screen
                theme: root.theme
                motion: root.motion
                hoverEnabled: !root.popoutOpen
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 10

            MediaControls {
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
                hoverEnabled: !root.popoutOpen
            }

            SystemClock { id: clock; precision: SystemClock.Minutes }

            ActionButton {
                id: clockButton
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
                text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                highlighted: root.popupState.activeScreen === root.screen && root.popupState.activePanel === "calendar"
                hoverEnabled: !root.popoutOpen
                onClicked: root.togglePanel("calendar", clockButton)
                onHoveredChanged: if (hovered) root.hoverPanel("calendar", clockButton)
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 3

            SystemTray { anchors.verticalCenter: parent.verticalCenter; theme: root.theme; motion: root.motion; hoverEnabled: !root.popoutOpen }
            NotificationCenter { anchors.verticalCenter: parent.verticalCenter; screen: root.screen; theme: root.theme; motion: root.motion; hoverEnabled: !root.popoutOpen }
            BatteryStatus { anchors.verticalCenter: parent.verticalCenter; theme: root.theme; motion: root.motion }
            StatusControls {
                anchors.verticalCenter: parent.verticalCenter
                theme: root.theme
                motion: root.motion
                audio: root.audio
                bluetooth: root.bluetooth
                network: root.network
                activePanel: root.popupState.activeScreen === root.screen ? root.popupState.activePanel : ""
                onAudioClicked: anchor => root.togglePanel("audio", anchor)
                onAudioHovered: anchor => root.hoverPanel("audio", anchor)
                onBluetoothClicked: anchor => root.togglePanel("bluetooth", anchor)
                onBluetoothHovered: anchor => root.hoverPanel("bluetooth", anchor)
                onNetworkClicked: anchor => root.togglePanel("network", anchor)
                onNetworkHovered: anchor => root.hoverPanel("network", anchor)
            }
        }

        Behavior on y {
            NumberAnimation { duration: root.motion.normal; easing.type: root.exiting ? Easing.InCubic : root.motion.emphasizedEasing }
        }
        Behavior on opacity {
            NumberAnimation { duration: root.motion.fast; easing.type: root.motion.spatialEasing }
        }
        Behavior on color { ColorAnimation { duration: root.motion.normal } }
    }

    PopoutHost {
        screen: root.screen
        theme: root.theme
        motion: root.motion
        audio: root.audio
        bluetooth: root.bluetooth
        network: root.network
        activePanel: root.popupState.activeScreen === root.screen ? root.popupState.activePanel : ""
        requestedCenter: root.popupState.requestedCenter
        onDismissRequested: {
            root.popupState.activePanel = "";
            root.popupState.activeScreen = null;
        }
    }
}
