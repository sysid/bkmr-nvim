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
  vim.api.nvim_buf_set_option(buf, 'buftype', 'acwrite')  -- Allow custom write
  vim.api.nvim_buf_set_option(buf, 'filetype', 'bkmr')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  
  -- Set a meaningful name for the buffer
  local buf_name = snippet.id and 
    string.format('bkmr://snippet/%d', snippet.id) or 
    'bkmr://snippet/new'
  vim.api.nvim_buf_set_name(buf, buf_name)
  
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
    -- Template header matching bkmr edit format
    table.insert(lines, "# Snippet Template")
    table.insert(lines, "# Section markers (=== SECTION_NAME ===) are required and must not be removed.")
    table.insert(lines, "")
    
    -- ID section
    if snippet.id then
      table.insert(lines, "=== ID ===")
      table.insert(lines, tostring(snippet.id))
    end
    
    -- CONTENT section (not URL for snippets)
    table.insert(lines, "=== CONTENT ===")
    local content = snippet.url or ""
    if content ~= "" then
      local content_lines = vim.split(content, '\n', true)
      for _, line in ipairs(content_lines) do
        table.insert(lines, line)
      end
    end
    
    -- TITLE section
    table.insert(lines, "=== TITLE ===")
    table.insert(lines, snippet.title or "")
    
    -- TAGS section
    table.insert(lines, "=== TAGS ===")
    local tags_str = ""
    if snippet.tags and #snippet.tags > 0 then
      tags_str = table.concat(snippet.tags, ",")
    end
    table.insert(lines, tags_str)
    
    -- COMMENTS section (description)
    table.insert(lines, "=== COMMENTS ===")
    table.insert(lines, snippet.description or "")
    
    -- END marker
    table.insert(lines, "=== END ===")
  else
    -- Simple format without template header
    local content = snippet.url or ""
    if content ~= "" then
      local content_lines = vim.split(content, '\n', true)
      for _, line in ipairs(content_lines) do
        table.insert(lines, line)
      end
    end
  end
  
  return lines
end

-- Parse template content back to snippet
function M.parse_template(lines)
  local snippet = {
    id = nil,
    title = "",
    description = "",
    tags = {},
    url = ""
  }
  
  local current_section = nil
  local section_content = {}
  
  for _, line in ipairs(lines) do
    -- Check for section markers
    if line:match("^=== (%w+) ===$") then
      -- Save previous section content if any
      if current_section then
        M.save_section_content(snippet, current_section, section_content)
        section_content = {}
      end
      current_section = line:match("^=== (%w+) ===$")
    elseif current_section and current_section ~= "END" then
      -- Add all lines within sections (including those starting with #)
      table.insert(section_content, line)
    end
    -- Lines outside sections (template header comments) are ignored
  end
  
  -- Save last section if any
  if current_section and current_section ~= "END" then
    M.save_section_content(snippet, current_section, section_content)
  end
  
  return snippet
end

-- Helper function to save section content to snippet
function M.save_section_content(snippet, section, content)
  local content_str = table.concat(content, '\n'):gsub("^%s*(.-)%s*$", "%1")
  
  if section == "ID" then
    snippet.id = tonumber(content_str)
  elseif section == "CONTENT" then
    snippet.url = content_str
  elseif section == "TITLE" then
    snippet.title = content_str
  elseif section == "TAGS" then
    if content_str and content_str ~= "" then
      snippet.tags = vim.split(content_str, ",", true)
      -- Trim whitespace from each tag
      for i, tag in ipairs(snippet.tags) do
        snippet.tags[i] = tag:gsub("^%s*(.-)%s*$", "%1")
      end
    end
  elseif section == "COMMENTS" then
    snippet.description = content_str
  end
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
    return false
  end
  
  if not parsed_snippet.url or parsed_snippet.url == "" then
    vim.notify('Content is required', vim.log.levels.ERROR)
    return false
  end
  
  -- Preserve original ID if editing existing snippet
  if original_snippet.id then
    parsed_snippet.id = original_snippet.id
  end
  
  -- Ensure _snip_ tag is present
  if not vim.tbl_contains(parsed_snippet.tags, '_snip_') then
    table.insert(parsed_snippet.tags, '_snip_')
  end
  
  -- Mark buffer as saved (prevents E382)
  vim.api.nvim_buf_set_option(buf, 'modified', false)
  
  -- Notify user that save is in progress
  vim.notify('Saving snippet...', vim.log.levels.INFO)
  
  -- Call callback with parsed snippet (the actual save happens here)
  if callback then
    callback(parsed_snippet)
    -- Don't close buffer here - let the callback handle it after successful save
  end
  
  return true
end

-- Find content start line (after template header)
function M.find_content_start(lines)
  for i, line in ipairs(lines) do
    if line == "=== CONTENT ===" then
      -- Position cursor on the line after the CONTENT marker
      return i + 1
    end
  end
  -- Fallback to first non-comment line
  for i, line in ipairs(lines) do
    if not line:match("^#") and not line:match("^===") and line ~= "" then
      return i
    end
  end
  return 5  -- Default to line 5 (after header comments)
end

-- Get window configuration
function M.get_window_config(cfg)
  return {
    split_direction = cfg.ui.split_direction,
    split_size = cfg.ui.split_size
  }
end

return M