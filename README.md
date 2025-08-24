# bkmr-nvim

A comprehensive Neovim plugin for the [bkmr](https://github.com/sysid/bkmr) snippet manager.
Provides seamless integration with the bkmr LSP server and a rich editing interface for managing
snippets directly within Neovim.

## Features

- **LSP Integration**: Automatic setup with bkmr LSP server for snippet completion
- **Visual Snippet Management**: Browse and select snippets using fzf-lua or builtin selector
- **Rich Editing Interface**: Edit snippets in vsplit with template format matching `bkmr edit`

## Requirements

- Neovim 0.8+
- [bkmr](https://github.com/sysid/bkmr) 4.24.0+ (with LSP support)
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for enhanced snippet selection
- Optional: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) for automatic LSP setup

### Development Requirements

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for running tests

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "sysid/bkmr-nvim",
  dependencies = {
    "ibhagwan/fzf-lua",  -- Optional: for better snippet selection
    "neovim/nvim-lspconfig"  -- Optional: for automatic LSP setup
  },
  config = function()
    require('bkmr').setup({
      debug = false,  -- Enable debug logging
      ui = {
        use_fzf = true,  -- Enable fzf-lua integration
      }
    })
  end
}
```

## Configuration

Default configuration:

```lua
require('bkmr').setup({
  debug = false,                           -- Enable debug logging
  lsp = {
    auto_setup = true,                    -- Auto-configure with lspconfig
    cmd = { "bkmr", "lsp" },             -- LSP server command
    filetypes = {                        -- Supported file types
      'rust', 'javascript', 'typescript', 'python', 'go', 'java', 'c', 'cpp',
      'html', 'css', 'scss', 'ruby', 'php', 'swift', 'kotlin', 'shell', 'sh',
      'bash', 'yaml', 'json', 'markdown', 'xml', 'vim', 'lua', 'toml'
    }
  },
  ui = {
    split_direction = "vertical",         -- "horizontal" | "vertical"
    split_size = 80,                     -- Split width/height
    use_telescope = false,               -- Use telescope for selection
    use_fzf = true,                      -- Use fzf-lua for selection
  },
  edit = {
    auto_save = false,                   -- Auto-save on buffer leave
    confirm_delete = true,               -- Confirm before deletion
    template_header = true,              -- Show template header in edit buffer
  }
})
```

### Manual LSP Setup

If you prefer manual LSP configuration or don't have nvim-lspconfig:

```lua
require('bkmr').setup({
  lsp = {
    auto_setup = false  -- Disable automatic setup
  }
})

-- Then manually configure with nvim-lspconfig:
require('lspconfig').bkmr_lsp.setup({
  cmd = { "bkmr", "lsp" },
  filetypes = { "rust", "python", "javascript" }, -- your preferred filetypes
})
```

## Usage

### Commands

- `:BkmrEdit [language]` - Browse and edit snippets (defaults to current buffer's filetype if not specified)
- `:BkmrNew` - Create new snippet
- `:BkmrDelete <id>` - Delete snippet by ID

When using `:BkmrEdit`, you can browse available snippets and select one to edit.

### Snippet Editing

When editing snippets, the interface uses section markers matching `bkmr edit`:

```
# Snippet Template
# Lines starting with '#' are comments and will be ignored.
# Section markers (=== SECTION_NAME ===) are required and must not be removed.

=== ID ===
123

=== CONTENT ===
echo "Hello, World!"
echo "This is my snippet content"

=== TITLE ===
My Example Snippet

=== TAGS ===
_snip_,bash,shell

=== COMMENTS ===
This snippet demonstrates the editing format

=== END ===
```

**Editing Controls:**
- Save: `:w` or `:W`
- Save and close: `:wq`
- Cancel: `:q` (without saving)
- The cursor automatically positions at the content section

### LSP Completion

The plugin automatically configures bkmr LSP completion. Snippets will appear in completion menus based on:

- Current buffer filetype (e.g., `.rs` files show Rust snippets)
- Universal snippets (tagged with appropriate tags)
- Manual completion trigger (varies by completion plugin)

## Debug Mode

Enable debug mode to see detailed LSP communication:

```lua
require('bkmr').setup({
  debug = true
})
```

Debug features:
- All LSP requests and responses are logged
- Large responses (>10 items) are automatically truncated in logs
- Error messages are properly extracted from various response formats
- Use `:messages` to view debug output

## API

The plugin provides a Lua API for integration with other plugins:

```lua
local bkmr = require('bkmr')

