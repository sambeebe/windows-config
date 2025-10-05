-- ----------CRUTCHES---------

-- backspace
-- vim.keymap.set("n", "<BS>", "Xi", { noremap = true })
-- vim.keymap.set("v", "<BS>", '"_d', { noremap = true })
-- vim.keymap.set("x", "<BS>", '"_d', { noremap = true })
-- Backspace - delete without copying to clipboard
vim.keymap.set("n", "<BS>", '"_X', { noremap = true }) -- delete char before cursor
vim.keymap.set("v", "<BS>", '"_d', { noremap = true })
vim.keymap.set("x", "<BS>", '"_d', { noremap = true })

-- Delete key - delete without copying to clipboard
vim.keymap.set("n", "<Del>", '"_x', { noremap = true }) -- delete char under cursor
vim.keymap.set("v", "<Del>", '"_d', { noremap = true })
vim.keymap.set("x", "<Del>", '"_d', { noremap = true })
-- undo in insert mode
vim.api.nvim_set_keymap("i", "<C-z>", "<Esc>ui", { noremap = true })

-- Ctrl+C to copy in visual mode
-- Ctrl+V to paste in normal, visual, and insert modes
-- Ctrl+Z for undo
vim.keymap.set("v", "<C-c>", "y", { noremap = true, silent = true, desc = "Copy selection" })
vim.keymap.set("n", "<C-v>", '"+p', { noremap = true, silent = true, desc = "Paste in normal mode" })
vim.keymap.set("v", "<C-v>", '"+p', { noremap = true, silent = true, desc = "Paste in visual mode" })
vim.keymap.set("i", "<C-v>", "<C-r>+", { noremap = true, silent = true, desc = "Paste in insert mode" })
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
-- Use Ctrl+j for jump forward (since Ctrl+i conflicts with Tab)
vim.keymap.set("n", "<C-j>", "<C-i>", { noremap = true, silent = true, desc = "Jump forward in jump list" })

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
-- Retain current single-character delete with `x`
vim.keymap.set("n", "x", '"_x', { noremap = true, silent = true, desc = "Delete char without clipboard" })

-- Add operator-pending "cut" functionality with `<leader>x`
vim.keymap.set("n", "X", '"+d', { noremap = true, silent = true, desc = "Cut to clipboard (motion)" })

-- Revert 'x' to its default behavior (delete character)
-- vim.keymap.set('n', 'x', 'x', { noremap = true })  -- Normal mode: 'x' deletes character
--
-- -- Keep your customizations for other commands
-- vim.keymap.set('x', 'x', 'd', { noremap = true })  -- Visual mode: 'x' deletes selection
-- vim.keymap.set('n', 'xx', 'dd', { noremap = true })  -- Normal mode: 'xx' deletes current line
-- vim.keymap.set('n', 'X', 'D', { noremap = true })  -- Normal mode: 'X' deletes to end of line
--
-- -- Telescope mappings
-- vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader><leader>", "<cmd>Telescope find_files<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>")
vim.api.nvim_set_keymap("n", "<Leader>h", ":bprevious<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Leader>l", ":bnext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<Leader>j", "<C-^>", { noremap = true, silent = true })

----------CUSTOM COMMANDS-------
--
----
vim.api.nvim_set_keymap("n", "<C-l>", ":noh<CR>", { noremap = true, silent = true })

----------BUTTON REMAPS----------
-- Switch : and ; (swap their functionality)
vim.keymap.set("n", ";", ":", { noremap = true })
vim.keymap.set("n", ":", ";", { noremap = true })

-- Duplicate current line and comment the original
vim.keymap.set("n", "<leader>d", function()
	local line_num = vim.api.nvim_win_get_cursor(0)[1]
	local line_content = vim.api.nvim_get_current_line()
	vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { line_content })
	vim.api.nvim_win_set_cursor(0, { line_num, 0 })
	vim.cmd("normal gcc")
	vim.api.nvim_win_set_cursor(0, { line_num + 1, 0 })
