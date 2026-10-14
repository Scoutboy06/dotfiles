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

-- Float the Bitwarden desktop app at a consistent monitor-relative size.
o.window("^[Bb]itwarden$", {
  float = true,
  size = { "monitor_w * 0.65", "monitor_h * 0.75" },
  center = true,
})

-- Browser extension windows initially have the browser's generic title, so a
-- static rule cannot distinguish them. Check when they open, when their title
-- changes, and once on reload for windows that already exist.
local function float_bitwarden_extension(window)
  if window ~= nil
    and window.floating ~= true
    and type(window.title) == "string"
    and window.title:match("^Extension: %(Bitwarden Password Manager%)")
  then
    hl.dispatch(hl.dsp.window.float({ window = window, action = "set" }))
    hl.dispatch(hl.dsp.window.center({ window = window }))
  end
end

hl.on("window.open", float_bitwarden_extension)
hl.on("window.title", float_bitwarden_extension)
-- Zen re-evaluates the window after setting its extension title. Run after
-- that pass too so its final state remains floating.
hl.on("window.update_rules", float_bitwarden_extension)

for _, window in ipairs(hl.get_windows()) do
  float_bitwarden_extension(window)
end

-- Toggle config flags dynamically.
require("default.hypr.toggles")
