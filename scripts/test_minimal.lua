-- Minimal test for bkmr.nvim LSP integration
-- Run with: nvim --clean -u scripts/test_minimal.lua

-- Set up minimal config
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Enable debug logging
require('bkmr').setup({
  debug = true,
  lsp = {
    auto_setup = false -- Manual setup for testing
  }
})

-- Manual LSP setup
local lsp = require('bkmr.lsp')
print("Setting up bkmr LSP...")
lsp.setup()

-- Wait for LSP to start, then test
vim.defer_fn(function()
  print("\n=== Testing BkmrEdit (all snippets) ===")
  require('bkmr').list_snippets()
  
  -- Test with language filter after a delay
  vim.defer_fn(function()
    print("\n=== Testing BkmrEdit with language filter ===")
    require('bkmr').list_snippets("sh")
    
    -- Test snippet creation
    vim.defer_fn(function()
      print("\n=== Testing BkmrNew ===")
      require('bkmr').new_snippet()
    end, 2000)
  end, 2000)
end, 3000)

print("bkmr.nvim minimal test loaded. Waiting for LSP startup...")