end, { desc = "Duplicate line and comment original" })

-- Traditional Cut Behavior (like Notepad++)
-- Normal mode: Ctrl+X cuts the current line
vim.keymap.set("n", "<C-x>", '"+dd', {
	noremap = true,
	silent = true,
	desc = "Cut current line to system clipboard",
})

-- Visual and Visual-Block mode: Ctrl+X cuts selected text
vim.keymap.set({ "v", "x" }, "<C-x>", '"+d', {
	noremap = true,
	silent = true,
	desc = "Cut selection to system clipboard",
})

-- around ( )
vim.keymap.set("n", "<leader>rp", function()
	local keys = "ca(" .. vim.api.nvim_replace_termcodes("<C-r>+<Esc>", true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Replace around ( ) with clipboard" })

-- inside ( )
vim.keymap.set("n", "<leader>ri", function()
	local keys = "ci(" .. vim.api.nvim_replace_termcodes("<C-r>+<Esc>", true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Replace inside ( ) with clipboard" })

-- generic: type the delimiter after <leader>rc (works for ", ', (, {, [, <, etc.)
vim.keymap.set("n", "<leader>rc", function()
	local ch = vim.fn.getcharstr()
	local keys = "ca" .. ch .. vim.api.nvim_replace_termcodes("<C-r>+<Esc>", true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Change around {char} and paste from clipboard" })

-- Function to extract quoted file path and open in Windows Explorer
local function open_quoted_path_in_explorer()
	-- Get current line and cursor position
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- Convert to 1-based indexing

	-- Find quotes around cursor position
	local quote_chars = { '"', "'", "`" }
	local start_pos, end_pos, quote_char = nil, nil, nil

	for _, q in ipairs(quote_chars) do
		-- Find the nearest opening quote before or at cursor
		local before_cursor = line:sub(1, col):reverse()
		local start_idx = before_cursor:find(q)
		if start_idx then
			start_pos = col - start_idx + 1
			quote_char = q

			-- Find the corresponding closing quote after the start position
			local after_start = line:sub(start_pos + 1)
			local end_idx = after_start:find(q)
			if end_idx then
				end_pos = start_pos + end_idx
				break
			end
		end
	end

	if not start_pos or not end_pos then
		print("No quoted text found around cursor")
		return
	end

	-- Extract the path between quotes
	local path = line:sub(start_pos + 1, end_pos - 1)

	-- Convert forward slashes to backslashes for Windows
	path = path:gsub("/", "\\")

	-- Copy to clipboard
	vim.fn.setreg("+", path)

	-- Simulate Ctrl+Alt+O key combination
	-- Using PowerShell to send the key combination
	local cmd = string.format(
		[[powershell.exe -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('^%%o')"]]
	)
	vim.fn.system(cmd)

	print("Copied path: " .. path .. " and triggered Ctrl+Alt+O")
end

-- Keymap to open quoted file path in Windows Explorer
vim.keymap.set("n", "<leader>o", open_quoted_path_in_explorer, { desc = "Open quoted path in Windows Explorer" })

-- Function to replace content inside quotes with clipboard
local function replace_quoted_with_clipboard()
	-- Try each quote type and see if we can select inside it
	local quote_chars = { '"', "'", "`" }

	for _, q in ipairs(quote_chars) do
		-- Try to select inside the quotes
		local success = pcall(function()
			vim.cmd("normal! vi" .. q)
		end)

		if success then
			-- Check if we actually selected something
			local start_pos = vim.fn.getpos("'<")
			local end_pos = vim.fn.getpos("'>")

			if start_pos[2] ~= end_pos[2] or start_pos[3] ~= end_pos[3] then
				-- We have a selection, replace with clipboard content
				vim.cmd('normal! "_c')
				vim.cmd('normal! "+p')
				return
			end
		end
	end

	print("No quoted text found around cursor")
end

-- Keymap to replace quoted content with clipboard
vim.keymap.set("n", "<leader>rq", replace_quoted_with_clipboard, { desc = "Replace quoted content with clipboard" })
