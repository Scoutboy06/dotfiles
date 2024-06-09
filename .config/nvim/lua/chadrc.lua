-- This file  needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/NvChad/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.ui = {
	theme = "onedark",
  transparency = true,
  telescope = { style = "bordered" },

  statusline = {
    theme = "default",
    separator_style = "round",
  },

  nvdash = {
    load_on_startup = true,
  }
	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.plugins = "custom.plugins"

-- M.nvimtree = {
--   git = {
--     enable = true,
--   },
--   renderer = {
--     highlight_git = true,
--     show = { git = true },
--   },
--   view = {
--     side = "right"
--   }
-- }

return M
