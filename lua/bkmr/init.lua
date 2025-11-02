-- bkmr.nvim - Neovim integration for bkmr snippet manager
-- Main entry point and public API

local M = {}

local config = require('bkmr.config')
local lsp = require('bkmr.lsp')
local ui = require('bkmr.ui')

-- Plugin version
M.version = '0.2.5'

-- Setup function - configures the plugin
function M.setup(opts)
  config.setup(opts or {})

  -- Setup LSP integration if enabled
  if config.get().lsp.auto_setup then
    lsp.setup()
  end

  -- Create user commands
  M.create_commands()
end

-- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command('BkmrEdit', function(opts)
    -- Use provided language or default to current buffer's filetype
    local language_filter = nil
    if opts.args and opts.args ~= "" then
      language_filter = opts.args
    else
      -- Default to current buffer's filetype
      language_filter = vim.bo.filetype
      -- Only use if it's a recognized filetype (not empty)
      if language_filter == "" then
        language_filter = nil
      end
    end
    M.list_snippets(language_filter)
  end, {
    desc = 'Edit bkmr snippets (defaults to current filetype)',
    nargs = '?'
  })

  vim.api.nvim_create_user_command('BkmrNew', function()
    M.new_snippet()
  end, {
    desc = 'Create new bkmr snippet'
  })

  vim.api.nvim_create_user_command('BkmrDelete', function(opts)
    local id = tonumber(opts.args)
    if id then
      M.delete_snippet(id)
    else
      vim.notify('BkmrDelete: Please provide a snippet ID', vim.log.levels.ERROR)
    end
  end, {
    desc = 'Delete bkmr snippet by ID',
    nargs = 1
  })
end

-- Public API functions

-- Browse and edit snippets with optional filtering
function M.list_snippets(language_filter)
  if config.get().debug then
    local msg = '[bkmr.nvim] Browsing snippets for editing'
    if language_filter then
      msg = msg .. ' - language: ' .. language_filter
      if language_filter == vim.bo.filetype then
        msg = msg .. ' (current buffer filetype)'
      end
    else
      msg = msg .. ' - all languages'
    end
    vim.notify(msg, vim.log.levels.DEBUG)
  end
  lsp.list_snippets(language_filter, function(snippets)
    if not snippets or #snippets == 0 then
      vim.notify('No snippets found', vim.log.levels.INFO)
      return
    end

    ui.show_snippet_selector(snippets, function(selected_snippet)
      if selected_snippet then
        M.edit_snippet(selected_snippet.id)
      end
    end)
  end)
end

-- Edit existing snippet by ID
function M.edit_snippet(id)
  if config.get().debug then
    vim.notify('[bkmr.nvim] Editing snippet ID: ' .. id, vim.log.levels.DEBUG)
  end
  lsp.get_snippet(id, function(snippet)
    if snippet then
      ui.open_snippet_editor(snippet, function(updated_snippet)
        if updated_snippet then
          lsp.update_snippet(updated_snippet, function(success)
            if success then
              vim.notify('Snippet updated successfully', vim.log.levels.INFO)
              -- Close the editor buffer after successful save
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local buf_name = vim.api.nvim_buf_get_name(buf)
                if buf_name:match('bkmr://snippet/' .. id) then
                  vim.api.nvim_buf_delete(buf, { force = true })
                  break
                end
              end
            else
              vim.notify('Failed to update snippet', vim.log.levels.ERROR)
            end
          end)
        end
      end)
    else
      vim.notify('Snippet not found: ' .. id, vim.log.levels.ERROR)
    end
  end)
end

-- Create new snippet
function M.new_snippet()
  if config.get().debug then
    vim.notify('[bkmr.nvim] Creating new snippet', vim.log.levels.DEBUG)
  end
  local template_snippet = {
    id = nil,
    title = '',
    description = '',
    url = '',
    tags = {'_snip_'}
  }

  ui.open_snippet_editor(template_snippet, function(new_snippet)
    if new_snippet and new_snippet.url and new_snippet.url ~= '' then
      lsp.create_snippet(new_snippet, function(success, result)
        if success then
          vim.notify('Snippet created successfully', vim.log.levels.INFO)
          -- Close the editor buffer after successful save
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name:match('bkmr://snippet/new') then
              vim.api.nvim_buf_delete(buf, { force = true })
              break
            end
          end
        else
          vim.notify('Failed to create snippet: ' .. (result or 'Unknown error'), vim.log.levels.ERROR)
        end
      end)
    end
  end)
end

-- Delete snippet with confirmation
function M.delete_snippet(id)
  if config.get().debug then
    vim.notify('[bkmr.nvim] Deleting snippet ID: ' .. id, vim.log.levels.DEBUG)
  end
  if config.get().edit.confirm_delete then
    local confirm = vim.fn.confirm('Delete snippet ' .. id .. '?', '&Yes\n&No', 2)
    if confirm ~= 1 then
      return
    end
  end

  lsp.delete_snippet(id, function(success)
    if success then
      vim.notify('Snippet deleted successfully', vim.log.levels.INFO)
    else
      vim.notify('Failed to delete snippet', vim.log.levels.ERROR)
    end
  end)
end


-- Utility functions for other plugins to integrate

-- Get current snippet context (for completion, etc.)
function M.get_context()
  return {
    bufnr = vim.api.nvim_get_current_buf(),
    filetype = vim.bo.filetype,
    cursor_pos = vim.api.nvim_win_get_cursor(0)
  }
end

-- Check if LSP is available
function M.is_lsp_available()
  return lsp.is_available()
end

-- Get plugin configuration
function M.get_config()
  return config.get()
end

return M
