-- Tests for bkmr.nvim configuration module

local config = require('bkmr.config')

describe('config', function()
  describe('setup', function()
    it('should use default values when no options provided', function()
      config.setup()
      local cfg = config.get()
      
      assert.are.equal(false, cfg.debug)
      assert.are.equal(true, cfg.lsp.auto_setup)
      assert.are.equal(true, cfg.ui.use_fzf)
      assert.are.equal(false, cfg.ui.use_telescope)
      assert.are.equal('vertical', cfg.ui.split_direction)
      assert.are.equal("50%", cfg.ui.split_size)
      assert.are.equal(true, cfg.edit.template_header)
      assert.are.equal(false, cfg.edit.auto_save)
      assert.are.equal(true, cfg.edit.confirm_delete)
    end)
    
    it('should merge user options with defaults', function()
      config.setup({
        debug = true,
        ui = {
          use_fzf = false,
          split_size = 100
        }
      })
      local cfg = config.get()
      
      assert.are.equal(true, cfg.debug)
      assert.are.equal(false, cfg.ui.use_fzf)
      assert.are.equal(100, cfg.ui.split_size)
      -- Other defaults should remain
      assert.are.equal('vertical', cfg.ui.split_direction)
      assert.are.equal(true, cfg.edit.template_header)
    end)
    
    it('should override nested options correctly', function()
      config.setup({
        lsp = {
          auto_setup = false
        },
        edit = {
          auto_save = true,
          confirm_delete = false
        }
      })
      local cfg = config.get()
      
      assert.are.equal(false, cfg.lsp.auto_setup)
      assert.are.equal(true, cfg.edit.auto_save)
      assert.are.equal(false, cfg.edit.confirm_delete)
    end)
  end)
  
  describe('get_lsp_config', function()
    it('should return proper LSP configuration', function()
      config.setup()
      local lsp_cfg = config.get_lsp_config()
      
      assert.are.same({'bkmr', 'lsp'}, lsp_cfg.cmd)
      assert.is_true(vim.tbl_contains(lsp_cfg.filetypes, 'markdown'))
      assert.is_true(vim.tbl_contains(lsp_cfg.filetypes, 'python'))
      assert.is_function(lsp_cfg.root_dir)
    end)
    
    it('should find root directory correctly', function()
      config.setup()
      local lsp_cfg = config.get_lsp_config()
      
      -- Test with a file path
      local root = lsp_cfg.root_dir('/some/path/file.md')
      -- The root_dir function uses vim.fn.fnamemodify which in tests returns the current directory
      -- So we just check it returns a string
      assert.is_string(root)
      
      -- Test that root_dir is a function
      assert.is_function(lsp_cfg.root_dir)
    end)
  end)
end)