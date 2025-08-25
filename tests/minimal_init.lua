-- Minimal init.lua for testing bkmr.nvim

-- Add plugin to runtime path
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(plugin_root)

-- Try to find plenary in common locations
local plenary_paths = {
  vim.fn.expand('~/.local/share/nvim/lazy/plenary.nvim'),
  vim.fn.expand('~/.local/share/nvim/site/pack/packer/start/plenary.nvim'),
  vim.fn.expand('~/.config/nvim/plugged/plenary.nvim'),
  vim.fn.stdpath('data') .. '/lazy/plenary.nvim',
  vim.fn.stdpath('data') .. '/site/pack/packer/start/plenary.nvim'
}

local plenary_found = false
for _, path in ipairs(plenary_paths) do
  if vim.fn.isdirectory(path) == 1 then
    vim.opt.runtimepath:append(path)
    plenary_found = true
    break
  end
end

if not plenary_found then
  print("Warning: plenary.nvim not found. Tests require plenary.nvim to be installed.")
  print("Install with your package manager, e.g.:")
  print("  Lazy: { 'nvim-lua/plenary.nvim' }")
  print("  Packer: use 'nvim-lua/plenary.nvim'")
end

-- Minimal settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.hidden = true

-- Mock vim.notify for cleaner test output
local original_notify = vim.notify
vim.notify = function(msg, level)
  if level == vim.log.levels.ERROR or level == vim.log.levels.WARN then
    original_notify(msg, level)
  end
end

-- Ensure required globals are available
vim.g = vim.g or {}
vim.b = vim.b or {}
vim.w = vim.w or {}
vim.t = vim.t or {}

-- Mock LSP to prevent hanging during tests
vim.lsp = vim.lsp or {}
vim.lsp.start = function() return nil end
vim.lsp.get_clients = function() return {} end

-- Stub lspconfig if it tries to load
package.loaded['lspconfig'] = {
  configs = {},
}
package.loaded['lspconfig.configs'] = {}