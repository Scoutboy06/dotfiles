import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "services"
import "theme"

ShellRoot {
    id: root

    property bool exiting: false
    readonly property alias shellTheme: theme
    readonly property alias shellMotion: motion
    readonly property alias audioService: audio
    readonly property alias bluetoothService: bluetooth
    readonly property alias networkService: network
    readonly property alias mediaService: media
    readonly property alias notificationService: notifications
    readonly property alias powerService: power
    readonly property alias hyprAnimationService: hyprAnimations
    readonly property alias sharedPopupState: popupState

    Theme { id: theme }
    Motion { id: motion }
    Audio { id: audio }
    BluetoothService { id: bluetooth }
    NetworkService {
        id: network
        detailsVisible: popupState.activePanel === "network"
    }
    MediaService {
        id: media
        detailsVisible: popupState.activePanel === "media"
    }
    NotificationService { id: notifications }
    PowerService {
        id: power
        detailsVisible: popupState.activePanel === "power"
    }
    HyprAnimationService { id: hyprAnimations }

    QtObject {
        id: popupState
        property var activeScreen: null
        property string activePanel: ""
        property real requestedCenter: 0
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
                theme: root.shellTheme
                motion: root.shellMotion
                audio: root.audioService
                bluetooth: root.bluetoothService
                network: root.networkService
                media: root.mediaService
                notifications: root.notificationService
                power: root.powerService
                hyprAnimations: root.hyprAnimationService
                popupState: root.sharedPopupState
                exiting: root.exiting
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activespecial") {
                Hyprland.refreshMonitors();
                Hyprland.refreshWorkspaces();
            }
        }
    }

    IpcHandler {
        target: "shell"

        function reloadTheme(): void {
            root.shellTheme.reloadTheme();
        }

        function quit(): void {
            if (root.exiting)
                return;
            root.exiting = true;
            quitTimer.start();
        }
    }

    Timer {
        id: quitTimer
        interval: motion.normal + 40
        onTriggered: Qt.quit()
    }
}
