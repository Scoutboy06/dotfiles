import Quickshell
import Quickshell.Io
import QtQuick

Row {
    id: root
    required property var theme
    required property var motion
    required property var audio
    signal audioClicked

    property bool wifiConnected: false
    property bool ethernetConnected: false
    property bool bluetoothOn: false
    spacing: 2

    function run(command) { Quickshell.execDetached(["sh", "-lc", command]); }
    function refresh() { state.running = true; }

    Process {
        id: state
        command: ["sh", "-lc", "iface=$(ip route show default 2>/dev/null | awk 'NR == 1 {print $5}'); printf '%s|%s|%s' \"$([ -n \"$iface\" ] && echo connected || echo disconnected)\" \"$([ -n \"$iface\" ] && [ ! -d \"/sys/class/net/$iface/wireless\" ] && echo yes || echo no)\" \"$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                root.wifiConnected = parts[0] === "connected";
                root.ethernetConnected = parts[1] === "yes";
                root.bluetoothOn = parts[2] === "yes";
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    ActionButton {
        theme: root.theme; motion: root.motion
        text: root.ethernetConnected ? "󰈀" : root.wifiConnected ? "󰤨" : "󰤭"
        textColor: root.wifiConnected ? root.theme.success : root.theme.foreground
        onClicked: root.run("omarchy launch wifi")
    }
    ActionButton {
        theme: root.theme; motion: root.motion
        text: root.bluetoothOn ? "󰂯" : "󰂲"
        textColor: root.bluetoothOn ? root.theme.accent : root.theme.foreground
        onClicked: root.run("omarchy launch bluetooth")
    }
    ActionButton {
        theme: root.theme; motion: root.motion
        text: root.audio.muted ? "󰖁" : root.audio.volume > 0.6 ? "󰕾" : root.audio.volume > 0 ? "󰖀" : "󰕿"
        onClicked: root.audioClicked()

        WheelHandler {
            onWheel: event => root.audio.setVolume(root.audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }
    ActionButton {
        theme: root.theme; motion: root.motion; text: "󰐥"; textColor: root.theme.urgent
        onClicked: root.run("omarchy-menu system")
    }
}
