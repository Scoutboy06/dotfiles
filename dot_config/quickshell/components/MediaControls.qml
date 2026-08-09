import Quickshell.Services.Mpris
import QtQuick

Row {
    id: root
    required property var theme
    required property var motion
    property bool hoverEnabled: true

    readonly property var player: Mpris.players.values.find(player => player.isPlaying) ?? Mpris.players.values[0] ?? null
    visible: player !== null
    spacing: 2

    ActionButton {
        theme: root.theme; motion: root.motion; text: "󰒮"; hoverEnabled: root.hoverEnabled
        visible: root.player?.canGoPrevious ?? false
        onClicked: root.player.previous()
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, 180)
        elide: Text.ElideRight
        text: root.player?.trackTitle || root.player?.identity || ""
        color: root.theme.foreground
        font.family: root.theme.fontFamily
        font.pixelSize: 12
    }

    ActionButton {
        theme: root.theme; motion: root.motion
        text: root.player?.isPlaying ? "󰏤" : "󰐊"
        hoverEnabled: root.hoverEnabled
        onClicked: root.player.togglePlaying()
    }

    ActionButton {
        theme: root.theme; motion: root.motion; text: "󰒭"; hoverEnabled: root.hoverEnabled
        visible: root.player?.canGoNext ?? false
        onClicked: root.player.next()
    }
}
