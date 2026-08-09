import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property int layerInDuration: 400
    property int layerOutDuration: 150
    property var layerInCurve: [0.23, 1, 0.32, 1, 1, 1]
    property var layerOutCurve: [0, 0, 1, 1, 1, 1]

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    function curveFor(name, curves, fallback) {
        const curve = curves.find(candidate => candidate.name === name);
        return curve ? [curve.X0, curve.Y0, curve.X1, curve.Y1, 1, 1] : fallback;
    }

    function applyConfiguration(text) {
        try {
            const document = JSON.parse(text);
            const animations = document[0] ?? [];
            const curves = document[1] ?? [];
            const layerIn = animations.find(animation => animation.name === "layersIn");
            const layerOut = animations.find(animation => animation.name === "layersOut");

            if (layerIn) {
                layerInDuration = layerIn.enabled ? Math.round(layerIn.speed * 100) : 0;
                layerInCurve = curveFor(layerIn.bezier, curves, layerInCurve);
            }
            if (layerOut) {
                layerOutDuration = layerOut.enabled ? Math.round(layerOut.speed * 100) : 0;
                layerOutCurve = curveFor(layerOut.bezier, curves, layerOutCurve);
            }
        } catch (error) {
            console.warn("Unable to parse Hyprland animation settings:", error);
        }
    }

    Component.onCompleted: refresh()

    property Process queryProcess: Process {
        id: query
        command: ["hyprctl", "animations", "-j"]
        stdout: StdioCollector { onStreamFinished: root.applyConfiguration(text) }
    }

    property Connections hyprlandEvents: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.refresh();
        }
    }
}
