-- Personal keybinding overrides loaded after Omarchy's defaults.

-- SUPER + SHIFT + RETURN is Omarchy's browser binding by default.
hl.unbind("SUPER + SHIFT + RETURN")
o.bind("SUPER + SHIFT + RETURN", "Tmux", "omarchy launch terminal tmux")

-- Additional application binding not provided by Omarchy's defaults.
o.bind("CTRL + SHIFT + ESCAPE", "Activity", "omarchy launch tui btop")

-- Special workspace toggles.
o.bind("SUPER + D", "Vesktop workspace", hl.dsp.workspace.toggle_special("vesktop"))
o.bind("SUPER + M", "Music workspace", hl.dsp.workspace.toggle_special("music"))
o.bind("SUPER + odiaeresis", "Terminal workspace", hl.dsp.workspace.toggle_special("terminal"))

-- Vesktop and Spotify always open on their dedicated special workspaces.
o.window("^[Vv]esktop$", { workspace = "special:vesktop" })
o.window("^[Ss]potify$", { workspace = "special:music" })

-- Override Omarchy's stock Steam floating rule in Big Picture mode.
o.window({ class = "^steam$", title = "^Steam Big Picture Mode$" }, {
  float = false,
  fullscreen = true,
})

-- Vim-style focus movement. SUPER + J/K/L replace Omarchy's split,
-- keybindings-menu, and workspace-layout bindings respectively.
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right", hl.dsp.focus({ direction = "r" }))
