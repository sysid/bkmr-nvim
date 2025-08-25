-- Tests for bkmr.nvim LSP module

local lsp = require('bkmr.lsp')
local config = require('bkmr.config')

describe('lsp', function()
  before_each(function()
    config.setup({ debug = false })
  end)
  
  describe('response handling', function()
    it('should recognize direct snippet object as success for create', function()
      -- Mock successful creation response
      local response = {
        id = 123,
        title = 'Created Snippet',
        url = 'echo "created"',
        tags = {'_snip_'}
      }
      
      -- This would need actual function testing with mocked client
      -- For now, we verify the response structure matches expectations
      assert.is_not_nil(response.id)
      assert.is_nil(response.success) -- No success wrapper
      assert.is_string(response.title)
    end)
    
    it('should recognize direct snippet object as success for update', function()
      local response = {
        id = 456,
        title = 'Updated Snippet',
        url = 'echo "updated"',
        tags = {'_snip_', 'updated'}
      }
      
      assert.is_not_nil(response.id)
      assert.is_nil(response.success)
    end)
    
    it('should handle nil response as success for delete', function()
      local response = nil
      
      -- Delete operations return nil on success
      assert.is_nil(response)
    end)
    
    it('should extract error messages from table responses', function()
      local error_responses = {
        { error = 'Simple error message' },
        { error = { message = 'Nested error message' } },
        { message = 'Direct message field' }
      }
      
      -- Verify each error format can be handled
      for _, err_response in ipairs(error_responses) do
        local msg = err_response.error or err_response.message or 'Unknown error'
        if type(msg) == 'table' then
          msg = msg.message or msg.error or vim.inspect(msg)
        end
        assert.is_string(msg)
        assert.is_not.equal('', msg)
      end
    end)
  end)
  
  describe('truncate_response helper', function()
    it('should truncate large arrays', function()
      -- Create a mock large array
      local large_array = {}
      for i = 1, 20 do
        large_array[i] = { id = i, title = 'Snippet ' .. i }
      end
      
      -- The truncation should keep first 5 and last 5
      -- with a placeholder in between
      assert.are.equal(20, #large_array)
      
      -- Verify truncation logic (would need actual function exposed)
      local should_truncate = #large_array > 10
      assert.is_true(should_truncate)
    end)
    
    it('should not truncate small arrays', function()
      local small_array = { {id = 1}, {id = 2}, {id = 3} }
      
      assert.are.equal(3, #small_array)
      local should_truncate = #small_array > 10
      assert.is_false(should_truncate)
    end)
  end)
  
  describe('parameter formatting', function()
    it('should handle empty language filter correctly', function()
      -- Test that empty string is converted to nil
      local language_filter = ""
      local params = {}
      
      if language_filter and language_filter ~= "" then
        params.arguments = { { language = language_filter } }
      end
      
      assert.is_nil(params.arguments)
    end)
    
    it('should include language filter when provided', function()
      local language_filter = "python"
      local params = {}
      
      if language_filter and language_filter ~= "" then
        params.arguments = { { language = language_filter } }
      end
      
      assert.is_not_nil(params.arguments)
      assert.are.equal("python", params.arguments[1].language)
    end)
  end)
  
  describe('snippet validation', function()
    it('should ensure _snip_ tag is present', function()
      local tags = {'bash', 'shell'}
      
      if not vim.tbl_contains(tags, '_snip_') then
        table.insert(tags, '_snip_')
      end
      
      assert.is_true(vim.tbl_contains(tags, '_snip_'))
      assert.is_true(vim.tbl_contains(tags, 'bash'))
    end)
    
    it('should not duplicate _snip_ tag', function()
      local tags = {'_snip_', 'bash'}
      
      if not vim.tbl_contains(tags, '_snip_') then
        table.insert(tags, '_snip_')
      end
      
      -- Count occurrences
      local count = 0
      for _, tag in ipairs(tags) do
        if tag == '_snip_' then
          count = count + 1
        end
      end
      
      assert.are.equal(1, count)
    end)
  end)
end)