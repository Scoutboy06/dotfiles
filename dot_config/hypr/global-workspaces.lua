-- Desktop workspaces use global ids, not Omarchy's per-monitor blocks.
-- The stock event handlers call this method on startup, reload and hotplug.
-- Disable reassignment so they cannot renumber our odd/even or series layout.
o.workspaces.reconcile = function() end

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  local id = tostring(workspace)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. id,
    hl.dsp.focus({ workspace = id }))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. id,
    hl.dsp.window.move({ workspace = id, follow = true }))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. id,
    hl.dsp.window.move({ workspace = id, follow = false }))
end

-- Keep global ids when manually moving a workspace between monitors too.
for key, direction in pairs({ LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }) do
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move workspace to " .. direction .. " monitor",
    hl.dsp.workspace.move({ monitor = direction }))
end
