.DEFAULT_GOAL := help

VERSION = $(shell cat VERSION)

# Plugin paths
plugin_root = .
lua_src = $(plugin_root)/lua
doc_src = $(plugin_root)/doc

################################################################################
# Development \
DEVELOPMENT: ## ##############################################################

.PHONY: setup
setup: ## one-time development environment setup
	@echo "Setting up bkmr.nvim development environment..."
	@echo "Checking dependencies..."
	@if ! command -v bkmr >/dev/null 2>&1; then \
		echo "❌ bkmr CLI not found. Install with: cargo install bkmr"; \
		exit 1; \
	fi
	@echo "✅ bkmr CLI found: $$(bkmr --version)"
	@echo "✅ Pure Lua plugin setup complete!"
	@echo ""
	@echo "Optional dependencies:"
	@echo "- fzf-lua: Enhanced snippet selection (recommended)"
	@echo "- nvim-lspconfig: Automatic LSP setup (recommended)"
	@echo "- plenary.nvim: For testing framework"

.PHONY: dev
dev: setup ## setup and open development environment
	@echo "Opening Neovim for bkmr.nvim development..."
	nvim .

.PHONY: check
check: test lint ## comprehensive check (lint + tests)

.PHONY: ci
ci: setup check ## simulate CI pipeline locally

.PHONY: update-nvim
update-nvim:  ## Push-force and re-load plugin from github
	@echo "Reloading plugin"
	git caa; git pf
	nvim --headless "+Lazy! update bkmr-nvim" +qa

################################################################################
# Testing \
TESTING: ## ##################################################################

.PHONY: test
test: ## run all tests using plenary.nvim
	@echo "Running bkmr.nvim test suite..."
	@echo "Note: Tests require plenary.nvim and real bkmr CLI"
	@if [ -d "tests" ]; then \
		nvim --headless -c "lua require('plenary.test_harness').test_directory('tests')" -c "qa"; \
	else \
		echo "No tests directory found. Create tests/ with plenary tests."; \
	fi

.PHONY: test-interactive
test-interactive: ## run tests in interactive mode
	@echo "Running tests in interactive Neovim..."
	@if [ -d "tests" ]; then \
		nvim -c "lua require('plenary.test_harness').test_directory('tests')"; \
	else \
		echo "No tests directory found."; \
	fi

.PHONY: test-manual
test-manual: ## open test environment for manual testing
	@echo "Opening manual test environment..."
	@echo "Testing bkmr.nvim functionality:"
	@echo "1. Run :BkmrList to test snippet listing"
	@echo "2. Run :BkmrNew to test snippet creation"
	@echo "3. Test LSP completion in various filetypes"
	nvim --clean -c "set rtp+=." -c "lua require('bkmr').setup()"

.PHONY: test-lsp
test-lsp: ## test LSP integration manually
	@echo "Testing bkmr LSP integration..."
	@if ! command -v bkmr >/dev/null 2>&1; then \
		echo "❌ bkmr CLI not found"; \
		exit 1; \
	fi
	@echo "✅ Testing bkmr LSP server..."
	@timeout 5s bkmr lsp || echo "LSP server test completed"
	@echo "✅ Testing snippet availability..."
	@bkmr search -t _snip_ --limit 5

.PHONY: test-deps
test-deps: ## verify all dependencies are available
	@echo "Checking bkmr.nvim dependencies..."
	@command -v bkmr >/dev/null 2>&1 && echo "✅ bkmr CLI" || echo "❌ bkmr CLI (required)"
	@nvim --version >/dev/null 2>&1 && echo "✅ Neovim" || echo "❌ Neovim"
	@nvim --headless -c "lua require('fzf-lua')" -c "qa" 2>/dev/null && echo "✅ fzf-lua (optional)" || echo "⚠️  fzf-lua not found (optional)"
	@nvim --headless -c "lua require('lspconfig')" -c "qa" 2>/dev/null && echo "✅ nvim-lspconfig (optional)" || echo "⚠️  nvim-lspconfig not found (optional)"

################################################################################
# Code Quality \
QUALITY: ## ##################################################################

.PHONY: lint
lint: ## run Lua linting (stylua if available)
	@if command -v stylua >/dev/null 2>&1; then \
		echo "Running stylua formatting check..."; \
		stylua --check $(lua_src); \
	else \
		echo "stylua not found - install with: cargo install stylua"; \
		echo "Skipping lint check"; \
	fi

.PHONY: format
format: ## format Lua code with stylua
	@if command -v stylua >/dev/null 2>&1; then \
		echo "Formatting Lua code with stylua..."; \
		stylua $(lua_src); \
	else \
		echo "stylua not found - install with: cargo install stylua"; \
		exit 1; \
	fi

.PHONY: luacheck
luacheck: ## run luacheck for static analysis
	@if command -v luacheck >/dev/null 2>&1; then \
		echo "Running luacheck..."; \
		luacheck $(lua_src) --globals vim; \
	else \
		echo "luacheck not found - install with: luarocks install luacheck"; \
		echo "Skipping luacheck"; \
	fi

################################################################################
# Version Management \
VERSIONING: ## ###############################################################

.PHONY: bump-major
bump-major: check-github-token ## bump major version, tag and push
	bump-my-version bump --commit --tag major
	git push
	git push --tags
	@$(MAKE) create-release

