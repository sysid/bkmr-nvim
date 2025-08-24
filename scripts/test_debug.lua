-- Debug test for bkmr.nvim - shows all LSP communication
-- Run with: nvim --clean -u scripts/test_debug.lua

-- Set up runtime path
vim.opt.runtimepath:prepend(vim.fn.getcwd())

-- Override debug_notify to show everything
local original_notify = vim.notify
vim.notify = function(msg, level)
  level = level or vim.log.levels.INFO
  local level_names = {
    [vim.log.levels.DEBUG] = "DEBUG",
    [vim.log.levels.INFO] = "INFO",
    [vim.log.levels.WARN] = "WARN",
    [vim.log.levels.ERROR] = "ERROR"
  }
  print(string.format("[%s] %s", level_names[level] or "UNKNOWN", msg))
end

-- Set up plugin with maximum debugging
require('bkmr').setup({
  debug = true,
  lsp = {
    auto_setup = true,
  }
})

-- Helper function to test LSP calls
local function test_lsp_call(name, func)
  print("\n" .. string.rep("-", 40))
  print("Testing: " .. name)
  print(string.rep("-", 40))
  
  local success, result = pcall(func)
  if not success then
    print("ERROR: " .. tostring(result))
  end
end

-- Run tests after LSP startup
vim.defer_fn(function()
  print("\n" .. string.rep("=", 50))
  print("STARTING bkmr.nvim DEBUG TESTS")
  print(string.rep("=", 50))
  
  -- Test 1: Check LSP availability
  test_lsp_call("LSP Availability Check", function()
    local available = require('bkmr').is_lsp_available()
    print("Result: LSP Available = " .. tostring(available))
  end)
  
  -- Test 2: List all snippets
  vim.defer_fn(function()
    test_lsp_call("List All Snippets", function()
      require('bkmr').list_snippets()
    end)
    
    -- Test 3: List shell snippets  
    vim.defer_fn(function()
      test_lsp_call("List Shell Snippets", function()
        require('bkmr').list_snippets("shell")
      end)
      
      -- Test 4: Get specific snippet
      vim.defer_fn(function()
        test_lsp_call("Get Snippet 22", function()
          require('bkmr').edit_snippet(22)
        end)
      end, 2000)
    end, 2000)
  end, 2000)
end, 3000)

print("bkmr.nvim debug test environment loaded...")