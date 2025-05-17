-- COLORS
vim.opt.termguicolors = true
vim.g.moonflyTerminalColors = true

-- LEADER
vim.g.mapleader = " "

-- Initialize vim-plug
vim.cmd([[
     call plug#begin('~/AppData/Local/nvim/plugged')
     Plug 'https://github.com/junegunn/vim-easy-align.git'
     Plug 'https://github.com/echasnovski/mini.nvim'
     Plug 'https://github.com/nvim-telescope/telescope.nvim'
     Plug 'nvim-lua/plenary.nvim' 
     Plug 'ThePrimeagen/harpoon'
     Plug 'https://github.com/svermeulen/vim-cutlass'
     Plug 'https://github.com/mbbill/undotree'
     Plug 'https://github.com/mg979/vim-visual-multi'
     Plug 'https://github.com/chentoast/marks.nvim'
     Plug 'https://github.com/bluz71/vim-moonfly-colors'
     Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
     Plug 'nvim-treesitter/nvim-treesitter-textobjects'
     Plug 'nvim-treesitter/playground'  
     Plug 'https://github.com/nvim-lualine/lualine.nvim'
     call plug#end()
     colorscheme moonfly
     ]]
     )
------------ VIM SETINGS ---------
vim.g.loaded_netrwPlugin = 0
vim.cmd('syntax enable')

vim.cmd('filetype plugin indent on') -- Enable filetype detection, plugin, and indent


vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  group = "YankHighlight",
  callback = function()
      vim.highlight.on_yank {
          higroup = "IncSearch",  -- highlight group (Visual, Search, IncSearch, etc)
          timeout = 149,          -- duration in ms
          on_visual = false,      -- don't trigger when pasting in visual mode
      }
  end,
})


vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)
vim.opt.undofile = true -- Save undo history

-- Set tab width and indentation
vim.opt.tabstop = 4        -- Number of spaces a tab counts for
vim.opt.shiftwidth = 4     -- Number of spaces for each step of autoindent
vim.opt.expandtab = true   -- Convert tabs to spaces
vim.opt.smartindent = true -- Auto-indent new lines
vim.opt.autoindent = true  -- Copy indent from current line when starting a new line
vim.opt.softtabstop = 3    -- Number of spaces a tab counts for when editing
vim.opt.smarttab = true    -- Insert spaces or tabs to go to the next indent
vim.opt.breakindent = true -- Wrapped lines will maintain their indentatio


vim.o.ignorecase = true  -- Makes searches case insensitive by default
vim.o.smartcase = true   -- Case-sensitive if search contains uppercase letters



----------CUSTOM COMMANDS-------
--
----
vim.api.nvim_set_keymap('n', '<C-l>', ':noh<CR>', { noremap = true, silent = true })

-- Create custom command to copy file path
vim.api.nvim_create_user_command('C', function()
     local full_path = vim.fn.expand('%:p')
     vim.fn.setreg('+', full_path)
     print("Copied: " .. full_path)
end, {})

-- Create custom command to execute PowerShell's "e" command
vim.api.nvim_create_user_command('F', function()
    -- Execute PowerShell with the 'e' command
    vim.fn.system('powershell.exe -Command "e"')
    -- Print a confirmation message
    print("PowerShell command 'e' executed")
end, {})


-- Define a custom command to reload the Neovim configuration
vim.api.nvim_create_user_command('RC', 'source C:/Users/samue/AppData/Local/nvim/init.lua', { nargs = 0 })


vim.opt.relativenumber = true
-- Create custom command to toggle between relative and absolute line numbers
vim.api.nvim_create_user_command('T', function()
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
        vim.opt.number = true  -- Keep number on for hybrid mode
        print("Switched to relative line numbers")
    end
end, {})


----------BUTTON REMAPS----------
-- Switch : and ; (swap their functionality)
vim.keymap.set('n', ';', ':', { noremap = true })
vim.keymap.set('n', ':', ';', { noremap = true })

-- Remove the default 's' binding to free it up for mini.surround
vim.keymap.set('n', 's', '<Nop>', { noremap = true })
-- Remap the built-in 's' command to 'cl' which does the same thing
vim.keymap.set('n', 'cl', 's', { desc = "Substitute character (remapped from 's')" })




