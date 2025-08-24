-- File type detection for bkmr snippet editing buffers

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*",
  callback = function()
    -- Check if this is a bkmr editing buffer
    local bufname = vim.api.nvim_buf_get_name(0)
    local buf_ft = vim.bo.filetype
    
    -- Set filetype for bkmr editing buffers
    if buf_ft == 'bkmr' or bufname:match('bkmr_edit_') then
      vim.bo.filetype = 'bkmr'
    end
  end
})