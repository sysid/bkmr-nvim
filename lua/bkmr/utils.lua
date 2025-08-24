-- Utility functions for bkmr.nvim

local M = {}

-- Split string by delimiter
function M.split(str, delimiter)
  local result = {}
  local pattern = string.format("([^%s]+)", delimiter)
  for match in string.gmatch(str, pattern) do
    table.insert(result, match)
  end
  return result
end

-- Trim whitespace from string
function M.trim(str)
  if not str then return "" end
  return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

-- Check if table contains value
function M.table_contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

-- Deep copy table
function M.deep_copy(orig)
  local copy
  if type(orig) == 'table' then
    copy = {}
    for k, v in next, orig, nil do
      copy[M.deep_copy(k)] = M.deep_copy(v)
    end
    setmetatable(copy, M.deep_copy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Get current buffer file type
function M.get_filetype()
  return vim.bo.filetype
end

-- Get current buffer URI
function M.get_buffer_uri()
  return vim.uri_from_bufnr(0)
end

-- Get current cursor position
function M.get_cursor_position()
  return vim.api.nvim_win_get_cursor(0)
end

-- Safe notify with level
function M.notify(msg, level)
  level = level or vim.log.levels.INFO
  vim.notify(msg, level)
end

-- Format snippet for display
function M.format_snippet_display(snippet)
  local title = snippet.title or 'Untitled'
  local desc = snippet.description or ''
  local tags_str = table.concat(snippet.tags or {}, ',')
  
  local display_line = string.format("%d: %s", snippet.id, title)
  if desc ~= '' then
    display_line = display_line .. " | " .. desc
  end
  if tags_str ~= '' then
    display_line = display_line .. " | [" .. tags_str .. "]"
  end
  
  return display_line
end

-- Validate snippet data
function M.validate_snippet(snippet)
  if not snippet then
    return false, "Snippet is nil"
  end
  
  if not snippet.title or snippet.title == "" then
    return false, "Title is required"
  end
  
  if not snippet.url or snippet.url == "" then
    return false, "Content (url field) is required"
  end
  
  -- Ensure tags is an array
  if not snippet.tags then
    snippet.tags = {}
  elseif type(snippet.tags) ~= "table" then
    return false, "Tags must be an array"
  end
  
  -- Ensure _snip_ tag is present
  if not M.table_contains(snippet.tags, '_snip_') then
    table.insert(snippet.tags, '_snip_')
  end
  
  return true, nil
end

-- Get project root directory
function M.get_project_root()
  local cwd = vim.fn.getcwd()
  
  -- Try to find git root
  local git_root = vim.fn.systemlist("git -C " .. cwd .. " rev-parse --show-toplevel")[1]
  if git_root and git_root ~= "" then
    return git_root
  end
  
  -- Fallback to current working directory
  return cwd
end

-- Check if command exists
function M.command_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Get relative path from project root
function M.get_relative_path(filepath)
  filepath = filepath or vim.fn.expand('%:p')
  local root = M.get_project_root()
  
  -- Remove root path from filepath
  if filepath:sub(1, #root) == root then
    return filepath:sub(#root + 2) -- +2 to remove leading slash
  end
  
  return filepath
end

-- Escape string for use in patterns
function M.escape_pattern(str)
  return str:gsub("([^%w])", "%%%1")
end

-- Create unique temporary filename
function M.create_temp_file(prefix, suffix)
  prefix = prefix or "bkmr"
  suffix = suffix or ".tmp"
  
  local temp_dir = vim.fn.tempname()
  return temp_dir .. prefix .. suffix
end

-- Safe file reading
function M.read_file(filepath)
  local file = io.open(filepath, 'r')
  if not file then
    return nil, "Could not open file: " .. filepath
  end
  
  local content = file:read('*a')
  file:close()
  
  return content, nil
end

-- Safe file writing
function M.write_file(filepath, content)
  local file = io.open(filepath, 'w')
  if not file then
    return false, "Could not open file for writing: " .. filepath
  end
  
  file:write(content)
  file:close()
  
  return true, nil
end

-- Get language mapping for bkmr
function M.get_language_mapping(filetype)
  local mappings = {
    javascript = "javascript",
    typescript = "typescript",
    python = "python",
    rust = "rust",
    go = "go",
    java = "java",
    c = "c",
    cpp = "cpp",
    lua = "lua",
    vim = "vim",
    sh = "shell",
    bash = "shell",
    zsh = "shell",
    yaml = "yaml",
    yml = "yaml",
    json = "json",
    markdown = "markdown",
    md = "markdown",
    html = "html",
    css = "css",
    scss = "scss",
    ruby = "ruby",
    php = "php",
    swift = "swift",
    kotlin = "kotlin",
    xml = "xml",
    toml = "toml"
  }
  
  return mappings[filetype] or filetype
end

-- Debug logging
function M.debug_log(msg, data)
  if vim.g.bkmr_debug then
    local log_msg = "[bkmr.nvim] " .. msg
    if data then
      log_msg = log_msg .. " | " .. vim.inspect(data)
    end
    print(log_msg)
  end
end

-- Measure execution time
function M.time_it(func, name)
  name = name or "function"
  local start_time = vim.loop.hrtime()
  
  local result = func()
  
  local end_time = vim.loop.hrtime()
  local duration_ms = (end_time - start_time) / 1000000
  
  M.debug_log(string.format("%s took %.2fms", name, duration_ms))
  
  return result
end

return M