vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.scrolloff = 8
vim.opt.termguicolors = true
vim.g.mapleader = " "
-- vim.opt.colorcolumn = "80"

 -- Disable netrw
--[[ vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1 ]]

vim.cmd("set number relativenumber")
vim.cmd("set noshowmode")
vim.api.nvim_set_keymap("n", ";", ":", { noremap = true, silent = false })
