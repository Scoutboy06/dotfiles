import QtQuick

Row {
    id: root
    required property var theme
    required property var motion
    required property var audio
    required property var bluetooth
    required property var network
    required property string activePanel
    signal audioClicked(var anchor)
    signal audioHovered(var anchor)
    signal bluetoothClicked(var anchor)
    signal bluetoothHovered(var anchor)
    signal networkClicked(var anchor)
    signal networkHovered(var anchor)
    signal powerClicked(var anchor)
    signal powerHovered(var anchor)

    spacing: 2

    ActionButton {
        id: networkButton
        theme: root.theme; motion: root.motion
        text: root.network.wired.length > 0 ? "󰈀" : root.network.connectedSsid !== "" ? "󰤨" : "󰤭"
        textColor: root.network.connectedSsid !== "" ? root.theme.success : root.theme.foreground
        highlighted: root.activePanel === "network"
        onClicked: root.networkClicked(networkButton)
        onHoveredChanged: if (hovered) root.networkHovered(networkButton)
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
        id: powerButton
        theme: root.theme; motion: root.motion; text: "󰐥"; textColor: root.theme.foreground
        highlighted: root.activePanel === "power"
        hoverEnabled: root.activePanel === ""
        onClicked: root.powerClicked(powerButton)
        onHoveredChanged: if (hovered) root.powerHovered(powerButton)
    }
}
