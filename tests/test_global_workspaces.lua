-- Run from the dotfiles root: lua tests/test_global_workspaces.lua
local bindings = {}
local reconciled = false
o = {
  workspaces = { reconcile = function() reconciled = true end },
  rebind = function(keys, description, dispatcher)
    assert(bindings[keys] == nil, "Duplicate binding: " .. keys)
    bindings[keys] = dispatcher
  end,
}

local function dispatcher(kind)
  return function(options) return { kind = kind, options = options } end
end
hl = { dsp = {
  focus = dispatcher("focus"),
  window = { move = dispatcher("window.move") },
  workspace = { move = dispatcher("workspace.move") },
} }

dofile("dot_config/hypr/global-workspaces.lua")
o.workspaces.reconcile()
assert(not reconciled, "Stock reconciliation must not renumber global workspaces")

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  local focus = assert(bindings["SUPER + " .. key])
  assert(focus.kind == "focus" and focus.options.workspace == tostring(workspace))
  for _, silent in ipairs({ false, true }) do
    local modifiers = silent and "SUPER + SHIFT + ALT + " or "SUPER + SHIFT + "
    local move = assert(bindings[modifiers .. key])
    assert(move.kind == "window.move" and move.options.workspace == tostring(workspace))
    assert(move.options.follow == not silent)
  end
end

for key, direction in pairs({ LEFT = "l", RIGHT = "r", UP = "u", DOWN = "d" }) do
  local move = assert(bindings["SUPER + SHIFT + ALT + " .. key])
  assert(move.kind == "workspace.move" and move.options.monitor == direction)
end

print("Global workspace bindings: all tests passed")
