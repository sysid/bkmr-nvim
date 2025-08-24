-- bkmr.nvim plugin loader
-- This file is automatically sourced by Neovim

-- Prevent double loading
if vim.g.loaded_bkmr_nvim then
  return
end
vim.g.loaded_bkmr_nvim = true

-- Set up the plugin namespace
local bkmr = require('bkmr')

-- Auto-setup with default configuration if not manually configured
if not vim.g.bkmr_manual_setup then
  bkmr.setup()
end

-- Create additional utility commands that don't require full setup
vim.api.nvim_create_user_command('BkmrInsertPath', function()
  require('bkmr.lsp').insert_filepath_comment()
end, {
  desc = 'Insert filepath comment at cursor'
})

-- Optional: Create mappings for quick access (users can override these)
if not vim.g.bkmr_no_default_mappings then
  -- Leader-based mappings for snippet management
  vim.keymap.set('n', '<leader>bs', function() 
    require('bkmr').list_snippets() 
  end, { desc = 'List bkmr snippets' })
  
  vim.keymap.set('n', '<leader>bn', function() 
    require('bkmr').new_snippet() 
  end, { desc = 'Create new bkmr snippet' })
  
  vim.keymap.set('n', '<leader>bp', function() 
    require('bkmr.lsp').insert_filepath_comment() 
  end, { desc = 'Insert filepath comment' })
end