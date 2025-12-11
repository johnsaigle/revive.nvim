# revive.nvim

Neovim diagnostics integration for [revive](https://github.com/mgechev/revive), a fast and configurable Go linter.

Built using the [sast-nvim](https://github.com/johnsaigle/sast-nvim) library for static analysis tool integration.

## Features

- Real-time Go linting with revive
- Integrates with Neovim's native diagnostics system
- Configurable severity levels
- Works with none-ls/null-ls
- Automatically excludes test files (configurable)

## Requirements

- Neovim >= 0.8.0
- [revive](https://github.com/mgechev/revive) installed and available in PATH
- [sast-nvim](https://github.com/johnsaigle/sast-nvim) library
- [none-ls.nvim](https://github.com/nvimtools/none-ls.nvim) or [null-ls.nvim](https://github.com/jose-elias-alvarez/null-ls.nvim)

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "johnsaigle/revive.nvim",
  dependencies = {
    "johnsaigle/sast-nvim",
    "nvimtools/none-ls.nvim",
  },
  config = function()
    require("revive-diagnostics").setup({
      -- Optional: customize configuration
      enabled = true,
      filetypes = { "go" },
      run_mode = "save", -- "save" or "change"
    })
  end,
}
```

## Configuration

### Default Configuration

```lua
{
  enabled = true,
  filetypes = { "go" },
  run_mode = "save", -- "save" or "change"
  debounce_ms = 1000,
  minimum_severity = vim.diagnostic.severity.HINT,
  extra_args = {
    "-exclude", "**/*_test.go", -- Exclude test files by default
  },
  on_attach = function(bufnr, adapter)
    -- Default keymaps (see below)
  end,
}
```

### Options

- `enabled` (boolean): Enable/disable the linter. Default: `true`
- `filetypes` (table): List of filetypes to lint. Default: `{ "go" }`
- `run_mode` (string): When to run the linter
  - `"save"`: Only on file save
  - `"change"`: On buffer changes (debounced)
- `debounce_ms` (number): Debounce delay in milliseconds (only for "change" mode). Default: `1000`
- `minimum_severity` (number): Minimum severity level to show. Default: `vim.diagnostic.severity.HINT`
- `extra_args` (table): Additional arguments to pass to revive. Default: `{ "-exclude", "**/*_test.go" }`
- `on_attach` (function): Function called when attaching to a buffer. Receives `bufnr` and `adapter`.

### Example: Custom Configuration

```lua
require("revive-diagnostics").setup({
  enabled = true,
  run_mode = "change", -- Run on every change (debounced)
  debounce_ms = 500,   -- Faster debounce
  minimum_severity = vim.diagnostic.severity.WARN, -- Only show warnings and errors
  extra_args = {},     -- Don't exclude test files
  on_attach = function(bufnr, adapter)
    -- Custom keymaps
    vim.keymap.set("n", "<leader>lt", function()
      adapter.toggle()
    end, { buffer = bufnr, desc = "Toggle revive" })
  end,
})
```

## Default Keymaps

When `on_attach` is not overridden, the following keymaps are set:

- `<leader>rt` - Toggle revive diagnostics on/off
- `<leader>rc` - Print current configuration
- `<leader>rv` - Set minimum severity level (interactive)

## Usage

Once installed and configured, revive will automatically lint your Go files based on your `run_mode` setting.

### Commands

The plugin provides the following functionality through the adapter:

```lua
local revive = require("revive-diagnostics")

-- Toggle the linter on/off
revive.adapter.toggle()

-- Print current configuration
revive.adapter.print_config()

-- Set minimum severity level
revive.adapter.set_minimum_severity(vim.diagnostic.severity.ERROR)
```

## Configuring Revive

To configure revive's linting rules, create a `revive.toml` file in your project root or `$HOME`. See the [revive documentation](https://github.com/mgechev/revive#configuration) for details.

Example `revive.toml`:

```toml
ignoreGeneratedHeader = false
severity = "warning"
confidence = 0.8

[rule.blank-imports]
[rule.context-as-argument]
[rule.error-return]
[rule.error-strings]
[rule.exported]
```

## Troubleshooting

### Revive not found

Make sure revive is installed and available in your PATH:

```bash
# Install revive
go install github.com/mgechev/revive@latest

# Verify installation
which revive
revive -version
```

### Diagnostics not showing

1. Check if the linter is enabled: `<leader>rc`
2. Verify none-ls is installed and configured
3. Check your `minimum_severity` setting
4. Ensure you're editing a `.go` file (not `*_test.go` by default)