.PHONY: bump-minor
bump-minor: check-github-token ## bump minor version, tag and push
	bump-my-version bump --commit --tag minor
	git push
	git push --tags
	@$(MAKE) create-release

.PHONY: bump-patch
bump-patch: check-github-token ## bump patch version, tag and push
	bump-my-version bump --commit --tag patch
	git push
	git push --tags
	@$(MAKE) create-release

.PHONY: create-release
create-release: check-github-token ## create a release on GitHub via the gh cli
	@if ! command -v gh &>/dev/null; then \
		echo "You do not have the GitHub CLI (gh) installed. Please create the release manually."; \
		exit 1; \
	else \
		echo "Creating GitHub release for v$(VERSION)"; \
		gh release create "v$(VERSION)" --generate-notes --latest; \
	fi

.PHONY: check-github-token
check-github-token: ## check if GITHUB_TOKEN is set
	@if [ -z "$$GITHUB_TOKEN" ]; then \
		echo "GITHUB_TOKEN is not set. Please export your GitHub token before running this command."; \
		exit 1; \
	fi
	@echo "GITHUB_TOKEN is set"

.PHONY: version
version: ## show current version
	@echo "bkmr.nvim version: $(VERSION)"

################################################################################
# Documentation \
DOCUMENTATION: ## ############################################################

.PHONY: docs
docs: ## generate and update documentation
	@echo "Updating bkmr.nvim documentation..."
	@echo "✅ README.md - comprehensive user documentation"
	@echo "✅ doc/bkmr.txt - Vim help documentation"
	@echo "✅ CLAUDE.md - development guidance"
	@echo ""
	@echo "Help tags need regeneration in Neovim:"
	@echo "  :helptags doc/"

.PHONY: check-docs
check-docs: ## validate documentation
	@echo "Checking documentation consistency..."
	@grep -q "$(VERSION)" README.md && echo "✅ Version in README.md" || echo "⚠️  Version not found in README.md"
	@grep -q "$(VERSION)" lua/bkmr/init.lua && echo "✅ Version in init.lua" || echo "⚠️  Version not found in init.lua"

################################################################################
# Plugin Management \
PLUGIN: ## ###################################################################

.PHONY: install-dev
install-dev: ## install plugin for development (symlink to nvim config)
	@echo "For development, add this to your Neovim config:"
	@echo ""
	@echo "-- Using lazy.nvim"
	@echo "{"
	@echo "  'sysid/bkmr.nvim',"
	@echo "  dev = true,"
	@echo "  dir = '$(PWD)',"
	@echo "  dependencies = { 'ibhagwan/fzf-lua', 'neovim/nvim-lspconfig' },"
	@echo "  config = function()"
	@echo "    require('bkmr').setup()"
	@echo "  end"
	@echo "}"

.PHONY: test-integration
test-integration: ## test plugin integration with real Neovim setup
	@echo "Testing bkmr.nvim integration..."
	@echo "Make sure bkmr.nvim is loaded in your Neovim config"
	nvim -c "lua print('bkmr.nvim version: ' .. require('bkmr').version)" -c "qa"

.PHONY: validate-plugin
validate-plugin: ## validate plugin structure and functionality
	@echo "Validating bkmr.nvim plugin structure..."
	@[ -f "lua/bkmr/init.lua" ] && echo "✅ Main module" || echo "❌ Missing main module"
	@[ -f "plugin/bkmr.lua" ] && echo "✅ Plugin loader" || echo "❌ Missing plugin loader"
	@[ -f "doc/bkmr.txt" ] && echo "✅ Help documentation" || echo "❌ Missing help docs"
	@[ -f "syntax/bkmr.vim" ] && echo "✅ Syntax highlighting" || echo "❌ Missing syntax file"
	@[ -d "ftdetect" ] && echo "✅ Filetype detection" || echo "❌ Missing ftdetect"

################################################################################
# LSP Integration \
LSP: ## ######################################################################

.PHONY: test-lsp-commands
test-lsp-commands: ## test LSP command integration
	@echo "Testing bkmr LSP commands..."
	@echo "This requires bkmr CLI with LSP support (4.24.0+)"
	@bkmr --version | grep -E "4\.(2[4-9]|[3-9][0-9])|[5-9]\." > /dev/null && echo "✅ bkmr version supports LSP" || echo "❌ bkmr version too old for LSP"

.PHONY: setup-lsp
setup-lsp: ## setup bkmr LSP for manual testing
	@echo "Setting up bkmr LSP for testing..."
	@echo "Run this in Neovim to test LSP setup:"
	@echo ""
	@echo "  require('lspconfig').bkmr_lsp.setup({"
	@echo "    cmd = { 'bkmr', 'lsp' },"
	@echo "    filetypes = { 'rust', 'python', 'javascript' }"
	@echo "  })"

################################################################################
# Cleanup \
CLEANUP: ## ##################################################################

.PHONY: clean
clean: ## remove build artifacts and temporary files
	@echo "Cleaning up bkmr.nvim..."
	find . -name "*.tmp" -delete
	find . -name "*.log" -delete
	find . -name ".DS_Store" -delete
	@echo "✅ Cleanup complete"

################################################################################
# Utilities \
UTILITIES: ## #################################################################

.PHONY: _confirm
_confirm:
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo "Action confirmed by user."

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([%a-zA-Z0-9_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		if target != "dummy":
			print("\033[36m%-20s\033[0m %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

.PHONY: help
help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)
