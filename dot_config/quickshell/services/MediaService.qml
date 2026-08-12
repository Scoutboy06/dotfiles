import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

QtObject {
    id: root

    property var players: []
    property var player: null
    property bool manuallySelected: false
    property var playerPositions: ({})
    property var pendingPlayer: null
    property bool detailsVisible: false

    function hasPlayableMedia(candidate) {
        return candidate.isPlaying
            || (candidate.trackTitle ?? "").trim() !== ""
            || (candidate.trackArtUrl ?? "") !== ""
            || (candidate.lengthSupported && candidate.length > 0);
    }

    function availablePlayers() {
        return Mpris.players.values.filter(candidate =>
            !candidate.dbusName.toLowerCase().includes("playerctld") && hasPlayableMedia(candidate));
    }

    function isBrowser(candidate) {
        const identity = ((candidate?.identity ?? "") + " " + (candidate?.desktopEntry ?? "") + " " + (candidate?.dbusName ?? "")).toLowerCase();
        return ["brave", "chromium", "chrome", "firefox"].some(name => identity.includes(name));
    }

    function chooseFallback() {
        const available = availablePlayers();
        if (player && available.includes(player))
            return;
        manuallySelected = false;
        player = available.find(candidate => candidate.isPlaying && !isBrowser(candidate))
            ?? available.find(candidate => candidate.isPlaying)
            ?? available.find(candidate => !isBrowser(candidate))
            ?? available[0]
            ?? null;
    }

    function preferPlayingPlayer() {
        if (manuallySelected || player?.isPlaying)
            return;
        const available = availablePlayers();
        const playing = available.find(candidate => candidate.isPlaying && !isBrowser(candidate))
            ?? available.find(candidate => candidate.isPlaying);
        if (playing)
            player = playing;
    }

    function positionFor(candidate) {
        if (!candidate)
            return 0;
        return playerPositions[candidate.uniqueId] ?? candidate.position ?? 0;
    }

    function updatePositions() {
        const available = availablePlayers();
        const next = Object.assign({}, playerPositions);
        for (const candidate of available)
            next[candidate.uniqueId] = candidate.position ?? 0;
        playerPositions = next;
        players = available;
        chooseFallback();
    }

    function completeSelection(position) {
        if (!pendingPlayer)
            return;
        if (position !== undefined) {
            const next = Object.assign({}, playerPositions);
            next[pendingPlayer.uniqueId] = position;
            playerPositions = next;
        }
        player = pendingPlayer;
        manuallySelected = true;
        pendingPlayer = null;
    }

    function selectPlayer(nextPlayer) {
        if (!nextPlayer)
            return;
        if (nextPlayer === player) {
            manuallySelected = true;
            return;
        }
        pendingPlayer = nextPlayer;
        positionQuery.command = ["busctl", "--user", "get-property", nextPlayer.dbusName, "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Position"];
        positionQuery.running = true;
    }

    Component.onCompleted: {
        players = availablePlayers();
        chooseFallback();
    }

    property Process positionProcess: Process {
        id: positionQuery
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/);
                const microseconds = Number(parts[parts.length - 1]);
                if (isFinite(microseconds))
                    root.completeSelection(microseconds / 1000000);
            }
        }
        onExited: if (root.pendingPlayer) root.completeSelection(undefined)
    }

    property Timer playingPlayerTimer: Timer {
        // The popout has its own smooth local position timer. In the background
        // this only needs to notice player/playing-state changes promptly.
        interval: root.detailsVisible ? 500 : 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.updatePositions();
            root.preferPlayingPlayer();
        }
    }

    property Connections playerConnections: Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.players = root.availablePlayers();
            root.chooseFallback();
        }
    }
}
