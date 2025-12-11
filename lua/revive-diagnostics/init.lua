local M = {}

local sast = require('sast-nvim')

-- Build command arguments for revive
local function build_revive_args(config, filepath)
	local args = {
		"-formatter", "json",
	}

	-- Add any extra arguments from config first (like -exclude patterns)
	for _, arg in ipairs(config.extra_args or {}) do
		table.insert(args, arg)
	end

	-- Add the file path last
	table.insert(args, filepath)

	return args
end

-- Validate a single revive result
local function validate_result(result)
	return result.Failure ~= nil and
		result.Position ~= nil and
		result.Position.Start ~= nil
end

-- Transform revive result to nvim diagnostic
local function transform_result(result, config)
	-- Map revive severity to nvim diagnostic severity
	local severity_map = {
		error = vim.diagnostic.severity.ERROR,
		warning = vim.diagnostic.severity.WARN,
	}

	local severity = severity_map[result.Severity] or vim.diagnostic.severity.INFO

	-- Build the diagnostic message
	local message = result.Failure
	if result.RuleName then
		message = string.format("%s [%s]", message, result.RuleName)
	end

	-- Build diagnostic object
	-- Note: none-ls expects 1-indexed row/col fields, not 0-indexed lnum/col
	local diag = {
		row = result.Position.Start.Line or 1,
		col = result.Position.Start.Column or 1,
		end_row = (result.Position.End and result.Position.End.Line) or result.Position.Start.Line,
		end_col = (result.Position.End and result.Position.End.Column) or result.Position.Start.Column,
		severity = severity,
		message = message,
		source = "revive",
		user_data = {
			rule_name = result.RuleName,
			category = result.Category,
			confidence = result.Confidence,
		}
	}

	return diag
end

-- Create the revive adapter
local revive_adapter = sast.create_adapter({
	name = "revive",
	executable = "revive",
	build_args = build_revive_args,
	validate_result = validate_result,
	transform_result = transform_result,
})

-- Setup function for users to call
function M.setup(opts)
	-- Set default configuration
	local default_opts = {
		enabled = true,
		filetypes = { "go" },
		run_mode = "save", -- "save" or "change"
		debounce_ms = 1000,
		minimum_severity = vim.diagnostic.severity.HINT,
		extra_args = {
			-- Exclude test files by default
			"-exclude", "**/*_test.go",
		},
		on_attach = function(bufnr, adapter)
			local opts_with_buf = { buffer = bufnr }

			vim.keymap.set("n", "<leader>rt", function()
				adapter.toggle()
			end, vim.tbl_extend("force", opts_with_buf, { desc = "[R]evive [T]oggle" }))

			vim.keymap.set("n", "<leader>rc", function()
				adapter.print_config()
			end, vim.tbl_extend("force", opts_with_buf, { desc = "[R]evive [C]onfig" }))

			vim.keymap.set("n", "<leader>rv", function()
				vim.ui.select(
					{ "ERROR", "WARN", "INFO", "HINT" },
					{
						prompt = "Select minimum severity level:",
						format_item = function(item)
							return string.format("%s (%d)", item, vim.diagnostic.severity[item])
						end,
					},
					function(choice)
						if choice then
							local severity = vim.diagnostic.severity[choice]
							adapter.set_minimum_severity(severity)
						end
					end
				)
			end, vim.tbl_extend("force", opts_with_buf, { desc = "[R]evive se[v]erity" }))
		end,
	}

	-- Merge user options with defaults
	local final_opts = vim.tbl_deep_extend("force", default_opts, opts or {})

	-- Setup the adapter
	revive_adapter.setup(final_opts)
end

-- Re-export adapter for advanced usage
M.adapter = revive_adapter

return M