----------MINI CONFIGS-----------
-- Set up mini.ai
require('mini.ai').setup({
  n_lines = 500,

  custom_textobjects = {
    -- your existing ones
    f = require('mini.ai').gen_spec.treesitter({ a = '@function.outer',    i = '@function.inner'    }),
    c = require('mini.ai').gen_spec.treesitter({ a = '@class.outer',       i = '@class.inner'       }),

    -- now add loops under 'u' (for “looP”)
    u = require('mini.ai').gen_spec.treesitter({ a = '@loop.outer',        i = '@loop.inner'        }),
    -- and blocks under 'b'
    b = require('mini.ai').gen_spec.treesitter({ a = '@block.outer',       i = '@block.inner'       }),
    -- and conditionals under 'o' (think “if/Else”)
    o = require('mini.ai').gen_spec.treesitter({ a = '@conditional.outer', i = '@conditional.inner' }),
  },

  mappings = {
    around       = 'a',
    inside       = 'i',
    around_next  = 'an',
    inside_next  = 'in',
    around_last  = 'al',
    inside_last  = 'il',
    goto_left    = 'g[',
    goto_right   = 'g]',
  },
})


-- Set up mini.surround with simplified keys
require('mini.surround').setup({
     -- Use shorter keys
     mappings = {
          add = 's',          -- Just 's' to start surrounding
          replace = 'cs',     -- Change surround (like vim-surround)
          delete = 'ds',      -- Delete surround (like vim-surround)
          -- Disable or simplify less commonly used operations
          find = '',          -- Disable find
          find_left = '',     -- Disable find left
          highlight = '',     -- Disable highlight
          update_n_lines = '', -- Disable update n_lines
     },
})


-- TREESITTER 
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "python", "powershell", "cpp" },
  highlight = {
    enable = true,
  }
}




-- Telescope mappings
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>')
vim.keymap.set('n', '<leader><leader>', '<cmd>Telescope find_files<CR>')
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>')
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>')
vim.api.nvim_set_keymap('n', '<Leader>h', ':bprevious<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<Leader>l', ':bnext<CR>', { noremap = true, silent = true })


-- Marks

require'marks'.setup {
     default_mappings = true,
     builtin_marks = { ".", "<", ">", "^" },
     cyclic = true,
     force_write_shada = false,
     refresh_interval = 250,
     -- sign priorities for each type of mark - builtin marks, uppercase marks, lowercase
     -- marks, and bookmarks.
     -- can be either a table with all/none of the keys, or a single number, in which case
     -- the priority applies to all marks.
     -- default 10.
     sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
     -- disables mark tracking for specific filetypes. default {}
     excluded_filetypes = {},
     -- disables mark tracking for specific buftypes. default {}
     excluded_buftypes = {},
     -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own
     -- sign/virttext. Bookmarks can be used to group together positions and quickly move
     -- across multiple buffers. default sign is '!@#$%^&*()' (from 0 to 9), and
     -- default virt_text is "".
     bookmark_0 = {
          sign = "⚑",
          virt_text = "hello world",
          -- explicitly prompt for a virtual line annotation when setting a bookmark from this group.
          -- defaults to false.
          annotate = false,
     },
     mappings = {}
}


require('marks').setup {
     mappings = {
          next = ">",     -- Go to next mark with )
          prev = "<",     -- Go to previous mark with (
          }
     }
-- CUTLASS
-- Revert 'x' to its default behavior (delete character)
-- vim.keymap.set('n', 'x', 'x', { noremap = true })  -- Normal mode: 'x' deletes character
--
-- -- Keep your customizations for other commands
-- vim.keymap.set('x', 'x', 'd', { noremap = true })  -- Visual mode: 'x' deletes selection
-- vim.keymap.set('n', 'xx', 'dd', { noremap = true })  -- Normal mode: 'xx' deletes current line
-- vim.keymap.set('n', 'X', 'D', { noremap = true })  -- Normal mode: 'X' deletes to end of line



-- STATUS LINE
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'auto',
    component_separators = { left = '|', right = '|'},
    section_separators = { left = '', right = ''},
    disabled_filetypes = {
      statusline = {},
      winbar = {},
    },
    ignore_focus = {},
    always_divide_middle = true,
    always_show_tabline = false,  -- Set to false to hide the tabline
    globalstatus = false,
    refresh = {
      statusline = 100,
      tabline = 100,
      winbar = 100,
    }
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diff', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'fileformat', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {'filename'},
    lualine_x = {'location'},
    lualine_y = {},
    lualine_z = {}
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {}
}








