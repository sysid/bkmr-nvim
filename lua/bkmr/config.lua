-- Configuration management for bkmr.nvim

local M = {}

-- Default configuration
local default_config = {
  lsp = {
    auto_setup = true,                 -- Auto-configure with lspconfig
    cmd = { "bkmr", "lsp" },          -- LSP server command
    filetypes = {                     -- Supported file types
      'rust', 'javascript', 'typescript', 'python', 'go', 'java', 'c', 'cpp',
      'html', 'css', 'scss', 'ruby', 'php', 'swift', 'kotlin', 'shell', 'sh',
      'bash', 'yaml', 'json', 'markdown', 'xml', 'vim', 'lua', 'toml'
    }
  },
  ui = {
    split_direction = "vertical",      -- "horizontal" | "vertical"
    split_size = "50%",                -- Split width/height (number or percentage string)
    use_telescope = false,            -- Use telescope for selection (disabled per user request)
    use_fzf = true,                   -- Use fzf-lua for selection (enabled per user request)
  },
  edit = {
    auto_save = false,                -- Auto-save on buffer leave
    confirm_delete = true,            -- Confirm before deletion
    template_header = true,           -- Show template header in edit buffer
  },
  debug = false,                      -- Enable debug logging
}

-- Current configuration (starts as copy of default)
local current_config = vim.deepcopy(default_config)

-- Setup configuration with user overrides
function M.setup(user_config)
  current_config = vim.tbl_deep_extend('force', current_config, user_config or {})
  
  -- Validate configuration
  M.validate(current_config)
end

-- Get current configuration
function M.get()
  return current_config
end

-- Get default configuration
function M.get_default()
  return vim.deepcopy(default_config)
end

-- Validate configuration
function M.validate(cfg)
  cfg = cfg or current_config
  
  -- Validate split_direction
  if cfg.ui.split_direction ~= "vertical" and cfg.ui.split_direction ~= "horizontal" then
    vim.notify('Invalid split_direction: ' .. cfg.ui.split_direction .. '. Using "vertical".', vim.log.levels.WARN)
    cfg.ui.split_direction = "vertical"
  end
  
  -- Validate split_size (can be number or percentage string)
  local split_size = cfg.ui.split_size
  if type(split_size) == "string" then
    -- Check if it's a valid percentage format
    if not split_size:match("^%d+%%$") then
      vim.notify('Invalid split_size format: ' .. split_size .. '. Using "50%".', vim.log.levels.WARN)
      cfg.ui.split_size = "50%"
    end
  elseif type(split_size) ~= "number" or split_size <= 0 then
    vim.notify('Invalid split_size: ' .. tostring(split_size) .. '. Using "50%".', vim.log.levels.WARN)
    cfg.ui.split_size = "50%"
  end
  
  -- Validate LSP command
  if not cfg.lsp.cmd or type(cfg.lsp.cmd) ~= "table" or #cfg.lsp.cmd == 0 then
    vim.notify('Invalid LSP command configuration. Using default.', vim.log.levels.WARN)
    cfg.lsp.cmd = {"bkmr", "lsp"}
  end
  
  return true
end

-- Update specific configuration value
function M.set(key_path, value)
  local keys = vim.split(key_path, '.', true)
  local current = current_config
  
  -- Navigate to parent of target key
  for i = 1, #keys - 1 do
    local key = keys[i]
    if not current[key] then
      current[key] = {}
    end
    current = current[key]
  end
  
  -- Set the value
  current[keys[#keys]] = value
  
  -- Re-validate
  M.validate()
end

-- Get specific configuration value
function M.get_value(key_path)
  local keys = vim.split(key_path, '.', true)
  local current = current_config
  
  for _, key in ipairs(keys) do
    if type(current) ~= "table" or not current[key] then
      return nil
    end
    current = current[key]
  end
  
  return current
end

-- Check if a feature is enabled
function M.is_enabled(feature)
  return M.get_value(feature) == true
end

-- Get LSP configuration for nvim-lspconfig
function M.get_lsp_config()
  return {
    cmd = current_config.lsp.cmd,
    filetypes = current_config.lsp.filetypes,
    root_dir = function(fname)
      -- Try to find project root, fallback to current directory
      local ok, lspconfig_util = pcall(require, 'lspconfig.util')
      if ok and lspconfig_util then
        return lspconfig_util.find_git_ancestor(fname) or vim.fn.getcwd()
      else
        return vim.fn.getcwd()
      end
    end,
    settings = {
      bkmr = {
        enableIncrementalCompletion = false
      }
    },
  }
end

return M