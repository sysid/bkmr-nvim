-- LSP client integration for bkmr.nvim

local M = {}

local config = require('bkmr.config')

-- LSP client reference
local client = nil

-- Helper function for debug logging
local function debug_notify(msg, level)
  level = level or vim.log.levels.DEBUG
  if config.get().debug or level ~= vim.log.levels.DEBUG then
    vim.notify('[bkmr.nvim] ' .. msg, level)
  end
end

-- Helper function to truncate large responses for logging
local function truncate_response(data)
  if type(data) ~= 'table' then
    return tostring(data)
  end

  -- If it's an array with more than 10 items
  if #data > 10 then
    local truncated = {}
    for i = 1, 5 do
      truncated[i] = data[i]
    end
    truncated[#truncated + 1] = "... (" .. (#data - 10) .. " more items) ..."
    for i = #data - 4, #data do
      truncated[#truncated + 1] = data[i]
    end
    return vim.inspect(truncated)
  end

  return vim.inspect(data)
end

-- Setup LSP integration
function M.setup()
  -- Check if bkmr binary is available
  if vim.fn.executable('bkmr') == 0 then
    vim.notify('bkmr binary not found in PATH. LSP integration disabled.', vim.log.levels.WARN)
    vim.notify('Install bkmr with: cargo install bkmr', vim.log.levels.INFO)
    return false
  end

  -- Check bkmr version
  local version_output = vim.fn.system('bkmr --version')
  debug_notify('Found bkmr: ' .. vim.trim(version_output))

  -- Try to setup with nvim-lspconfig if available
  local ok, lspconfig = pcall(require, 'lspconfig')
  if ok then
    debug_notify('Using nvim-lspconfig for bkmr LSP setup')
    M.setup_with_lspconfig(lspconfig)
  else
    debug_notify('nvim-lspconfig not found, using manual LSP setup')
    M.setup_manual()
  end

  return true
end

-- Setup using nvim-lspconfig
function M.setup_with_lspconfig(lspconfig)
  local lsp_config = config.get_lsp_config()

  -- Import configs module separately
  local configs = require('lspconfig.configs')

  -- Check if bkmr_lsp is already configured
  if not configs.bkmr_lsp then
    configs.bkmr_lsp = {
      default_config = {
        cmd = lsp_config.cmd,
        filetypes = lsp_config.filetypes,
        root_dir = lsp_config.root_dir,
        settings = lsp_config.settings,
      },
    }
  end

  -- Setup the LSP
  lspconfig.bkmr_lsp.setup({
    cmd = lsp_config.cmd,
    filetypes = lsp_config.filetypes,
    root_dir = lsp_config.root_dir,
    settings = lsp_config.settings,
    capabilities = M.get_capabilities(),
    on_attach = function(c, bufnr)
      client = c
      M.on_attach(c, bufnr)
    end,
  })

  vim.notify('bkmr LSP configured with nvim-lspconfig', vim.log.levels.DEBUG)
end

-- Manual LSP setup (fallback)
function M.setup_manual()
  local lsp_config = config.get_lsp_config()

  -- Get root directory for current buffer
  local root_dir = lsp_config.root_dir(vim.fn.expand('%:p'))

  local client_id = vim.lsp.start({
    name = 'bkmr-lsp',
    cmd = lsp_config.cmd,
    filetypes = lsp_config.filetypes,
    root_dir = root_dir,
    settings = lsp_config.settings,
    capabilities = M.get_capabilities(),
    on_attach = function(c, bufnr)
      client = c
      M.on_attach(c, bufnr)
      vim.notify('bkmr LSP client attached to buffer ' .. bufnr, vim.log.levels.DEBUG)
    end,
  })

  if client_id then
    vim.notify('bkmr LSP configured manually (client_id: ' .. client_id .. ')', vim.log.levels.DEBUG)
  else
    vim.notify('Failed to start bkmr LSP server', vim.log.levels.ERROR)
  end
end

-- Get LSP capabilities
function M.get_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  -- Add snippet support
  capabilities.textDocument.completion.completionItem.snippetSupport = true

  -- Try to get cmp capabilities if available
  local ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
  if ok then
    capabilities = cmp_lsp.default_capabilities(capabilities)
  end

  return capabilities
end

-- LSP on_attach callback
function M.on_attach(c, bufnr)
  -- Store client reference
  client = c

  -- Setup buffer-local keymaps or other configurations if needed
  -- For now, we rely on the user commands from init.lua
end

-- Check if LSP is available and ready
function M.is_available()
  if not client then
    -- Try to find bkmr-lsp client if not stored
    local clients = vim.lsp.get_clients({name = 'bkmr-lsp'})
    if #clients > 0 then
      client = clients[1]
      debug_notify('Found existing bkmr LSP client')
    end
  end

  return client ~= nil and not client.is_stopped()
end

-- Get LSP client
function M.get_client()
  return client
end

-- LSP command wrappers

-- List snippets via LSP
function M.list_snippets(language_filter, callback)
  if not M.is_available() then
    vim.notify('bkmr LSP not available. Please ensure bkmr LSP server is running.', vim.log.levels.ERROR)
    callback(nil)
    return
  end

  local request_params = {
    command = 'bkmr.listSnippets'
  }

  if language_filter and language_filter ~= "" then
    request_params.arguments = { { language = language_filter } }
    debug_notify('Listing snippets for language: ' .. language_filter)
  else
    -- Don't send arguments at all for listing all snippets
    debug_notify('Listing all snippets...')
  end

  client.request('workspace/executeCommand', request_params, function(err, result)
    debug_notify('LSP listSnippets response - err: ' .. tostring(err) .. ', result: ' .. truncate_response(result))

    if err then
      vim.notify('Failed to list snippets: ' .. tostring(err), vim.log.levels.ERROR)
      callback(nil)
    elseif result and result.success then
      local snippets = result.snippets or {}
      debug_notify('Retrieved ' .. #snippets .. ' snippets')
      callback(snippets)
    elseif result and type(result) == 'table' and result.snippets then
      -- Handle case where success field is missing but snippets are present
      local snippets = result.snippets or {}
      debug_notify('Retrieved ' .. #snippets .. ' snippets (no success field)')
      callback(snippets)
    elseif result and type(result) == 'table' and #result > 0 then
      -- Handle case where result is an array of snippets directly
      debug_notify('Retrieved ' .. #result .. ' snippets (direct array)')
      callback(result)
    else
      local error_msg = result and result.error or 'Unknown error'
      -- Handle both string and table error messages
      local error_str
      if type(error_msg) == 'table' then
        error_str = error_msg.message or error_msg.error or vim.inspect(error_msg)
      else
        error_str = tostring(error_msg)
      end
      vim.notify('Failed to list snippets: ' .. error_str, vim.log.levels.ERROR)
      callback(nil)
    end
  end)
end

-- Get snippet by ID via LSP
function M.get_snippet(id, callback)
  if not M.is_available() then
    vim.notify('bkmr LSP not available. Please ensure bkmr LSP server is running.', vim.log.levels.ERROR)
    callback(nil)
    return
  end

  debug_notify('Retrieving snippet ' .. id .. '...')

  client.request('workspace/executeCommand', {
    command = 'bkmr.getSnippet',
    arguments = { { id = id } }
  }, function(err, result)
    debug_notify('LSP getSnippet response - err: ' .. tostring(err) .. ', result: ' .. truncate_response(result))

    if err then
      vim.notify('Failed to get snippet ' .. id .. ': ' .. tostring(err), vim.log.levels.ERROR)
      callback(nil)
    elseif result and result.success then
      debug_notify('Successfully retrieved snippet ' .. id)
      callback(result.snippet)
    elseif result and result.snippet then
      -- Some LSP servers might return snippet directly without success field
      debug_notify('Retrieved snippet ' .. id .. ' (no success field)')
      callback(result.snippet)
    elseif result and type(result) == 'table' then
      -- Check if the result IS the snippet directly (has expected fields)
      if result.id or result.url or result.title then
        debug_notify('Retrieved snippet ' .. id .. ' (direct response)')
        callback(result)
      else
        -- It's an error response
        local error_msg = result.error or result
        local error_str
        if type(error_msg) == 'table' then
          -- If it's a table, try to extract meaningful info
          error_str = error_msg.message or error_msg.error or vim.inspect(error_msg)
        else
          error_str = tostring(error_msg)
        end

        if error_str:match('not found') or error_str:match('No snippet') or error_str:match('not a snippet') then
          vim.notify('Snippet ' .. id .. ' not found or is not a snippet type.', vim.log.levels.WARN)
        else
          vim.notify('Failed to get snippet ' .. id .. ': ' .. error_str, vim.log.levels.ERROR)
        end
        callback(nil)
      end
    else
      vim.notify('Failed to get snippet ' .. id .. ': Unexpected response format', vim.log.levels.ERROR)
      callback(nil)
    end
  end)
end

-- Create snippet via LSP
function M.create_snippet(snippet, callback)
  if not M.is_available() then
    vim.notify('bkmr LSP not available', vim.log.levels.ERROR)
    callback(false)
    return
  end

  local params = {
    url = snippet.url,
    title = snippet.title,
    description = snippet.description,
    tags = snippet.tags or {}
  }

  debug_notify('Creating snippet with params: ' .. truncate_response(params))

  client.request('workspace/executeCommand', {
    command = 'bkmr.createSnippet',
    arguments = { params }
  }, function(err, result)
    debug_notify('LSP createSnippet response - err: ' .. tostring(err) .. ', result: ' .. truncate_response(result))
    if err then
      vim.notify('Failed to create snippet: ' .. tostring(err), vim.log.levels.ERROR)
      callback(false, tostring(err))
    elseif result and result.success then
      callback(true, result)
    elseif result and result.id then
      -- Server returned the created snippet directly (which means success)
      debug_notify('Snippet created successfully with ID: ' .. result.id)
      callback(true, result)
    else
      callback(false, result and result.error or 'Unknown error')
    end
  end)
end

-- Update snippet via LSP
function M.update_snippet(snippet, callback)
  if not M.is_available() then
    vim.notify('bkmr LSP not available', vim.log.levels.ERROR)
    callback(false)
    return
  end

  local params = {
    id = snippet.id,
    url = snippet.url,
    title = snippet.title,
    description = snippet.description,
    tags = snippet.tags
  }

  debug_notify('Updating snippet ' .. snippet.id .. ' with params: ' .. truncate_response(params))

  client.request('workspace/executeCommand', {
    command = 'bkmr.updateSnippet',
    arguments = { params }
  }, function(err, result)
    debug_notify('LSP updateSnippet response - err: ' .. tostring(err) .. ', result: ' .. truncate_response(result))
    if err then
      vim.notify('Failed to update snippet: ' .. tostring(err), vim.log.levels.ERROR)
      callback(false)
    elseif result and result.success then
      callback(true)
    elseif result and result.id then
      -- Server returned the updated snippet directly (which means success)
      debug_notify('Snippet updated successfully')
      callback(true)
    else
      local error_msg = result and result.error or 'Unknown error'
      local error_str = type(error_msg) == 'table' and (error_msg.message or error_msg.error or vim.inspect(error_msg)) or tostring(error_msg)
      vim.notify('Failed to update snippet: ' .. error_str, vim.log.levels.ERROR)
      callback(false)
    end
  end)
end

-- Delete snippet via LSP
function M.delete_snippet(id, callback)
  if not M.is_available() then
    vim.notify('bkmr LSP not available', vim.log.levels.ERROR)
    callback(false)
    return
  end

  debug_notify('Deleting snippet ' .. id)

  client.request('workspace/executeCommand', {
    command = 'bkmr.deleteSnippet',
    arguments = { { id = id } }
  }, function(err, result)
    debug_notify('LSP deleteSnippet response - err: ' .. tostring(err) .. ', result: ' .. truncate_response(result))
    if err then
      vim.notify('Failed to delete snippet: ' .. tostring(err), vim.log.levels.ERROR)
      callback(false)
    elseif result and result.success then
      callback(true)
    elseif result == vim.NIL or result == nil then
      -- Server returned nil/empty response (which typically means success for delete operations)
      debug_notify('Snippet deleted successfully')
      callback(true)
    else
      local error_msg = result and result.error or 'Unknown error'
      local error_str = type(error_msg) == 'table' and (error_msg.message or error_msg.error or vim.inspect(error_msg)) or tostring(error_msg)
      vim.notify('Failed to delete snippet: ' .. error_str, vim.log.levels.ERROR)
      callback(false)
    end
  end)
end

-- Insert filepath comment via LSP
function M.insert_filepath_comment(callback)
  if not M.is_available() then
    vim.notify('bkmr LSP not available', vim.log.levels.ERROR)
    if callback then callback(false) end
    return
  end

  local uri = vim.uri_from_bufnr(0)

  client.request('workspace/executeCommand', {
    command = 'bkmr.insertFilepathComment',
    arguments = { uri }
  }, function(err, result)
    if err then
      vim.notify('Failed to insert filepath comment: ' .. tostring(err), vim.log.levels.ERROR)
      if callback then callback(false) end
    elseif result and result.success then
      if callback then callback(true) end
    else
      local error_msg = result and result.error or 'Unknown error'
      local error_str = type(error_msg) == 'table' and (error_msg.message or error_msg.error or vim.inspect(error_msg)) or tostring(error_msg)
      vim.notify('Failed to insert filepath comment: ' .. error_str, vim.log.levels.ERROR)
      if callback then callback(false) end
    end
  end)
end

return M
