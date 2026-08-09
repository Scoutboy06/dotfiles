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

    Theme { id: theme }
    Motion { id: motion }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
                theme: root.shellTheme
                motion: root.shellMotion
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
