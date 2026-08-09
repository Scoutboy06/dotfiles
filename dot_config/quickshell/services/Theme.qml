import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property color background: "#1a1b26"
    property color foreground: "#c0caf5"
    property color accent: "#7aa2f7"
    property color surface: "#32344a"
    property color urgent: "#f7768e"
    property color success: "#9ece6a"
    property color warning: "#e0af68"

    function load(contents) {
        const colours = {};
        for (const line of contents.split("\n")) {
            const match = line.match(/^([a-zA-Z0-9_]+)\s*=\s*"(#[0-9a-fA-F]{6,8})"/);
            if (match)
                colours[match[1]] = match[2];
        }

        background = colours.background ?? background;
        foreground = colours.foreground ?? foreground;
        accent = colours.accent ?? accent;
        surface = colours.color0 ?? surface;
        urgent = colours.color1 ?? urgent;
        success = colours.color2 ?? success;
        warning = colours.color3 ?? warning;
    }

    // Omarchy atomically replaces the whole theme directory. Watch theme.name,
    // which changes after the swap, so the new colors file is always reopened.
    property FileView themeNameFile: FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme.name"
        watchChanges: true
        onFileChanged: {
            reload();
            root.themeFile.reload();
        }
    }

    property FileView themeFile: FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/colors.toml"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(text())
    }
}