-- --
-- ----------CRUTCHES---------



-- backspace
vim.keymap.set('n', '<BS>', 'Xi', { noremap = true })
vim.keymap.set('v', '<BS>', '"_d', { noremap = true })
vim.keymap.set('x', '<BS>', '"_d', { noremap = true })


-- undo in insert mode
vim.api.nvim_set_keymap('i', '<C-z>', '<Esc>ui', { noremap = true })

-- Map Ctrl+C to copy text in visual mode
-- Map Ctrl+Z for undo in normal mode (already have it in insert mode)
vim.keymap.set('v', '<C-c>', '"+y', { noremap = true, desc = 'Copy selection to clipboard' })
vim.keymap.set('n', '<C-z>', 'u', { noremap = true, desc = 'Undo in normal mode' })

-- Normal mode: duplicate current line
-- Visual mode: duplicate selected lines
-- Insert mode: duplicate current line and stay in insert mode
vim.keymap.set('n', '<C-d>', 'yyp', { noremap = true, desc = 'Duplicate line' })
vim.keymap.set('v', '<C-d>', 'y`>p', { noremap = true, desc = 'Duplicate selection' })
vim.keymap.set('i', '<C-d>', '<Esc>yypi', { noremap = true, desc = 'Duplicate line' })


-- Map Ctrl+S to exit insert mode and save
vim.keymap.set('i', '<C-s>', '<Esc>:w<CR>', { noremap = true, silent = true, desc = 'Exit insert mode and save' })
vim.keymap.set('n', '<C-s>', ':w<CR>', { noremap = true, silent = true, desc = 'Save in normal mode' })




-- TAB
-- Clear any prior Tab mappings to avoid conflicts
-- Ensure Tab works for indentation even on non-blank lines
-- Shift + Tab to un-indent
-- Indentation in visual mode and keep visual mode active

vim.keymap.set('n', '<Tab>', '<Nop>', { noremap = true, silent = true })
vim.keymap.set('n', '<Tab>', "col('.') == 1 ? 'i<Tab>' : '>>_'", { noremap = true, silent = true, expr = true })
vim.keymap.set('n', '<S-Tab>', '<<', { noremap = true, silent = true })
vim.keymap.set('v', '<Tab>', '>gv', { noremap = true, silent = true })
vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true, silent = true })
vim.keymap.set('i', '<S-Tab>', '<C-d>', { noremap = true })
    
-- Increment with <leader>a
-- Decrement with <leader>x (since d is commonly used for delete)
-- vim.keymap.set('n', '<leader>a', '<C-a>', { noremap = true, desc = 'Increment number' })
-- vim.keymap.set('n', '<leader>x', '<C-x>', { noremap = true, desc = 'Decrement number' })

-- enter 
vim.keymap.set('n', '<CR>', 'i<CR><Esc>', { noremap = true })
-- vim.keymap.set('n', '<leader><CR>', 'i<CR>', { noremap = true })



-- In visual mode: create line breaks at selection boundaries
-- In visual block mode: maintain the block selection after pressing Enter
vim.keymap.set('v', '<CR>', 'd<CR><Esc>P', { noremap = true })
vim.keymap.set('x', '<CR>', '<C-v><CR>', { noremap = true })


--ctrl + A to select all 
vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true })


-- Fix Alt+Up/Down mappings
-- Visual mode
vim.keymap.set('v', '<A-Up>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up', noremap = true })
vim.keymap.set('v', '<A-Down>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down', noremap = true })
vim.keymap.set('i', '<A-Down>', '<Esc>:m .+1<CR>==gi', { desc = 'Move line down', noremap = true })
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', { desc = 'Move line up', noremap = true })
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', { desc = 'Move line down', noremap = true })

vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc = 'Move selection up', noremap = true })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc = 'Move selection down', noremap = true })
vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { desc = 'Move line down', noremap = true })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc = 'Move line up', noremap = true })
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc = 'Move line down', noremap = true })

vim.o.showmode = false
