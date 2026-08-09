import Quickshell.Hyprland
import QtQuick

Row {
    id: root

    required property var screen
    required property var theme
    required property var motion

    spacing: 6

    Repeater {
        model: Hyprland.workspaces.values.filter(workspace => {
            const monitor = Hyprland.monitorFor(root.screen);
            return workspace.monitor === monitor && !workspace.name.startsWith("special:");
        })

        delegate: WorkspacePill {
            required property var modelData
            workspace: modelData
            theme: root.theme
            motion: root.motion
        }
    }
}
