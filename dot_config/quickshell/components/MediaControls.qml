import QtQuick

Item {
    id: root

    required property var theme
    required property var motion
    required property var media
    property bool hoverEnabled: true
    property bool highlighted: false
    signal clicked(var anchor)
    signal hovered(var anchor)

    readonly property var player: media.player

    visible: player !== null
    implicitWidth: visible ? controls.implicitWidth : 0
    implicitHeight: 24

    Row {
        id: controls
        anchors.centerIn: parent
        spacing: 2

        ActionButton {
            theme: root.theme
            motion: root.motion
            text: "󰒮"
            hoverEnabled: root.hoverEnabled
            visible: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }

        Rectangle {
            id: mediaTrigger
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(title.implicitWidth + 12, 192)
            height: 24
            radius: height / 2
            color: root.highlighted || (root.hoverEnabled && titleHover.hovered) ? Qt.lighter(root.theme.surface, 1.25) : "transparent"

            Text {
                id: title
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 180)
                elide: Text.ElideRight
                text: root.player?.trackTitle || root.player?.identity || ""
                color: root.theme.foreground
                font.family: root.theme.fontFamily
                font.pixelSize: 12
            }

            HoverHandler { id: titleHover }
            TapHandler { onTapped: root.clicked(root) }
            Behavior on color { ColorAnimation { duration: root.motion.fast } }
        }

        ActionButton {
            theme: root.theme
            motion: root.motion
            text: root.player?.isPlaying ? "󰏤" : "󰐊"
            hoverEnabled: root.hoverEnabled
            enabled: root.player?.canTogglePlaying ?? false
            onClicked: root.player.togglePlaying()
        }

        ActionButton {
            theme: root.theme
            motion: root.motion
            text: "󰒭"
            hoverEnabled: root.hoverEnabled
            visible: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
    }

    HoverHandler {
        onHoveredChanged: if (hovered) root.hovered(root)
    }
}
