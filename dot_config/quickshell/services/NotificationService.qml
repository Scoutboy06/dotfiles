import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var notifications: []

    function refresh() {
        if (!history.running)
            history.running = true;
    }

    function dismiss(id) {
        Quickshell.execDetached(["makoctl", "dismiss", "-n", String(id), "--no-history"]);
        refreshDelay.restart();
    }

    function dismissAll() {
        Quickshell.execDetached(["makoctl", "dismiss", "--all", "--no-history"]);
        refreshDelay.restart();
    }

    property Process historyProcess: Process {
        id: history
        command: ["makoctl", "list", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.notifications = JSON.parse(text);
                } catch (error) {
                    root.notifications = [];
                }
            }
        }
    }

    property Timer pollingTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    property Timer dismissalRefreshTimer: Timer {
        id: refreshDelay
        interval: 150
        onTriggered: root.refresh()
    }
}
