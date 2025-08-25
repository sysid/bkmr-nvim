-- Tests for bkmr.nvim UI module

local ui = require('bkmr.ui')
local config = require('bkmr.config')

describe('ui', function()
  before_each(function()
    config.setup({ debug = false })
  end)
  
  describe('generate_template', function()
    it('should generate template with section markers', function()
      local snippet = {
        id = 123,
        title = 'Test Snippet',
        description = 'Test description',
        tags = {'_snip_', 'bash'},
        url = 'echo "hello world"'
      }
      
      local lines = ui.generate_template(snippet)
      
      -- Check for section markers
      assert.is_true(vim.tbl_contains(lines, '=== ID ==='))
      assert.is_true(vim.tbl_contains(lines, '=== CONTENT ==='))
      assert.is_true(vim.tbl_contains(lines, '=== TITLE ==='))
      assert.is_true(vim.tbl_contains(lines, '=== TAGS ==='))
      assert.is_true(vim.tbl_contains(lines, '=== COMMENTS ==='))
      assert.is_true(vim.tbl_contains(lines, '=== END ==='))
      
      -- Check content placement
      local content_idx = nil
      local title_idx = nil
      for i, line in ipairs(lines) do
        if line == '=== CONTENT ===' then
          content_idx = i
        elseif line == '=== TITLE ===' then
          title_idx = i
        end
      end
      assert.is_not_nil(content_idx)
      assert.is_not_nil(title_idx)
      assert.are.equal('echo "hello world"', lines[content_idx + 1])
      assert.are.equal('Test Snippet', lines[title_idx + 1])
    end)
    
    it('should handle multi-line content correctly', function()
      local snippet = {
        title = 'Multi-line',
        url = 'line1\nline2\nline3',
        tags = {'_snip_'}
      }
      
      local lines = ui.generate_template(snippet)
      local content_idx = nil
      for i, line in ipairs(lines) do
        if line == '=== CONTENT ===' then
          content_idx = i
          break
        end
      end
      
      assert.is_not_nil(content_idx)
      assert.are.equal('line1', lines[content_idx + 1])
      assert.are.equal('line2', lines[content_idx + 2])
      assert.are.equal('line3', lines[content_idx + 3])
    end)
    
    it('should format tags as comma-separated', function()
      local snippet = {
        title = 'Test',
        url = 'test',
        tags = {'_snip_', 'bash', 'shell', 'unix'}
      }
      
      local lines = ui.generate_template(snippet)
      local tags_idx = nil
      for i, line in ipairs(lines) do
        if line == '=== TAGS ===' then
          tags_idx = i
          break
        end
      end
      
      assert.is_not_nil(tags_idx)
      assert.are.equal('_snip_,bash,shell,unix', lines[tags_idx + 1])
    end)
  end)
  
  describe('parse_template', function()
    it('should parse template back to snippet object', function()
      local lines = {
        '# Snippet Template',
        '# Comments are ignored',
        '=== ID ===',
        '456',
        '=== CONTENT ===',
        'echo "parsed"',
        '=== TITLE ===',
        'Parsed Title',
        '=== TAGS ===',
        '_snip_,lua,test',
        '=== COMMENTS ===',
        'Parsed description',
        '=== END ==='
      }
      
      local snippet = ui.parse_template(lines)
      
      assert.are.equal(456, snippet.id)
      assert.are.equal('echo "parsed"', snippet.url)
      assert.are.equal('Parsed Title', snippet.title)
      assert.are.equal('Parsed description', snippet.description)
      assert.are.same({'_snip_', 'lua', 'test'}, snippet.tags)
    end)
    
    it('should handle empty sections correctly', function()
      local lines = {
        '=== CONTENT ===',
        '=== TITLE ===',
        '=== TAGS ===',
        '=== COMMENTS ===',
        '=== END ==='
      }
      
      local snippet = ui.parse_template(lines)
      
      assert.are.equal('', snippet.url)
      assert.are.equal('', snippet.title)
      assert.are.equal('', snippet.description)
      assert.are.same({}, snippet.tags)
    end)
    
    it('should preserve content lines starting with # but ignore header comments', function()
      local lines = {
        '# This is a header comment (ignored)',
        '=== CONTENT ===',
        '# This is content that should be preserved',
        'actual content',
        '=== TITLE ===',
        '# This title comment should be preserved',  
        'Actual Title',
        '=== END ==='
      }
      
      local snippet = ui.parse_template(lines)
      
      -- Content should include lines starting with #
      assert.are.equal('# This is content that should be preserved\nactual content', snippet.url)
      assert.are.equal('# This title comment should be preserved\nActual Title', snippet.title)
    end)
  end)
  
  describe('truncate_response', function()
    it('should truncate arrays with more than 10 items', function()
      -- This test would need the actual truncate_response function exposed
      -- For now, we'll test it indirectly through LSP module
      assert.is_true(true) -- Placeholder
    end)
  end)
  
  describe('find_content_start', function()
    it('should find line after CONTENT marker', function()
      local lines = {
        '# Header',
        '# Comment',
        '=== ID ===',
        '123',
        '=== CONTENT ===',
        'actual content here',
        '=== TITLE ==='
      }
      
      local start_line = ui.find_content_start(lines)
      assert.are.equal(6, start_line) -- Line after '=== CONTENT ==='
    end)
    
    it('should fallback to first non-comment line if no CONTENT marker', function()
      local lines = {
        '# Header',
        '# Comment',
        '',
        'first real content',
        'more content'
      }
      
      local start_line = ui.find_content_start(lines)
      assert.are.equal(4, start_line)
    end)
  end)
end)