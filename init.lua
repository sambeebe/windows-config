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
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

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
  
  " Treesitter
  Plug 'nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }
  Plug 'https://github.com/chentoast/marks.nvim'
  Plug 'https://github.com/svermeulen/vim-cutlass'
  call plug#end()
]])

-- Plugin configurations
-- Note: With vim-plug, you need to configure plugins after they're loaded
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
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
		vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
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
					and client_supports_method(
						client,
						vim.lsp.protocol.Methods.textDocument_documentHighlight,
						event.buf
					)
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

				if
					client
					and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
				then
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
			signs = vim.g.have_nerd_font and {
				text = {
					[vim.diagnostic.severity.ERROR] = "󰅚 ",
					[vim.diagnostic.severity.WARN] = "󰀪 ",
					[vim.diagnostic.severity.INFO] = "󰋽 ",
					[vim.diagnostic.severity.HINT] = "󰌶 ",
				},
			} or {},
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
		local capabilities = require("blink.cmp").get_lsp_capabilities()

		require("blink.cmp").setup({
			keymap = {
				preset = "default",
			},
			appearance = {
				nerd_font_variant = "mono",
			},
			completion = {
				documentation = { auto_show = false, auto_show_delay_ms = 500 },
			},
			sources = {
				default = { "lsp", "path", "snippets", "lazydev" },
				providers = {
					lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
				},
			},
			snippets = { preset = "luasnip" },
			fuzzy = { implementation = "lua" },
			signature = { enabled = true },
		})

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

		-- require("mini.surround").setup()
		-- local statusline = require("mini.statusline")
		-- statusline.setup({ use_icons = vim.g.have_nerd_font })
		-- statusline.section_location = function()
		-- 	return "%2l:%-2v"
		-- end

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
	end,
})

-- ----------CRUTCHES---------

-- backspace
vim.keymap.set("n", "<BS>", "Xi", { noremap = true })
vim.keymap.set("v", "<BS>", '"_d', { noremap = true })
vim.keymap.set("x", "<BS>", '"_d', { noremap = true })

-- undo in insert mode
vim.api.nvim_set_keymap("i", "<C-z>", "<Esc>ui", { noremap = true })

-- Map Ctrl+C to copy text in visual mode
-- Map Ctrl+Z for undo in normal mode (already have it in insert mode)
vim.keymap.set("v", "<C-c>", '"+y', { noremap = true, desc = "Copy selection to clipboard" })
vim.keymap.set("n", "<C-z>", "u", { noremap = true, desc = "Undo in normal mode" })

-- Normal mode: duplicate current line
-- Visual mode: duplicate selected lines
-- Insert mode: duplicate current line and stay in insert mode
vim.keymap.set("n", "<C-g>", "yyp", { noremap = true, desc = "Duplicate line" })
vim.keymap.set("v", "<C-g>", "y`>p", { noremap = true, desc = "Duplicate selection" })
vim.keymap.set("i", "<C-g>", "<Esc>yypi", { noremap = true, desc = "Duplicate line" })

-- Map Ctrl+S to exit insert mode and save
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>", { noremap = true, silent = true, desc = "Exit insert mode and save" })
vim.keymap.set("n", "<C-s>", ":w<CR>", { noremap = true, silent = true, desc = "Save in normal mode" })

-- TAB
-- Clear any prior Tab mappings to avoid conflicts
-- Ensure Tab works for indentation even on non-blank lines
-- Shift + Tab to un-indent
-- Indentation in visual mode and keep visual mode active

vim.keymap.set("n", "<Tab>", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "<Tab>", "col('.') == 1 ? 'i<Tab>' : '>>_'", { noremap = true, silent = true, expr = true })
vim.keymap.set("n", "<S-Tab>", "<<", { noremap = true, silent = true })
vim.keymap.set("v", "<Tab>", ">gv", { noremap = true, silent = true })
vim.keymap.set("v", "<S-Tab>", "<gv", { noremap = true, silent = true })
vim.keymap.set("i", "<S-Tab>", "<C-d>", { noremap = true })