-- Check if LSP is available
if bkmr.is_lsp_available() then
  -- Get current context
  local context = bkmr.get_context()
  print(context.filetype)
end

-- Programmatically create snippet
bkmr.new_snippet()

-- List snippets with language filter
bkmr.list_snippets("rust")

-- Delete snippet
bkmr.delete_snippet(456)

-- Note: edit_snippet is used internally when selecting from list
```

## Testing

The plugin includes a comprehensive test suite using plenary.nvim. Tests cover configuration management, UI template generation/parsing, and LSP response handling.

### Prerequisites

Install plenary.nvim with your package manager:
```lua
-- Using lazy.nvim
{ 'nvim-lua/plenary.nvim' }

-- Using packer.nvim
use 'nvim-lua/plenary.nvim'
```

### Running Tests

```bash
# Run all tests (24 tests across 3 modules)
make test

# Run tests interactively in Neovim
make test-interactive

# Run specific test file
make test-file FILE=test_ui.lua

# Manual testing with debug scripts
make test-manual
```

### Test Coverage

- **test_config.lua**: Configuration defaults, merging, and LSP config generation
- **test_ui.lua**: Template generation with section markers, parsing, response truncation
- **test_lsp.lua**: Response handling, error extraction, parameter formatting

## Troubleshooting

### LSP Not Starting

1. Verify bkmr is installed and in PATH: `which bkmr`
2. Check bkmr version: `bkmr --version` (should be 4.24.0+)
3. Test LSP manually: `bkmr lsp`
4. Enable debug mode to see detailed logs

### No Completions

1. Ensure snippets exist: `bkmr list`
2. Check LSP client is attached: `:LspInfo`
3. Verify filetype mapping in configuration
4. Try browsing snippets: `:BkmrEdit`

### Snippet Selection Issues

1. If fzf-lua isn't working, install it or disable: `use_fzf = false`
2. For telescope users (not yet implemented), set: `use_telescope = true, use_fzf = false`
3. Falls back to builtin vim.ui.select if neither is available

### Template Parsing Issues

The plugin uses section markers for editing:
- Sections start with `=== SECTION_NAME ===`
- Required sections: CONTENT, TITLE, TAGS, COMMENTS
- Lines starting with `#` are treated as comments
- The `_snip_` tag is automatically added if missing

### Common Errors

**"Failed to create/update snippet: Unknown error"**
- The LSP server returns the snippet object directly on success
- This is normal behavior and the snippet is actually saved

**"E382: Cannot write, 'buftype' option is set"**
- This has been fixed - the buffer type is now 'acwrite'
- Save with `:w` should work properly

**"Invalid tag: Tag cannot be empty"**
- Empty language filters are now properly handled
- Use `:BkmrList` without arguments to list all snippets

## Development

### Project Structure

```
bkmr.nvim/
├── lua/bkmr/
│   ├── init.lua       # Main plugin entry point
│   ├── config.lua     # Configuration management
│   ├── lsp.lua        # LSP client integration
│   └── ui.lua         # UI components and editing
├── plugin/
│   └── bkmr.lua       # Vim plugin loader
├── syntax/
│   └── bkmr.vim       # Syntax highlighting for edit buffers
├── tests/             # Test suite
│   ├── test_config.lua
│   ├── test_ui.lua
│   └── test_lsp.lua
└── scripts/           # Testing scripts
    ├── test_minimal.lua
    ├── test_interactive.lua
    └── test_debug.lua
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Run tests: `make test`
5. Submit a pull request

## Related Projects

- [bkmr](https://github.com/sysid/bkmr) - Command-line bookmark and snippet manager
- [bkmr-lsp](../bkmr-lsp) - LSP server implementation (integrated into bkmr 4.24.0+)
- [bkmr-intellij-plugin](../bkmr-intellij-plugin) - IntelliJ Platform integration

## License

MIT License - see LICENSE file for details.
