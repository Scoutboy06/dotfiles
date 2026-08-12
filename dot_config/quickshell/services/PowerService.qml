import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property bool suspendAvailable: true
    property bool hibernateAvailable: false
    property bool detailsVisible: false

    function refresh() {
        if (!suspendCheck.running)
            suspendCheck.running = true;
        if (!hibernateCheck.running)
            hibernateCheck.running = true;
    }

    function execute(action) {
        const commands = {
            screensaver: ["omarchy-launch-screensaver", "force"],
            lock: ["omarchy-system-lock"],
            suspend: ["systemctl", "suspend"],
            hibernate: ["systemctl", "hibernate"],
            logout: ["omarchy-system-logout"],
            restart: ["omarchy-system-reboot"],
            shutdown: ["omarchy-system-shutdown"]
        };
        if (commands[action])
            Quickshell.execDetached(commands[action]);
    }

    Component.onCompleted: refresh()
    onDetailsVisibleChanged: if (detailsVisible) refresh()

    property Process suspendProcess: Process {
        id: suspendCheck
        command: ["omarchy-toggle-enabled", "suspend-off"]
        onExited: exitCode => root.suspendAvailable = exitCode !== 0
    }

    property Process hibernateProcess: Process {
        id: hibernateCheck
        command: ["omarchy-hibernation-available"]
        onExited: exitCode => root.hibernateAvailable = exitCode === 0
    }

}
