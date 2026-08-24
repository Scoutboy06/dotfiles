-- Personal input overrides loaded after Omarchy's defaults.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    kb_layout = "se",
    kb_options = "caps:escape",
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
})

-- Preserve the terminal-specific touchpad scroll speeds explicitly.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Three-finger workspace switching, plus Alt-modified resizing in either axis.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "horizontal", mods = "ALT", action = "resize" })
hl.gesture({ fingers = 3, direction = "vertical", mods = "ALT", action = "resize" })
