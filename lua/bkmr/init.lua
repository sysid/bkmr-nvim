-- bkmr.nvim - Neovim integration for bkmr snippet manager
-- Main entry point and public API

local M = {}

local config = require('bkmr.config')
local lsp = require('bkmr.lsp')
local ui = require('bkmr.ui')

-- Plugin version
M.version = '0.1.0'

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
  vim.api.nvim_create_user_command('BkmrList', function(opts)
    M.list_snippets(opts.args)
  end, {
    desc = 'List all bkmr snippets',
    nargs = '?'
  })

  vim.api.nvim_create_user_command('BkmrEdit', function(opts)
    local id = tonumber(opts.args)
    if id then
      M.edit_snippet(id)
    else
      vim.notify('BkmrEdit: Please provide a snippet ID', vim.log.levels.ERROR)
    end
  end, {
    desc = 'Edit bkmr snippet by ID',
    nargs = 1
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

  vim.api.nvim_create_user_command('BkmrSearch', function(opts)
    M.search_snippets(opts.args)
  end, {
    desc = 'Search bkmr snippets',
    nargs = '?'
  })

  vim.api.nvim_create_user_command('BkmrTags', function()
    M.list_tags()
  end, {
    desc = 'List available tags'
  })
end

-- Public API functions

-- List all snippets with optional filtering
function M.list_snippets(language_filter)
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
  lsp.get_snippet(id, function(snippet)
    if snippet then
      ui.open_snippet_editor(snippet, function(updated_snippet)
        if updated_snippet then
          lsp.update_snippet(updated_snippet, function(success)
            if success then
              vim.notify('Snippet updated successfully', vim.log.levels.INFO)
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
        else
          vim.notify('Failed to create snippet: ' .. (result or 'Unknown error'), vim.log.levels.ERROR)
        end
      end)
    end
  end)
end

-- Delete snippet with confirmation
function M.delete_snippet(id)
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

-- Search snippets (placeholder - uses list with filtering for now)
function M.search_snippets(query)
  -- For now, just list all snippets and let user filter
  -- Could be enhanced to use bkmr CLI search directly
  M.list_snippets()
end

-- List available tags (placeholder)
function M.list_tags()
  vim.notify('Tag listing not implemented yet', vim.log.levels.WARN)
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
