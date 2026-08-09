import Quickshell
import Quickshell.Hyprland
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
    required property var media
    required property var notifications
    required property var power
    required property var hyprAnimations
    required property var popupState
    property bool exiting: false
    property bool shown: false
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property bool fullscreen: hyprlandMonitor?.activeWorkspace?.hasFullscreen ?? false
    readonly property bool hiding: exiting || fullscreen || !shown
    readonly property bool popoutOpen: popupState.activeScreen === screen && popupState.activePanel !== ""

    function dismissPopups() {
        popupState.activePanel = "";
        popupState.activeScreen = null;
        trayMenu.dismiss();
    }

    function requestedCenter(anchor) {
        return anchor.mapToItem(panel, anchor.width / 2, 0).x + panel.x;
    }

    function togglePanel(panelName, anchor) {
        trayMenu.dismiss();
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
    implicitHeight: 36
    exclusiveZone: fullscreen ? 0 : 36
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"

    mask: Region {
        x: 0
        y: 0
        width: root.fullscreen ? 0 : root.width
        height: root.fullscreen ? 0 : root.height
    }

    onFullscreenChanged: if (fullscreen) dismissPopups()
    Component.onCompleted: reveal.start()
    Timer { id: reveal; interval: 1; onTriggered: root.shown = true }

    Item {
        id: panel
        x: 8
        y: root.shown && !root.exiting && !root.fullscreen ? 4 : -height - 4
        width: parent.width - 16
        height: 32
        opacity: root.shown && !root.exiting && !root.fullscreen ? 1 : 0

        Rectangle {
            anchors.left: parent.left
            width: leftControls.implicitWidth + 12
            height: parent.height
            radius: 8
            color: root.theme.barBackground

            Row {
                id: leftControls
                anchors.centerIn: parent
                spacing: 5

                ActionButton {
                    theme: root.theme
                    motion: root.motion
                    text: "󰣇"
                    textColor: root.theme.foreground
                    hoverEnabled: !root.popoutOpen
                    onClicked: {
                        root.dismissPopups();
                        Quickshell.execDetached(["omarchy-launch-walker"]);
                    }
                }

                WorkspaceList {
                    anchors.verticalCenter: parent.verticalCenter
                    screen: root.screen
                    theme: root.theme
                    motion: root.motion
                    hoverEnabled: !root.popoutOpen
                    onWorkspaceActivated: root.dismissPopups()
                }
            }

            Behavior on color { ColorAnimation { duration: root.motion.normal } }
        }

        Row {
            anchors.centerIn: parent
            height: parent.height
            spacing: 6

            Rectangle {
                visible: root.media.player !== null
                width: visible ? mediaControls.implicitWidth + 12 : 0
                height: parent.height
                radius: 8
                color: root.theme.barBackground

                MediaControls {
                    id: mediaControls
                    anchors.centerIn: parent
                    theme: root.theme
                    motion: root.motion
                    media: root.media
                    highlighted: root.popupState.activeScreen === root.screen && root.popupState.activePanel === "media"
                    hoverEnabled: !root.popoutOpen
                    onClicked: anchor => root.togglePanel("media", anchor)
                    onHovered: anchor => root.hoverPanel("media", anchor)
                    onTransportClicked: root.dismissPopups()
                }

                Behavior on color { ColorAnimation { duration: root.motion.normal } }
            }

            Rectangle {
                width: clockButton.implicitWidth + 12
                height: parent.height
                radius: 8
                color: root.theme.barBackground

                SystemClock { id: clock; precision: SystemClock.Minutes }

                ActionButton {
                    id: clockButton
                    anchors.centerIn: parent
                    theme: root.theme
                    motion: root.motion
                    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                    highlighted: root.popupState.activeScreen === root.screen && root.popupState.activePanel === "calendar"
                    hoverEnabled: !root.popoutOpen
                    onClicked: root.togglePanel("calendar", clockButton)
                    onHoveredChanged: if (hovered) root.hoverPanel("calendar", clockButton)
                }

                Behavior on color { ColorAnimation { duration: root.motion.normal } }
            }
        }

        Rectangle {
            anchors.right: parent.right
            width: rightControls.implicitWidth + 12
            height: parent.height
            radius: 8
            color: root.theme.barBackground

            Row {
                id: rightControls
                anchors.centerIn: parent
                spacing: 3

                SystemTray {
                    anchors.verticalCenter: parent.verticalCenter
                    theme: root.theme
                    motion: root.motion
                    hoverEnabled: !root.popoutOpen
                    onActivated: root.dismissPopups()
                    onMenuRequested: (menu, anchor) => {
                        root.popupState.activePanel = "";
                        root.popupState.activeScreen = null;
                        trayMenu.showMenu(menu, root.requestedCenter(anchor));
                    }
                }

                NotificationCenter {
                    anchors.verticalCenter: parent.verticalCenter
                    theme: root.theme
                    motion: root.motion
                    notifications: root.notifications
                    active: root.popupState.activeScreen === root.screen && root.popupState.activePanel === "notifications"
                    hoverEnabled: !root.popoutOpen
                    onNotificationClicked: anchor => root.togglePanel("notifications", anchor)
                    onNotificationHovered: anchor => root.hoverPanel("notifications", anchor)
                }

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
                    onPowerClicked: anchor => root.togglePanel("power", anchor)
                    onPowerHovered: anchor => root.hoverPanel("power", anchor)
                }
            }

            Behavior on color { ColorAnimation { duration: root.motion.normal } }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: root.dismissPopups()
        }

        Behavior on y {
            NumberAnimation {
                duration: root.hiding ? root.hyprAnimations.layerOutDuration : root.hyprAnimations.layerInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.hiding ? root.hyprAnimations.layerOutCurve : root.hyprAnimations.layerInCurve
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.hiding ? root.hyprAnimations.layerOutDuration : root.hyprAnimations.layerInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.hiding ? root.hyprAnimations.layerOutCurve : root.hyprAnimations.layerInCurve
            }
        }
    }

    TrayMenuHost {
        id: trayMenu
        screen: root.screen
        theme: root.theme
        motion: root.motion
    }

    PopoutHost {
        screen: root.screen
        theme: root.theme
        motion: root.motion
        audio: root.audio
        bluetooth: root.bluetooth
        network: root.network
        media: root.media
        notifications: root.notifications
        power: root.power
        activePanel: root.popupState.activeScreen === root.screen ? root.popupState.activePanel : ""
        requestedCenter: root.popupState.requestedCenter
        onDismissRequested: {
            root.popupState.activePanel = "";
            root.popupState.activeScreen = null;
        }
    }
}
