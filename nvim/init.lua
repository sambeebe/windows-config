vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = false
vim.o.number = true
vim.o.mouse = "a"
vim.o.showmode = false

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.o.inccommand = "split"
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Remove the default 's' binding to free it up for mini.surround
vim.keymap.set("n", "s", "<Nop>", { noremap = true })
-- Remap the built-in 's' command to 'cl' which does the same thing
vim.keymap.set("n", "cl", "s", { desc = "Substitute character (remapped from 's')" })
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

-- Initialize vim-plug
vim.cmd([[
  call plug#begin('~/AppData/Local/nvim/plugged')

  " Core plugins
  Plug 'NMAC427/guess-indent.nvim'
  Plug 'lewis6991/gitsigns.nvim'
  Plug 'folke/which-key.nvim'

  " Telescope and dependencies
  Plug 'nvim-telescope/telescope.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
  Plug 'nvim-telescope/telescope-ui-select.nvim'
  Plug 'nvim-tree/nvim-web-devicons'

  " LSP and completion
  Plug 'neovim/nvim-lspconfig'
  Plug 'williamboman/mason.nvim'
  Plug 'williamboman/mason-lspconfig.nvim'
  Plug 'WhoIsSethDaniel/mason-tool-installer.nvim'
  Plug 'j-hui/fidget.nvim'
  Plug 'saghen/blink.cmp'
  Plug 'folke/lazydev.nvim'

  " Snippets
  Plug 'L3MON4D3/LuaSnip', { 'tag': 'v2.*', 'do': 'make install_jsregexp' }

  " Formatting
  Plug 'stevearc/conform.nvim'

  " UI and colorscheme
  Plug 'folke/tokyonight.nvim'
  Plug 'folke/todo-comments.nvim'
  Plug 'echasnovski/mini.nvim'
  Plug 'https://github.com/nvim-lualine/lualine.nvim'
  " Treesitter
  Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
  Plug 'https://github.com/chentoast/marks.nvim'
  Plug 'https://github.com/svermeulen/vim-cutlass'
  Plug 'https://github.com/smoka7/hop.nvim'
  Plug 'https://github.com/sisoe24/nuketools.nvim'
  Plug 'nvim-lua/plenary.nvim'
  Plug 'greggh/claude-code.nvim'
  call plug#end()
]])

-- Guess indent setup
require("guess-indent").setup()

-- Gitsigns setup
require("gitsigns").setup({
	signs = {
		add = { text = "+" },
		change = { text = "~" },
		delete = { text = "_" },
		topdelete = { text = "‾" },
		changedelete = { text = "~" },
	},
})

-- Which-key setup
require("which-key").setup({
	delay = 0,
	icons = {
		mappings = vim.g.have_nerd_font,
		keys = vim.g.have_nerd_font and {} or {
			Up = "<Up> ",
			Down = "<Down> ",
			Left = "<Left> ",
			Right = "<Right> ",
			C = "<C-…> ",
			M = "<M-…> ",
			D = "<D-…> ",
			S = "<S-…> ",
			CR = "<CR> ",
			Esc = "<Esc> ",
			ScrollWheelDown = "<ScrollWheelDown> ",
			ScrollWheelUp = "<ScrollWheelUp> ",
			NL = "<NL> ",
			BS = "<BS> ",
			Space = "<Space> ",
			Tab = "<Tab> ",
			F1 = "<F1>",
			F2 = "<F2>",
			F3 = "<F3>",
			F4 = "<F4>",
			F5 = "<F5>",
			F6 = "<F6>",
			F7 = "<F7>",
			F8 = "<F8>",
			F9 = "<F9>",
			F10 = "<F10>",
			F11 = "<F11>",
			F12 = "<F12>",
		},
	},
	spec = {
		{ "<leader>s", group = "[S]earch" },
		{ "<leader>t", group = "[T]oggle" },
		{ "<leader>h", group = "Git [H]unk", mode = { "n", "v" } },
	},
})

-- Telescope setup
require("telescope").setup({
	extensions = {
		["ui-select"] = {
			require("telescope.themes").get_dropdown(),
		},
	},

	defaults = {
		layout_strategy = "vertical",
		previewer = true,
		layout_config = {
			height = 0.95,
			width = 0.95,

			-- split the space: preview ~40%, results fill remaining space, prompt at bottom
			preview_height = 0.4, -- middle section
			prompt_position = "bottom",
		},
	},

	pickers = {
		find_files = {
			layout_strategy = "vertical",
			previewer = true,
			layout_config = {
				height = 0.95,
				width = 0.95,

				-- split the space: preview ~40%, results fill remaining space, prompt at bottom
				preview_height = 0.4, -- middle section
				prompt_position = "bottom",
			},
		},
	},
})

