import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root
    property var geometry: []
    property string target: geometry.length === 8 ? geometry[7] : ""
    property real effectiveRadius: Number(geometry[5]) || 0
    onTargetChanged: {
        effectiveRadius = Number(geometry[5]) || 0;
        if (target !== "") radiusQuery.running = true;
    }
    Process {
        id: radiusQuery
        property string queriedTarget: ""
        command: ["hyprctl", "getprop", "address:" + root.target, "rounding"]
        onStarted: queriedTarget = root.target
        stdout: StdioCollector {
            onStreamFinished: {
                const radius = Number(text.trim());
                if (radiusQuery.queriedTarget === root.target && text.trim() !== "" && isFinite(radius))
                    root.effectiveRadius = Math.max(0, radius);
            }
        }
        onExited: { if (queriedTarget !== root.target && root.target !== "") running = true; }
    }
    FileView {
        id: state
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/voxtype-glow"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.geometry = text().trim().split("\n")
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: root.geometry.length === 8 && root.geometry[0] === modelData.name
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}
            WlrLayershell.namespace: "voxtype-glow"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            ShaderEffect {
                id: glow
                property real borderWidth: Number(root.geometry[6]) || 0
                // Extra drawing space only; never changes the actual window.
                property real outerPadding: 14
                x: (Number(root.geometry[1]) || 0) - borderWidth - outerPadding
                y: (Number(root.geometry[2]) || 0) - borderWidth - outerPadding
                width: (Number(root.geometry[3]) || 1) + 2 * (borderWidth + outerPadding)
                height: (Number(root.geometry[4]) || 1) + 2 * (borderWidth + outerPadding)
                property real cornerRadius: (Number(root.geometry[5]) === 0 ? 0 : root.effectiveRadius) + borderWidth
                property real phase: 0
                property vector2d resolution: Qt.vector2d(width, height)
                fragmentShader: Qt.resolvedUrl("glow.frag.qsb")
                FrameAnimation {
                    running: panel.visible
                    onTriggered: glow.phase += frameTime * 0.8
                }
            }
        }
    }
}
