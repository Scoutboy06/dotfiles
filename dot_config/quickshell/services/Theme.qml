import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    property color background: "#1a1b26"
    property color barBackground: "#1a1b26"
    property color foreground: "#c0caf5"
    property color accent: "#7aa2f7"
    property color surface: "#32344a"
    property color urgent: "#f7768e"
    property color success: "#9ece6a"
    property color warning: "#e0af68"
    readonly property string fontFamily: "CaskaydiaMono Nerd Font"

    property var basePalette: ({
        background: "#1a1b26",
        foreground: "#c0caf5",
        accent: "#7aa2f7",
        color0: "#32344a",
        color1: "#f7768e",
        color2: "#9ece6a",
        color3: "#e0af68"
    })
    property var waybarDefinitions: ({})

    function parseToml(contents) {
        const colours = {};
        for (const line of contents.split("\n")) {
            const match = line.match(/^([a-zA-Z0-9_]+)\s*=\s*"(#[0-9a-fA-F]{6,8})"/);
            if (match)
                colours[match[1]] = match[2];
        }
        basePalette = Object.assign({}, basePalette, colours);
        applyPalette();
    }

    function parseWaybar(contents) {
        const definitions = {};
        const expression = /@define-color\s+([a-zA-Z0-9_-]+)\s+([^;]+);/g;
        let match;
        while ((match = expression.exec(contents)) !== null)
            definitions[match[1]] = match[2].trim();
        waybarDefinitions = definitions;
        applyPalette();
    }

    function hexColor(value) {
        const hex = value.slice(1);
        const red = parseInt(hex.slice(0, 2), 16) / 255;
        const green = parseInt(hex.slice(2, 4), 16) / 255;
        const blue = parseInt(hex.slice(4, 6), 16) / 255;
        const alpha = hex.length === 8 ? parseInt(hex.slice(6, 8), 16) / 255 : 1;
        return Qt.rgba(red, green, blue, alpha);
    }

    function resolveWaybar(name, seen) {
        const value = waybarDefinitions[name];
        if (value === undefined || seen.includes(name))
            return undefined;
        const nextSeen = seen.concat([name]);

        if (/^#[0-9a-fA-F]{6,8}$/.test(value))
            return hexColor(value);

        const alias = value.match(/^@([a-zA-Z0-9_-]+)$/);
        if (alias)
            return resolveWaybar(alias[1], nextSeen);

        const alpha = value.match(/^alpha\(\s*@([a-zA-Z0-9_-]+)\s*,\s*([0-9.]+)\s*\)$/);
        if (alpha) {
            const base = resolveWaybar(alpha[1], nextSeen);
            if (base !== undefined)
                return Qt.rgba(base.r, base.g, base.b, Math.max(0, Math.min(1, Number(alpha[2]))));
        }

        return undefined;
    }

    function themedValue(names, fallback) {
        for (const name of names) {
            const value = resolveWaybar(name, []);
            if (value !== undefined)
                return value;
        }
        return fallback;
    }

    function applyPalette() {
        background = basePalette.background;
        barBackground = themedValue(["background"], basePalette.background);
        foreground = themedValue(["foreground"], basePalette.foreground);
        accent = themedValue(["accent"], basePalette.accent);
        surface = themedValue(["surface", "color0"], basePalette.color0);
        urgent = themedValue(["urgent", "color1"], basePalette.color1);
        success = themedValue(["success", "color2"], basePalette.color2);
        warning = themedValue(["warning", "color3"], basePalette.color3);
    }

    function reloadTheme() {
        themeFile.reload();
        waybarFile.reload();
    }

    property FileView themeFile: FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/colors.toml"
        onLoaded: root.parseToml(text())
    }

    property FileView waybarFile: FileView {
        path: Quickshell.env("HOME") + "/.config/omarchy/current/theme/waybar.css"
        onLoaded: root.parseWaybar(text())
    }
}
