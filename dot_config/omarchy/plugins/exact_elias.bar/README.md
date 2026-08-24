# Elias Islands Bar

Local clone of `omarchy.bar` that adds an opt-in `bar.islands` mode. The outer
bar surface becomes transparent while the left, center, and right sections use
the active theme's solid bar background, 8px rounded corners, and the spacing
from the former Elias Jade Waybar configuration. A theme can set the optional
`bar_island_background` key in `colors.toml`; without it, islands use the normal
bar background.

The bar engine is based on `/usr/share/omarchy/shell/plugins/bar/Bar.qml` and
uses its `BarModel.js`. Reconcile this clone with those packaged files when an
Omarchy update changes the stock bar engine.

Unlike the statically loaded stock bar, a custom bar is loaded before the shell
injects its properties. Keep the custom bar's injected properties optional and
null-safe so it can initialize successfully.
