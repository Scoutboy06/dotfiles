import Quickshell.Services.Pipewire
import QtQuick

QtObject {
    id: root

    property var sinks: []
    property var sources: []
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real sourceVolume: source?.audio?.volume ?? 0
    readonly property bool sourceMuted: source?.audio?.muted ?? false

    function refreshNodes() {
        const nextSinks = [];
        const nextSources = [];
        for (const node of Pipewire.nodes.values) {
            if (node.isStream || !node.audio)
                continue;
            if (node.isSink)
                nextSinks.push(node);
            else
                nextSources.push(node);
        }
        sinks = nextSinks;
        sources = nextSources;
    }

    function setVolume(value) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1.1, value));
    }

    function setSourceVolume(value) {
        if (source?.audio)
            source.audio.volume = Math.max(0, Math.min(1.1, value));
    }

    function selectSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    Component.onCompleted: refreshNodes()

    property Connections nodeConnections: Connections {
        target: Pipewire.nodes
        function onValuesChanged() { root.refreshNodes(); }
    }

    property PwObjectTracker tracker: PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources].filter(node => node)
    }
}
