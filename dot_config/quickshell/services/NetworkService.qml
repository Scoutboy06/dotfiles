import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property var wired: []
    property var networks: []
    property string defaultInterface: ""
    property bool wifiAvailable: false
    property bool wifiEnabled: false
    property string wifiInterface: ""
    property string wifiAdapter: ""
    property string wifiAddress: ""
    property string connectedSsid: ""
    property string changingNetwork: ""

    function refresh() {
        if (!state.running)
            state.running = true;
    }

    function runControl(command, networkName) {
        if (control.running)
            return;
        changingNetwork = networkName ?? "";
        control.command = command;
        control.running = true;
    }

    function toggleWifi() {
        if (wifiAdapter)
            runControl(["iwctl", "adapter", wifiAdapter, "set-property", "Powered", wifiEnabled ? "off" : "on"], "");
    }

    function toggleNetwork(network) {
        if (!wifiInterface)
            return;
        if (network.connected)
            runControl(["iwctl", "station", wifiInterface, "disconnect"], network.name);
        else
            runControl(["iwctl", "station", wifiInterface, "connect", network.name], network.name);
    }

    property Process stateProcess: Process {
        id: state
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/scripts/network-state.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.wired = data.wired ?? [];
                    root.networks = data.networks ?? [];
                    root.defaultInterface = data.defaultInterface ?? "";
                    root.wifiAvailable = data.wifiAvailable ?? false;
                    root.wifiEnabled = data.wifiEnabled ?? false;
                    root.wifiInterface = data.wifiInterface ?? "";
                    root.wifiAdapter = data.wifiAdapter ?? "";
                    root.wifiAddress = data.wifiAddress ?? "";
                    root.connectedSsid = data.connectedSsid ?? "";
                } catch (error) {
                    console.warn("Unable to parse network state:", error);
                }
            }
        }
    }

    property Process controlProcess: Process {
        id: control
        onExited: {
            root.changingNetwork = "";
            refreshDelay.restart();
        }
    }

    property Timer refreshTimer: Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    property Timer delayedRefresh: Timer {
        id: refreshDelay
        interval: 600
        onTriggered: root.refresh()
    }
}
