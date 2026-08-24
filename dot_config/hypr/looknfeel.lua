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
