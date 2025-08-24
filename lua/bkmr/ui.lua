-- UI components for bkmr.nvim

local M = {}

local config = require('bkmr.config')

-- Show snippet selector using fzf or fallback
function M.show_snippet_selector(snippets, callback)
  if config.get().ui.use_fzf then
    M.show_fzf_selector(snippets, callback)
  else
    M.show_builtin_selector(snippets, callback)
  end
end

-- FZF-based snippet selector
function M.show_fzf_selector(snippets, callback)
  local ok, fzf = pcall(require, 'fzf-lua')
  if not ok then
    vim.notify('fzf-lua not available, using builtin selector', vim.log.levels.WARN)
    M.show_builtin_selector(snippets, callback)
    return
  end
  
  -- Format snippets for display
  local formatted_items = {}
  local lookup = {}
  
  for _, snippet in ipairs(snippets) do
    local title = snippet.title or 'Untitled'
    local desc = snippet.description or ''
    local tags_str = table.concat(snippet.tags or {}, ',')
    
    -- Create display line: "ID: Title | Description | Tags"
    local display_line = string.format("%d: %s", snippet.id, title)
    if desc ~= '' then
      display_line = display_line .. " | " .. desc
    end
    if tags_str ~= '' then
      display_line = display_line .. " | [" .. tags_str .. "]"
    end
    
    table.insert(formatted_items, display_line)
    lookup[display_line] = snippet
  end
  
  fzf.fzf_exec(formatted_items, {
    prompt = 'Snippets> ',
    preview = function(selected)
      local snippet = lookup[selected[1]]
      if snippet then
        return snippet.url or 'No content'
      end
      return 'No preview available'
    end,
    actions = {
      ['default'] = function(selected)
        if #selected > 0 then
          local snippet = lookup[selected[1]]
          callback(snippet)
        end
      end
    }
  })
end

-- Built-in vim.ui.select based selector (fallback)
function M.show_builtin_selector(snippets, callback)
  local formatted_items = {}
  
  for _, snippet in ipairs(snippets) do
    local title = snippet.title or 'Untitled'
    local desc = snippet.description or ''
    local display_line = string.format("%d: %s", snippet.id, title)
    if desc ~= '' then
      display_line = display_line .. " | " .. desc
    end
    table.insert(formatted_items, { display = display_line, snippet = snippet })
  end
  
  vim.ui.select(formatted_items, {
    prompt = 'Select snippet:',
    format_item = function(item) return item.display end
  }, function(choice)
    if choice then
      callback(choice.snippet)
    else
      callback(nil)
    end
  end)
end

-- Open snippet editor in vsplit
function M.open_snippet_editor(snippet, callback)
  local cfg = config.get()
  
  -- Create new buffer for editing
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'bkmr')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Generate template content
  local content = M.generate_template(snippet)
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  
  -- Create window
  local win_config = M.get_window_config(cfg)
  local win
  
  if cfg.ui.split_direction == "vertical" then
    vim.cmd('vsplit')
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_width(win, cfg.ui.split_size)
  else
    vim.cmd('split')
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(win, cfg.ui.split_size)
  end
  
  -- Set buffer in window
  vim.api.nvim_win_set_buf(win, buf)
  
  -- Set up buffer-local keymaps and autocommands
  M.setup_editor_buffer(buf, snippet, callback)
  
  -- Focus on content area (after template header)
  local content_start_line = M.find_content_start(content)
  vim.api.nvim_win_set_cursor(win, {content_start_line, 0})
  
  vim.notify('Editing snippet. Save with :w, quit with :q', vim.log.levels.INFO)
end

-- Generate template content for editing
function M.generate_template(snippet)
  local lines = {}
  
  if config.get().edit.template_header then
    -- Template header (similar to bkmr edit format)
    table.insert(lines, "# Title: " .. (snippet.title or ""))
    table.insert(lines, "# Description: " .. (snippet.description or ""))
    
    local tags_str = ""
    if snippet.tags and #snippet.tags > 0 then
      tags_str = table.concat(snippet.tags, ",")
    end
    table.insert(lines, "# Tags: " .. tags_str)
    table.insert(lines, "# Type: snip")
    table.insert(lines, "---")
  end
  
  -- Content section
  local content = snippet.url or ""
  if content ~= "" then
    local content_lines = vim.split(content, '\n', true)
    for _, line in ipairs(content_lines) do
      table.insert(lines, line)
    end
  end
  
  return lines
