import Quickshell
import Quickshell.Io
import QtQuick

Row {
    id: root
    required property var theme
    required property var motion

    property bool wifiConnected: false
    property bool ethernetConnected: false
    property bool bluetoothOn: false
    property bool muted: false
    property int volume: 0
    spacing: 2

    function run(command) { Quickshell.execDetached(["sh", "-lc", command]); }
    function refresh() { state.running = true; }

    Process {
        id: state
        command: ["sh", "-lc", "iface=$(ip route show default 2>/dev/null | awk 'NR == 1 {print $5}'); printf '%s|%s|%s|%s' \"$([ -n \"$iface\" ] && echo connected || echo disconnected)\" \"$([ -n \"$iface\" ] && [ ! -d \"/sys/class/net/$iface/wireless\" ] && echo yes || echo no)\" \"$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2}')\" \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                root.wifiConnected = parts[0] === "connected";
                root.ethernetConnected = parts[1] === "yes";
                root.bluetoothOn = parts[2] === "yes";
                root.muted = (parts[3] ?? "").includes("MUTED");
                const match = (parts[3] ?? "").match(/[0-9.]+/);
                root.volume = match ? Math.round(Number(match[0]) * 100) : 0;
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
        text: root.muted ? "󰖁" : root.volume > 60 ? "󰕾" : root.volume > 0 ? "󰖀" : "󰕿"
        onClicked: root.run("omarchy launch audio")

        WheelHandler {
            onWheel: event => {
                root.run(event.angleDelta.y > 0 ? "wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+" : "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-");
                root.refresh();
            }
        }
    }
    ActionButton {
        theme: root.theme; motion: root.motion; text: "󰐥"; textColor: root.theme.urgent
        onClicked: root.run("omarchy-menu system")
    }
}
