-- Interactive test for bkmr.nvim
-- Run with: nvim --clean -u scripts/test_interactive.lua
-- Then manually test commands: :BkmrEdit, :BkmrNew, :BkmrDelete, etc.

-- Set up runtime path
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Configure plugin with debug enabled
require('bkmr').setup({
  debug = true,
  ui = {
    use_fzf = true,
    use_telescope = false,
  },
  edit = {
    confirm_delete = false, -- Skip confirmation in tests
  }
})

-- Create helpful commands for testing
vim.api.nvim_create_user_command('TestLspAvailable', function()
  local available = require('bkmr').is_lsp_available()
  print("LSP Available: " .. tostring(available))
end, { desc = 'Check if bkmr LSP is available' })

vim.api.nvim_create_user_command('TestEditAll', function()
  print("Testing edit all snippets...")
  require('bkmr').list_snippets()
end, { desc = 'Test editing all snippets' })

vim.api.nvim_create_user_command('TestEditShell', function()
  print("Testing edit shell snippets...")
  require('bkmr').list_snippets("shell")
end, { desc = 'Test editing shell snippets' })

vim.api.nvim_create_user_command('TestNew', function()
  print("Testing create new snippet...")
  require('bkmr').new_snippet()
end, { 
  desc = 'Test creating new snippet'
})

-- Show startup message
vim.defer_fn(function()
  print("\n" .. string.rep("=", 60))
  print("bkmr.nvim Interactive Test Environment")
  print(string.rep("=", 60))
  print("Available test commands:")
  print("  :TestLspAvailable   - Check LSP status")
  print("  :TestEditAll        - Test BkmrEdit (all)")
  print("  :TestEditShell      - Test BkmrEdit shell")
  print("  :TestNew            - Test BkmrNew")
  print("")
  print("Main commands:")
  print("  :BkmrEdit           - Edit snippets (current filetype)")
  print("  :BkmrEdit sh        - Edit shell snippets") 
  print("  :BkmrNew            - Create new snippet")
  print("  :BkmrDelete 123     - Delete snippet by ID")
  print(string.rep("=", 60))
end, 1000)

print("Loading bkmr.nvim interactive test environment...")