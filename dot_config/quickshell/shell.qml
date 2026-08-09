import Quickshell
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
    readonly property alias sharedPopupState: popupState

    Theme { id: theme }
    Motion { id: motion }
    Audio { id: audio }
    BluetoothService { id: bluetooth }
    NetworkService { id: network }
    MediaService { id: media }

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
                popupState: root.sharedPopupState
                exiting: root.exiting
            }
        }
    }

    IpcHandler {
        target: "shell"

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