pcall(require("telescope").load_extension, "fzf")
pcall(require("telescope").load_extension, "ui-select")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set("n", "<leader>ff", builtin.buffers, { desc = "[ ] Find existing buffers" })
vim.keymap.set("n", "<leader>/", function()
	builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
		winblend = 10,
		previewer = false,
	}))
end, { desc = "[/] Fuzzily search in current buffer" })
vim.keymap.set("n", "<leader>s/", function()
	builtin.live_grep({
		grep_open_files = true,
		prompt_title = "Live Grep in Open Files",
	})
end, { desc = "[S]earch [/] in Open Files" })
vim.keymap.set("n", "<leader>sn", function()
	builtin.find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "[S]earch [N]eovim files" })

-- Lazydev setup
require("lazydev").setup({
	library = {
		{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
	},
})

-- Mason setup
require("mason").setup()

-- Fidget setup
require("fidget").setup()

-- LSP configuration
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
	callback = function(event)
		local map = function(keys, func, desc, mode)
			mode = mode or "n"
			vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
		end
		map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
		map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
		map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
		map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
		map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
		map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
		map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
		map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
		map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")

		local function client_supports_method(client, method, bufnr)
			if vim.fn.has("nvim-0.11") == 1 then
				return client:supports_method(method, bufnr)
			else
				return client.supports_method(method, { bufnr = bufnr })
			end
		end

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if
			client
			and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
		then
			local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				buffer = event.buf,
				group = highlight_augroup,
				callback = vim.lsp.buf.clear_references,
			})
			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
				callback = function(event2)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
				end,
			})
		end

		if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
			map("<leader>th", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
			end, "[T]oggle Inlay [H]ints")
		end
	end,
})

vim.diagnostic.config({
	severity_sort = true,
	float = { border = "rounded", source = "if_many" },
	underline = { severity = vim.diagnostic.severity.ERROR },
	signs = false,
	virtual_text = {
		source = "if_many",
		spacing = 2,
		format = function(diagnostic)
			local diagnostic_message = {
				[vim.diagnostic.severity.ERROR] = diagnostic.message,
				[vim.diagnostic.severity.WARN] = diagnostic.message,
				[vim.diagnostic.severity.INFO] = diagnostic.message,
				[vim.diagnostic.severity.HINT] = diagnostic.message,
			}
			return diagnostic_message[diagnostic.severity]
		end,
	},
})

-- Blink.cmp setup
-- local capabilities = require("blink.cmp").get_lsp_capabilities()
--
-- require("blink.cmp").setup({
-- keymap = {
-- preset = "default",
-- },
-- appearance = {
-- nerd_font_variant = "mono",
-- },
-- completion = {
-- documentation = { auto_show = false, auto_show_delay_ms = 500 },
-- },
-- sources = {
-- default = { "lsp", "path", "snippets", "lazydev" },
-- providers = {
-- lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
-- },
-- },
-- snippets = { preset = "luasnip" },
-- fuzzy = { implementation = "lua" },
-- signature = { enabled = true },
-- })

-- LuaSnip setup
require("luasnip").setup()

-- Mason-lspconfig setup
local servers = {
	lua_ls = {
		settings = {
			Lua = {
				completion = {
					callSnippet = "Replace",
				},
			},
		},
	},
}

local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
	"stylua", -- Used to format Lua code
})

require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

require("mason-lspconfig").setup({
	ensure_installed = {},
	automatic_installation = false,
	handlers = {
		function(server_name)
			local server = servers[server_name] or {}
			server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
			require("lspconfig")[server_name].setup(server)
		end,
	},
})

-- Conform setup
require("conform").setup({
	notify_on_error = false,
	format_on_save = function(bufnr)
		local disable_filetypes = { c = true, cpp = true }
		if disable_filetypes[vim.bo[bufnr].filetype] then
			return nil
		else
			return {
				timeout_ms = 500,
				lsp_format = "fallback",
			}
		end
	end,
	formatters_by_ft = {
		lua = { "stylua" },
	},
})

-- Format keymap
vim.keymap.set("", "<leader>f", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "[F]ormat buffer" })

-- Tokyonight setup
require("tokyonight").setup({
	styles = {
		comments = { italic = false },
	},
})
vim.cmd.colorscheme("tokyonight-night")

-- Todo-comments setup
require("todo-comments").setup({ signs = false })

-- Mini.nvim setup
require("mini.ai").setup({ n_lines = 500 })