end

-- Parse template content back to snippet
function M.parse_template(lines)
  local snippet = {
    title = "",
    description = "",
    tags = {},
    url = ""
  }
  
  local in_content = false
  local content_lines = {}
  
  for _, line in ipairs(lines) do
    if line:match("^# Title: (.*)") then
      snippet.title = line:match("^# Title: (.*)")
    elseif line:match("^# Description: (.*)") then  
      snippet.description = line:match("^# Description: (.*)")
    elseif line:match("^# Tags: (.*)") then
      local tags_str = line:match("^# Tags: (.*)")
      if tags_str and tags_str ~= "" then
        snippet.tags = vim.split(tags_str, ",", true)
        -- Trim whitespace
        for i, tag in ipairs(snippet.tags) do
          snippet.tags[i] = tag:gsub("^%s*(.-)%s*$", "%1")
        end
      end
    elseif line == "---" then
      in_content = true
    elseif in_content then
      table.insert(content_lines, line)
    end
  end
  
  -- Join content lines
  snippet.url = table.concat(content_lines, '\n')
  
  return snippet
end

-- Setup editor buffer with keymaps and autocommands
function M.setup_editor_buffer(buf, original_snippet, callback)
  -- Buffer-local keymap for saving
  vim.api.nvim_buf_set_keymap(buf, 'n', '<leader>w', '', {
    callback = function()
      M.save_snippet(buf, original_snippet, callback)
    end,
    desc = 'Save snippet'
  })
  
  -- Custom save command
  vim.api.nvim_buf_create_user_command(buf, 'W', function()
    M.save_snippet(buf, original_snippet, callback)
  end, { desc = 'Save snippet' })
  
  -- Auto-save on write
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      M.save_snippet(buf, original_snippet, callback)
    end
  })
  
  -- Optional auto-save on buffer leave
  if config.get().edit.auto_save then
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = buf,
      callback = function()
        M.save_snippet(buf, original_snippet, callback)
      end
    })
  end
  
  -- Clean up when buffer is deleted
  vim.api.nvim_create_autocmd('BufDelete', {
    buffer = buf,
    once = true,
    callback = function()
      -- If callback wasn't called yet, call it with nil (cancelled)
      if callback then
        callback(nil)
      end
    end
  })
end

-- Save snippet from editor buffer
function M.save_snippet(buf, original_snippet, callback)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local parsed_snippet = M.parse_template(lines)
  
  -- Validate required fields
  if not parsed_snippet.title or parsed_snippet.title == "" then
    vim.notify('Title is required', vim.log.levels.ERROR)
    return
  end
  
  if not parsed_snippet.url or parsed_snippet.url == "" then
    vim.notify('Content is required', vim.log.levels.ERROR)
    return
  end
  
  -- Preserve original ID if editing existing snippet
  if original_snippet.id then
    parsed_snippet.id = original_snippet.id
  end
  
  -- Ensure _snip_ tag is present
  if not vim.tbl_contains(parsed_snippet.tags, '_snip_') then
    table.insert(parsed_snippet.tags, '_snip_')
  end
  
  -- Close editor buffer
  vim.api.nvim_buf_delete(buf, { force = true })
  
  -- Call callback with parsed snippet
  if callback then
    callback(parsed_snippet)
    -- Prevent multiple calls
    callback = nil
  end
end

-- Find content start line (after template header)
function M.find_content_start(lines)
  for i, line in ipairs(lines) do
    if line == "---" then
      return i + 1
    end
  end
  return #lines + 1
end

-- Get window configuration
function M.get_window_config(cfg)
  return {
    split_direction = cfg.ui.split_direction,
    split_size = cfg.ui.split_size
  }
end

return M