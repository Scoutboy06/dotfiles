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
    readonly property alias sharedPopupState: popupState

    Theme { id: theme }
    Motion { id: motion }
    Audio { id: audio }

    QtObject {
        id: popupState
        property var audioScreen: null
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
