-- Publish focused-window geometry for the click-through Quickshell inner glow.
local runtime = os.getenv("XDG_RUNTIME_DIR")
if not runtime then return end
local previous
local recording = false
local normal = hl.get_config("general.col.active_border")
local normal_group = hl.get_config("group.col.border_active")
local normal_locked = hl.get_config("group.col.border_locked_active")

local function update()
  local file = io.open(runtime .. "/voxtype/state", "r")
  local state = file and file:read("*l") or "idle"
  if file then file:close() end
  local payload = ""
  local window = hl.get_active_window()
  local active = state == "recording" and window and window.mapped and not window.hidden and window.monitor ~= nil
  if not not active ~= recording then
    recording = not not active
    hl.config({
      general = { col = { active_border = recording and "rgba(00000000)" or normal } },
      group = { col = {
        border_active = recording and "rgba(00000000)" or normal_group,
        border_locked_active = recording and "rgba(00000000)" or normal_locked,
      } },
    })
  end
  if active then
    local at, size, monitor = window.at, window.size, window.monitor
    local fullscreen = window.fullscreen == 2
    payload = string.format("%s\n%f\n%f\n%f\n%f\n%f\n%f\n%s", monitor.name,
      at.x - monitor.x, at.y - monitor.y, size.x, size.y,
      fullscreen and 0 or hl.get_config("decoration.rounding"),
      fullscreen and 0 or hl.get_config("general.border_size"), window.address)
  end
  if payload == previous then return end
  local output = io.open(runtime .. "/voxtype-glow", "w")
  if output then
    output:write(payload)
    output:close()
    previous = payload
  end
end

update()
hl.timer(update, { timeout = 150, type = "repeat" })