-- Set up mini.surround with simplified keys
require("mini.surround").setup({
	-- Use shorter keys
	-- Module mappings. Use `''` (empty string) to disable one.
	mappings = {
		add = "s", -- Add surrounding in Normal and Visual modes
		delete = "sd", -- Delete surrounding
		find = "sf", -- Find surrounding (to the right)
		find_left = "sF", -- Find "surrounding" ;(to the left)
		highlight = "sh", -- Highlight surrounding
		replace = "sr", -- Replace surrounding
		update_n_lines = "sn", -- Update `n_lines`
		suffix_last = "l", -- Suffix to search with "prev" method
		suffix_next = "n", -- Suffix to  search  with "next" method
	},
})

-- STATUS LINE
require("lualine").setup({
	options = {
		icons_enabled = true,
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = {},
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		always_show_tabline = true,
		globalstatus = false,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
			refresh_time = 16, -- ~60fps
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"SessionLoadPost",
				"FileChangedShellPost",
				"VimResized",
				"Filetype",
				"CursorMoved",
				"CursorMovedI",
				"ModeChanged",
			},
		},
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
})

-- Treesitter setup
require("nvim-treesitter.configs").setup({
	ensure_installed = {
		"bash",
		"c",
		"diff",
		"html",
		"lua",
		"luadoc",
		"markdown",
		"markdown_inline",
		"query",
		"vim",
		"vimdoc",
	},
	auto_install = true,
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = { "ruby" },
	},
	indent = { enable = true, disable = { "ruby" } },
})

-- Add this to your config
vim.keymap.set("n", "<leader>nk", function()
	local data = vim.fn.json_encode({
		text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"),
		file = "",
		formatText = "0",
	})
	local socket = vim.loop.new_tcp()
	socket:connect("127.0.0.1", 54321, function(err)
		if not err then
			socket:write(data, function()
				socket:close()
			end)
		end
	end)
end, { desc = "Send buffer to Nuke" })

-- Auto open Telescope when Neovim is started in a directory
-- Auto open Telescope when Neovim is started in a directory, but not when opening a file
vim.api.nvim_create_autocmd("VimEnter", {
	pattern = "*",
	callback = function()
		-- Check if Neovim was opened without a file argument
		if vim.fn.argc() == 0 and vim.fn.isdirectory(vim.fn.getcwd()) == 1 then
			-- Open Telescope's find_files when no file is specified and we're in a directory
			vim.cmd("Telescope find_files")
		end
	end,
})

-- Marks

-- require("marks").setup({
-- default_mappings = true,
-- builtin_marks = { ".", "<", ">", "^" },
-- cyclic = true,
-- force_write_shada = false,
-- refresh_interval = 250,
-- sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
-- excluded_filetypes = {},
-- excluded_buftypes = {},
-- bookmark_0 = {
-- sign = "⚑",
-- virt_text = "hello world",
-- annotate = false,
-- },
-- mappings = {
-- next = ">", -- Go to next mark with )
-- prev = "<", -- Go to previous mark with (
-- },
-- })

-- Create custom command to copy file path
vim.api.nvim_create_user_command("C", function()
	local full_path = vim.fn.expand("%:p")
	vim.fn.setreg("+", full_path)
	print("Copied: " .. full_path)
end, {})

-- Create custom command to execute PowerShell's "e" command
vim.api.nvim_create_user_command("F", function()
	-- Execute PowerShell with the 'e' command
	vim.fn.system('powershell.exe -Command "e"')
	-- Print a confirmation message
	print("PowerShell command 'e' executed")
end, {})

-- Create custom command to execute PowerShell's "e" command
vim.api.nvim_create_user_command("NN", function()
	-- Execute PowerShell with the 'e' command
	vim.fn.system('powershell.exe -Command "nn"')
	-- Print a confirmation message
	print("PowerShell command 'nn' executed")
end, {})

-- Define a custom command to reload the Neovim configuration
vim.api.nvim_create_user_command("RC", "source C:/Users/samue/AppData/Local/nvim/init.lua", { nargs = 0 })

vim.opt.relativenumber = true
-- Create custom command to toggle between relative and absolute line numbers
vim.api.nvim_create_user_command("T", function()
	-- Check current state of number and relativenumber
	local has_number = vim.opt.number:get()
	local has_relative = vim.opt.relativenumber:get()
	if has_relative then
		-- If currently using relative numbers, switch to absolute
		vim.opt.relativenumber = false
		vim.opt.number = true
		print("Switched to absolute line numbers")
	else
		-- If currently using absolute numbers, switch to relative
		vim.opt.relativenumber = true
		vim.opt.number = true -- Keep number on for hybrid mode
		print("Switched to relative line numbers")
	end
end, {})

-- Clipboard setting removed - using cutlass plugin instead

-- Load custom keymaps
require("keymaps")
