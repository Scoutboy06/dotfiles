import Quickshell
import Quickshell.Io
import QtQuick

Row {
    id: root
    required property var theme
    required property var motion
    required property var audio
    required property var bluetooth
    required property string activePanel
    signal audioClicked(var anchor)
    signal audioHovered(var anchor)
    signal bluetoothClicked(var anchor)
    signal bluetoothHovered(var anchor)

    property bool wifiConnected: false
    property bool ethernetConnected: false
    spacing: 2

    function run(command) { Quickshell.execDetached(["sh", "-lc", command]); }
    function refresh() { state.running = true; }

    Process {
        id: state
        command: ["sh", "-lc", "iface=$(ip route show default 2>/dev/null | awk 'NR == 1 {print $5}'); printf '%s|%s' \"$([ -n \"$iface\" ] && echo connected || echo disconnected)\" \"$([ -n \"$iface\" ] && [ ! -d \"/sys/class/net/$iface/wireless\" ] && echo yes || echo no)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                root.wifiConnected = parts[0] === "connected";
                root.ethernetConnected = parts[1] === "yes";
            }
        }
    }

    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    ActionButton {
        theme: root.theme; motion: root.motion
        text: root.ethernetConnected ? "󰈀" : root.wifiConnected ? "󰤨" : "󰤭"
        textColor: root.wifiConnected ? root.theme.success : root.theme.foreground
        hoverEnabled: root.activePanel === ""
        onClicked: root.run("omarchy launch wifi")
    }
    ActionButton {
        id: bluetoothButton
        theme: root.theme; motion: root.motion
        text: root.bluetooth.enabled ? "󰂯" : "󰂲"
        textColor: root.bluetooth.enabled ? root.theme.accent : root.theme.foreground
        highlighted: root.activePanel === "bluetooth"
        onClicked: root.bluetoothClicked(bluetoothButton)
        onHoveredChanged: if (hovered) root.bluetoothHovered(bluetoothButton)
    }
    ActionButton {
        id: audioButton
        theme: root.theme; motion: root.motion
        text: root.audio.muted ? "󰖁" : root.audio.volume > 0.6 ? "󰕾" : root.audio.volume > 0 ? "󰖀" : "󰕿"
        highlighted: root.activePanel === "audio"
        onClicked: root.audioClicked(audioButton)
        onHoveredChanged: if (hovered) root.audioHovered(audioButton)

        WheelHandler {
            onWheel: event => root.audio.setVolume(root.audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }
    ActionButton {
        theme: root.theme; motion: root.motion; text: "󰐥"; textColor: root.theme.urgent
        hoverEnabled: root.activePanel === ""
        onClicked: root.run("omarchy-menu system")
    }
}
