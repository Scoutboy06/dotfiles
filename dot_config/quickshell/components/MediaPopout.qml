import QtQuick

Item {
    id: root

    required property var theme
    required property var motion
    required property var media

    readonly property var player: media.player
    property real displayedPosition: 0

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 36

    function syncPosition() {
        displayedPosition = media.positionFor(player);
    }

    onPlayerChanged: syncPosition()
    onEnabledChanged: if (enabled) syncPosition()

    Connections {
        target: root.player
        function onPositionChanged() { root.displayedPosition = root.player?.position ?? 0; }
        function onTrackChanged() { root.displayedPosition = root.player?.position ?? 0; }
    }

    Timer {
        interval: 500
        running: root.enabled && (root.player?.isPlaying ?? false)
        repeat: true
        onTriggered: root.displayedPosition = Math.min(root.player?.length ?? Infinity, root.displayedPosition + 0.5 * (root.player?.rate ?? 1))
    }

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";
        const total = Math.floor(seconds);
        return Math.floor(total / 60) + ":" + String(total % 60).padStart(2, "0");
    }

    Column {
        id: content
        anchors { fill: parent; margins: 18 }
        spacing: 14

        Text {
            width: parent.width
            text: root.player?.identity ?? "Media"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 15
            elide: Text.ElideRight
        }

        Row {
            width: parent.width
            spacing: 14

            Rectangle {
                width: 92
                height: 92
                radius: 10
                color: root.theme.surface
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.children[0].status !== Image.Ready
                    text: "󰝚"
                    color: root.theme.accent
                    font.family: root.theme.fontFamily
                    font.pixelSize: 30
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 106
                spacing: 5

                Text {
                    width: parent.width
                    text: root.player?.trackTitle || "Unknown track"
                    color: root.theme.foreground
                    font.family: root.theme.fontFamily
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: root.player?.trackArtist || "Unknown artist"
                    color: root.theme.foreground
                    opacity: 0.75
                    font.family: root.theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: root.player?.trackAlbum || ""
                    color: root.theme.foreground
                    opacity: 0.55
                    font.family: root.theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        Row {
            readonly property bool seekAvailable: root.player?.positionSupported && root.player?.lengthSupported && root.player.length > 0
            width: parent.width
            spacing: 8
            opacity: seekAvailable ? 1 : 0.45

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                text: root.formatTime(root.displayedPosition)
                color: root.theme.foreground
                opacity: 0.7
                font.family: root.theme.fontFamily
                font.pixelSize: 10
            }

            AudioSlider {
                id: progress
                width: parent.width - 92
                theme: root.theme
                motion: root.motion
                from: 0
                to: Math.max(1, root.player?.length ?? 1)
                value: root.displayedPosition
                enabled: parent.seekAvailable && (root.player?.canSeek ?? false)
                onMoved: {
                    root.displayedPosition = value;
                    root.player.position = value;
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                text: root.formatTime(root.player?.length ?? 0)
                color: root.theme.foreground
                opacity: 0.7
                font.family: root.theme.fontFamily
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            width: parent.width
            height: transport.implicitHeight

            Row {
                id: transport
                anchors.centerIn: parent
                spacing: 18

                ActionButton {
                    theme: root.theme
                    motion: root.motion
                    text: "󰒮"
                    enabled: root.player?.canGoPrevious ?? false
                    onClicked: root.player.previous()
                }

                ActionButton {
                    theme: root.theme
                    motion: root.motion
                    text: root.player?.isPlaying ? "󰏤" : "󰐊"
                    textColor: root.theme.accent
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                ActionButton {
                    theme: root.theme
                    motion: root.motion
                    text: "󰒭"
                    enabled: root.player?.canGoNext ?? false
                    onClicked: root.player.next()
                }
            }
        }

        Text {
            visible: root.media.players.length > 1
            text: "Player"
            color: root.theme.foreground
            font.family: root.theme.fontFamily
            font.bold: true
            font.pixelSize: 13
        }

        Column {
            visible: root.media.players.length > 1
            width: parent.width
            spacing: 6

            Repeater {
                model: root.media.players
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 34
                    radius: 8
                    color: modelData === root.player ? root.theme.accent : hover.hovered ? Qt.lighter(root.theme.surface, 1.2) : root.theme.surface

                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: parent.width - 20
                        text: (modelData === root.player ? "●  " : "○  ") + modelData.identity
                        color: modelData === root.player ? root.theme.background : root.theme.foreground
                        font.family: root.theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    HoverHandler { id: hover }
                    TapHandler { onTapped: root.media.selectPlayer(modelData) }
                    Behavior on color { ColorAnimation { duration: root.motion.fast } }
                }
            }
        }
    }
}
