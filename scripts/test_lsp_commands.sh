#!/bin/bash

# Test bkmr.nvim LSP commands directly
# This script tests the plugin functionality step by step

set -e

cd "$(dirname "$0")/.."

echo "=== bkmr.nvim LSP Command Test ==="

# Check prerequisites
echo "1. Checking prerequisites..."
if ! command -v bkmr &> /dev/null; then
    echo "❌ bkmr CLI not found. Install with: cargo install bkmr"
    exit 1
fi

echo "✅ bkmr CLI found: $(bkmr --version)"

# Check if snippets exist
echo "2. Checking for snippets..."
snippet_count=$(bkmr search -t _snip_ --json | jq '. | length' 2>/dev/null || echo "0")
echo "Found $snippet_count snippets with _snip_ tag"

if [ "$snippet_count" -eq "0" ]; then
    echo "⚠️  No snippets found. Creating a test snippet..."
    bkmr add "echo 'Hello from bkmr.nvim test'" shell,_snip_ --title "test-snippet" --type snip
    echo "✅ Test snippet created"
fi

# Test LSP server directly
echo "3. Testing LSP server availability..."
timeout 3s bkmr lsp < /dev/null && echo "✅ LSP server responds" || echo "⚠️  LSP server test timeout (normal)"

# Test plugin with minimal config
echo "4. Testing plugin with minimal config..."
nvim --clean -u scripts/test_minimal.lua -c "sleep 8" -c "qa"

echo "✅ LSP command test completed"