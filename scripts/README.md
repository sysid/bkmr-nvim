# Test Scripts for bkmr.nvim

This directory contains test scripts for debugging and validating bkmr.nvim functionality.

## Scripts

### `test_minimal.lua`
Minimal automated test that loads the plugin and tests basic LSP commands.

**Usage:**
```bash
nvim --clean -u scripts/test_minimal.lua
```

**What it tests:**
- Plugin setup with debug enabled
- LSP client initialization  
- BkmrList (all snippets)
- BkmrList with language filter
- BkmrEdit for specific snippet

### `test_interactive.lua`
Interactive test environment for manual testing with helpful commands.

**Usage:**
```bash
nvim --clean -u scripts/test_interactive.lua
```

**Features:**
- Debug mode enabled
- Helper test commands (`:TestLspAvailable`, `:TestListAll`, etc.)
- Instructions for manual testing
- All plugin commands available

### `test_debug.lua`
Maximum verbosity test that shows all LSP communication and internal operations.

**Usage:**
```bash
nvim --clean -u scripts/test_debug.lua
```

**What it shows:**
- All debug messages
- LSP request/response details
- Error details with stack traces
- Step-by-step operation breakdown

### `test_lsp_commands.sh`
Shell script that validates prerequisites and runs automated tests.

**Usage:**
```bash
./scripts/test_lsp_commands.sh
```

**What it checks:**
- bkmr CLI availability and version
- Snippet database status
- LSP server responsiveness  
- Plugin loading and basic functionality

## Debugging Workflow

1. **Prerequisites Check:**
   ```bash
   ./scripts/test_lsp_commands.sh
   ```

2. **Basic Functionality:**
   ```bash
   nvim --clean -u scripts/test_minimal.lua
   ```

3. **Detailed Debugging:**
   ```bash
   nvim --clean -u scripts/test_debug.lua
   ```

4. **Manual Testing:**
   ```bash
   nvim --clean -u scripts/test_interactive.lua
   # Then use :BkmrList, :BkmrEdit, etc.
   ```

## Common Issues and Solutions

### "bkmr binary not found"
```bash
cargo install bkmr
```

### "No snippets found"  
```bash
bkmr add "echo 'test'" shell,_snip_ --title "test" --type snip
```

### "LSP not available"
- Check bkmr version: `bkmr --version` (need 4.24.0+)
- Test LSP server: `bkmr lsp` (should start without errors)
- Check Neovim LSP logs: `:LspLog`

### "Invalid tag: Tag cannot be empty"
This indicates parameter formatting issues with the LSP server. Enable debug mode to see the actual request/response.

## Debug Mode

All test scripts enable debug mode by default. You can also enable it in your regular config:

```lua
require('bkmr').setup({
  debug = true  -- Shows detailed LSP communication
})
```