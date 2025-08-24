# bkmr.nvim

A comprehensive Neovim plugin for the [bkmr](https://github.com/sysid/bkmr) snippet manager. Provides seamless integration with the bkmr LSP server and a rich editing interface for managing snippets directly within Neovim.

## Features

- **LSP Integration**: Automatic setup with bkmr LSP server for snippet completion
- **Visual Snippet Management**: Browse and select snippets using fzf-lua
- **Rich Editing Interface**: Edit snippets in vsplit with template format similar to `bkmr edit`
- **Full CRUD Operations**: Create, read, update, and delete snippets via LSP commands
- **Language-Aware**: Automatic filtering based on current buffer filetype
- **Template Support**: Full support for bkmr's template variables and LSP snippet placeholders

## Requirements

- Neovim 0.8+
- [bkmr](https://github.com/sysid/bkmr) 4.24.0+ (with LSP support)
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for enhanced snippet selection
- Optional: [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) for automatic LSP setup

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "sysid/bkmr.nvim",
  dependencies = {
    "ibhagwan/fzf-lua",  -- Optional: for better snippet selection
    "neovim/nvim-lspconfig"  -- Optional: for automatic LSP setup
  },
  config = function()
    require('bkmr').setup({
      ui = {
        use_fzf = true,  -- Enable fzf-lua integration
      }
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'sysid/bkmr.nvim',
  requires = {
    'ibhagwan/fzf-lua',     -- Optional
    'neovim/nvim-lspconfig' -- Optional
  },
  config = function()
    require('bkmr').setup()
  end
}
```

## Configuration

Default configuration:

```lua
require('bkmr').setup({
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

- `:BkmrList [language]` - List all snippets (optionally filtered by language)
- `:BkmrEdit <id>` - Edit snippet by ID
- `:BkmrNew` - Create new snippet
- `:BkmrDelete <id>` - Delete snippet by ID
- `:BkmrSearch [query]` - Search snippets
- `:BkmrTags` - List available tags
- `:BkmrInsertPath` - Insert filepath comment at cursor

### Default Keymaps

The plugin provides optional default keymaps (disable with `vim.g.bkmr_no_default_mappings = true`):

- `<leader>bs` - List bkmr snippets
- `<leader>bn` - Create new snippet
- `<leader>bp` - Insert filepath comment

### Snippet Editing

When editing snippets, the interface mimics `bkmr edit` with a structured template:

```
# Title: My Snippet Title
# Description: Description of what this snippet does
# Tags: rust,function,_snip_
# Type: snip
---
fn hello_world() {
    println!("Hello, world!");
}
```

**Editing Controls:**
- Save: `:w` or `:W`
- Save and close: `:wq`
- Cancel: `:q` (without saving)
- The cursor automatically positions after the `---` line for content editing

### LSP Completion

The plugin automatically configures bkmr LSP completion. Snippets will appear in completion menus based on:

- Current buffer filetype (e.g., `.rs` files show Rust snippets)
- Universal snippets (tagged with "universal")
- Manual completion trigger (`<C-Space>` in most editors)

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

-- List snippets with callback
bkmr.list_snippets("rust")
```

## Troubleshooting

### LSP Not Starting

1. Verify bkmr is installed and in PATH: `which bkmr`
2. Check bkmr version: `bkmr --version` (should be 4.24.0+)
3. Test LSP manually: `bkmr lsp`

### No Completions

1. Ensure snippets exist: `bkmr search -t _snip_`
2. Check LSP client is attached: `:LspInfo`
3. Verify filetype mapping in configuration

### Snippet Selection Issues

1. If fzf-lua isn't working, install it or disable: `use_fzf = false`
2. For telescope users, set: `use_telescope = true, use_fzf = false`

### Template Parsing

The plugin expects bkmr edit format:
- Lines starting with `# Field:` are metadata
- `---` separator divides metadata from content
- Everything after `---` is snippet content

## Related Projects

- [bkmr](https://github.com/sysid/bkmr) - Command-line bookmark and snippet manager
- [bkmr-intellij-plugin](../bkmr-intellij-plugin) - IntelliJ Platform integration
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - Fuzzy finder for Neovim

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details.# bkmr-nvim
