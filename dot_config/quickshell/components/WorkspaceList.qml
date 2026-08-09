import Quickshell.Hyprland
import QtQuick

Row {
    id: root

    required property var screen
    required property var theme
    required property var motion
    property bool hoverEnabled: true
    signal workspaceActivated

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property string activeSpecial: monitor?.lastIpcObject.specialWorkspace?.name ?? ""
    readonly property var numericWorkspaceIds: {
        const ids = [1, 2, 3, 4, 5];
        Hyprland.workspaces.values.forEach(workspace => {
            if (workspace.id > 0 && !ids.includes(workspace.id))
                ids.push(workspace.id);
        });
        return ids.sort((left, right) => left - right);
    }
    readonly property var specialWorkspaces: Hyprland.workspaces.values.filter(workspace =>
        workspace.name.startsWith("special:")
            && (workspace.toplevels.values.length > 0 || Hyprland.monitors.values.some(candidate =>
                candidate.lastIpcObject.specialWorkspace?.name === workspace.name))
    ).sort((left, right) => left.name.localeCompare(right.name))

    spacing: 4

    Repeater {
        model: root.numericWorkspaceIds

        delegate: WorkspacePill {
            required property int modelData
            readonly property var workspace: Hyprland.workspaces.values.find(candidate => candidate.id === modelData)

            label: modelData.toString()
            active: workspace === Hyprland.focusedWorkspace
            occupied: (workspace?.toplevels.values.length ?? 0) > 0
            theme: root.theme
            motion: root.motion
            hoverEnabled: root.hoverEnabled
            onActivated: {
                root.workspaceActivated();
                if (workspace)
                    workspace.activate();
                else
                    Hyprland.dispatch("workspace " + modelData);
            }
        }
    }

    Repeater {
        model: root.specialWorkspaces

        delegate: WorkspacePill {
            required property var modelData
            readonly property string specialName: modelData.name.slice("special:".length)

            label: specialName.slice(0, 1).toLowerCase()
            active: modelData.name === root.activeSpecial
            occupied: modelData.toplevels.values.length > 0
            theme: root.theme
            motion: root.motion
            hoverEnabled: root.hoverEnabled
            onActivated: {
                root.workspaceActivated();
                Hyprland.dispatch("togglespecialworkspace " + specialName);
            }
        }
    }
}
