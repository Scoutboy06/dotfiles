-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Load personal overrides after Omarchy's defaults.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Float Bitwarden at a consistent monitor-relative size.
o.window("^[Bb]itwarden$", {
  float = true,
  size = { "monitor_w * 0.65", "monitor_h * 0.75" },
  center = true,
})

-- Toggle config flags dynamically.
require("default.hypr.toggles")