-- Increment with <leader>a
-- Decrement with <leader>x (since d is commonly used for delete)
-- vim.keymap.set(n', '<leader>a', '<C-a>', { noremap = true, desc = 'Increment number' })
-- vim.keymap.set('n', '<leader>x', '<C-x>', { noremap = true, desc = 'Decrement number' })

-- enter
-- In visual mode: create line breaks at selection boundaries
-- In visual block mode: maintain the block selection after pressing Enter

vim.keymap.set("n", "<CR>", "a<CR><Esc>", { noremap = true })
vim.keymap.set("n", "<leader><CR>", "i<CR>", { noremap = true })
vim.keymap.set("v", "<CR>", "d<CR><Esc>P", { noremap = true })
vim.keymap.set("x", "<CR>", "<C-v><CR>", { noremap = true })

--ctrl + A to select all
vim.keymap.set("n", "<C-a>", "ggVG", { noremap = true })

-- Fix Alt+Up/Down mappings
-- Visual mode
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", noremap = true })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", noremap = true })
vim.keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down", noremap = true })
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { desc = "Move line up", noremap = true })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { desc = "Move line down", noremap = true })

vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", noremap = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", noremap = true })
vim.keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down", noremap = true })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up", noremap = true })
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down", noremap = true })

-- CUTLASS
-- Revert 'x' to its default behavior (delete character)
-- vim.keymap.set('n', 'x', 'x', { noremap = true })  -- Normal mode: 'x' deletes character
--
-- -- Keep your customizations for other commands
-- vim.keymap.set('x', 'x', 'd', { noremap = true })  -- Visual mode: 'x' deletes selection
-- vim.keymap.set('n', 'xx', 'dd', { noremap = true })  -- Normal mode: 'xx' deletes current line
-- vim.keymap.set('n', 'X', 'D', { noremap = true })  -- Normal mode: 'X' deletes to end of line
--
-- -- Telescope mappings
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader><leader>", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
vim.api.nvim_set_keymap("n", "<Leader>h", ":bprevious<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Leader>l", ":bnext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Leader>j", "<C-^>", { noremap = true, silent = true })
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

require("marks").setup({
	default_mappings = true,
	builtin_marks = { ".", "<", ">", "^" },
	cyclic = true,
	force_write_shada = false,
	refresh_interval = 250,
	sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
	excluded_filetypes = {},
	excluded_buftypes = {},
	bookmark_0 = {
		sign = "⚑",
		virt_text = "hello world",
		annotate = false,
	},
	mappings = {
		next = ">", -- Go to next mark with )
		prev = "<", -- Go to previous mark with (
	},
})

----------CUSTOM COMMANDS-------
--
----
vim.api.nvim_set_keymap("n", "<C-l>", ":noh<CR>", { noremap = true, silent = true })

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

----------BUTTON REMAPS----------
-- Switch : and ; (swap their functionality)
vim.keymap.set("n", ";", ":", { noremap = true })
vim.keymap.set("n", ":", ";", { noremap = true })

-- -- Remove the default 's' binding to free it up for mini.surround
-- vim.keymap.set("n", "s", "<Nop>", { noremap = true })
-- -- Remap the built-in 's' command to 'cl' which does the same thing
-- vim.keymap.set("n", "cl", "s", { desc = "Substitute character (remapped from 's')" })

-- Duplicate current line and comment the original
vim.keymap.set("n", "<leader>d", function()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line_content = vim.api.nvim_get_current_line()
	vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { line_content })
	vim.api.nvim_win_set_cursor(0, { line_num, 0 })
	vim.cmd("normal gcc")
	vim.api.nvim_win_set_cursor(0, { line_num + 1, 0 })
end, { desc = "Duplicate line and comment original" })
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)
