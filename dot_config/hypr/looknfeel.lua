-- Personal appearance overrides loaded after Omarchy's defaults.

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = {
      top = 4,
      right = 8,
      bottom = 8,
      left = 8,
    },
    resize_on_border = true,
    resize_corner = true,
  },

  decoration = {
    rounding = 8,
  },
})

-- Keep the focused window fully opaque while retaining inactive transparency.
o.window({ focus = true }, { opacity = "1 override" })

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

require("hypr.voxtype-border")
