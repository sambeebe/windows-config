-- COLORS
vim.opt.termguicolors = true
-- vim.g.moonflyTerminalColors = true
-- vim.cmd([[colorscheme everforest]])
-- vim.cmd('colorscheme everforest')
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
     Plug 'https://github.com/karb94/neoscroll.nvim'
     Plug 'https://github.com/neanias/everforest-nvim'
     Plug 'https://github.com/ellisonleao/gruvbox.nvim'
     Plug 'https://github.com/junegunn/vim-easy-align'
     Plug 'https://github.com/RRethy/vim-illuminate'
     call plug#end()
     "colorscheme moonfly
     "colorscheme everforest 
     colorscheme gruvbox
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
vim.opt.tabstop     = 4        -- Number of spaces a tab counts for
vim.opt.shiftwidth  = 4     -- Number of spaces for each step of autoindent
vim.opt.expandtab   = true   -- Convert tabs to spaces
vim.opt.smartindent = true -- Auto-indent new lines
vim.opt.autoindent  = true  -- Copy indent from current line when starting a new line
vim.opt.softtabstop = 3    -- Number of spaces a tab counts for when editing
vim.opt.smarttab    = true    -- Insert spaces or tabs to go to the next indent
vim.opt.breakindent = true -- Wrapped lines will maintain their indentatio


vim.o.ignorecase = true  -- Makes searches case insensitive by default
-- vim.o.smartcase = true   -- Case-sensitive if search contains uppercase letters



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


------------------- PLUGIN SETTINGS --------------------
-- Map ga to EasyAlign command
vim.api.nvim_set_keymap('x', 'ga', '<Plug>(EasyAlign)', { noremap = false, silent = true })
vim.api.nvim_set_keymap('n', 'ga', '<Plug>(EasyAlign)', { noremap = false, silent = true })

require('neoscroll').setup({
  mappings             = {                 -- Keys to be mapped to their corresponding default scrolling animation
    '<C-u>', '<C-d>',
    '<C-b>', '<C-f>',
    '<C-y>', '<C-e>',
    'zt', 'zz', 'zb',
  },
  hide_cursor          = true,          -- Hide cursor while scrolling
  stop_eof             = true,             -- Stop at <EOF> when scrolling downwards
  respect_scrolloff    = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
  cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
  duration_multiplier  = 0.2,   -- Global duration multiplier
  easing               = 'linear',           -- Default easing function
  pre_hook             = nil,              -- Function to run before the scrolling animation starts
  post_hook            = nil,             -- Function to run after the scrolling animation ends
  performance_mode     = false,    -- Disable "Performance Mode" on all buffers.
  ignored_events       = {           -- Events ignored while scrolling
      'WinScrolled', 'CursorMoved'
  },
})

require'nvim-treesitter.configs'.setup {
  textobjects = {
    select = {
      enable = true,

      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,

      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
	["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        -- You can optionally set descriptions to the mappings (used in the desc parameter of
        -- nvim_buf_set_keymap) which plugins like which-key display
        ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
        -- You can also use captures from other query groups like `locals.scm`
        ["as"] = { query = "@local.scope", query_group = "locals", desc = "Select language scope" },
      },
      -- You can choose the select mode (default is charwise 'v')
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * method: eg 'v' or 'o'
      -- and should return the mode ('v', 'V', or '<c-v>') or a table
      -- mapping query_strings to modes.
      selection_modes = {
        ['@parameter.outer'] = 'v', -- charwise
        ['@function.outer'] = 'V', -- linewise
        ['@class.outer'] = '<c-v>', -- blockwise
      },
      -- If you set this to `true` (default is `false`) then any textobject is
      -- extended to include preceding or succeeding whitespace. Succeeding
      -- whitespace has priority in order to act similarly to eg the built-in
      -- `ap`.
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * selection_mode: eg 'v'
      -- and should return true or false
      include_surrounding_whitespace = false,
    },
  },
}

----------MINI CONFIGS-----------
-- Set up mini.ai

-- require('mini.ai').setup({
--   n_lines = 500,
--
--   custom_textobjects = {
--     -- your existing ones
--     f = require('mini.ai').gen_spec.treesitter({ a = '@function.outer',    i = '@function.inner'    }),
--     c = require('mini.ai').gen_spec.treesitter({ a = '@class.outer',       i = '@class.inner'       }),
--
--     -- now add loops under 'u' (for “looP”)
--     u = require('mini.ai').gen_spec.treesitter({ a = '@loop.outer',        i = '@loop.inner'        }),
--     -- and blocks under 'b'
--     b = require('mini.ai').gen_spec.treesitter({ a = '@block.outer',       i = '@block.inner'       }),
--     -- and conditionals under 'o' (think “if/Else”)
--     o = require('mini.ai').gen_spec.treesitter({ a = '@conditional.outer', i = '@conditional.inner' }),
--   },
--
--   mappings = {
--     around       = 'a',
--     inside       = 'i',
--     around_next  = 'an',
--     inside_next  = 'in',
--     around_last  = 'al',
--     inside_last  = 'il',
--     goto_left    = 'g[',
--     goto_right   = 'g]',
--   },
-- })


-- Set up mini.surround with simplified keys
require('mini.surround').setup({
     -- Use shorter keys
 -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    add = 's', -- Add surrounding in Normal and Visual modes
    delete = 'sd', -- Delete surrounding
    find = 'sf', -- Find surrounding (to the right)
    find_left = 'sF', -- Find "surrounding" ;(to the left)
    highlight = 'sh', -- Highlight surrounding
    replace = 'sr', -- Replace surrounding
    update_n_lines = 'sn', -- Update `n_lines`

    suffix_last = 'l', -- Suffix to search with "prev" method
    suffix_next = 'n', -- Suffix to  search  with "next" method
  }
})


-- TREESITTER 
require'nvim-treesitter.configs'.setup {
  ensure_installed = { "lua", "python", "powershell", "cpp" },
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
vim.api.nvim_set_keymap('n', '<Leader>j', '<C-^>', { noremap = true, silent = true })
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
    end
})



-- Marks

require'marks'.setup {
    default_mappings = true,
    builtin_marks = { ".", "<", ">", "^" },
    cyclic = true,
    force_write_shada = false,
    refresh_interval = 250,
    sign_priority = { lower=10, upper=15, builtin=8, bookmark=20 },
    excluded_filetypes = {},
    excluded_buftypes = {},
    bookmark_0 = {
        sign = "⚑",
        virt_text = "hello world",
        annotate = false,
    },
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
vim.keymap.set('n', '<BS>', 'Xi',  { noremap = true })
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
vim.keymap.set('n', '<C-g>', 'yyp', { noremap = true, desc = 'Duplicate line' })
vim.keymap.set('v', '<C-g>', 'y`>p', { noremap = true, desc = 'Duplicate selection' })
vim.keymap.set('i', '<C-g>', '<Esc>yypi', { noremap = true, desc = 'Duplicate line' })


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
-- vim.keymap.set(n', '<leader>a', '<C-a>', { noremap = true, desc = 'Increment number' })
-- vim.keymap.set('n', '<leader>x', '<C-x>', { noremap = true, desc = 'Decrement number' })

-- enter 
-- In visual mode: create line breaks at selection boundaries
-- In visual block mode: maintain the block selection after pressing Enter

vim.keymap.set('n', '<CR>', 'a<CR><Esc>', { noremap = true })
vim.keymap.set('n', '<leader><CR>', 'i<CR>', { noremap = true })
vim.keymap.set('v', '<CR>', 'd<CR><Esc>P', { noremap = true })
vim.keymap.set('x', '<CR>', '<C-v><CR>', { noremap = true })




--ctrl + A to select all 
vim.keymap.set('n', '<C-a>', 'ggVG', { noremap = true })


-- Fix Alt+Up/Down mappings
-- Visual mode
vim.keymap.set('v', '<A-Up>', ":m '<-2<CR>gv=gv", { desc      = 'Move selection up', noremap = true   })
vim.keymap.set('v', '<A-Down>', ":m '>+1<CR>gv=gv", { desc    = 'Move selection down', noremap = true })
vim.keymap.set('i', '<A-Down>', '<Esc>:m .+1<CR>==gi', { desc = 'Move line down', noremap = true      })
vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', { desc          = 'Move line up', noremap = true        })
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', { desc        = 'Move line down', noremap = true      })

vim.keymap.set('v', '<A-k>', ":m '<-2<CR>gv=gv", { desc       = 'Move selection up', noremap = true   })
vim.keymap.set('v', '<A-j>', ":m '>+1<CR>gv=gv", { desc       = 'Move selection down', noremap = true })
vim.keymap.set('i', '<A-j>', '<Esc>:m .+1<CR>==gi', { desc    = 'Move line down', noremap = true      })
vim.keymap.set('n', '<A-k>', ':m .-2<CR>==', { desc           = 'Move line up', noremap = true        })
vim.keymap.set('n', '<A-j>', ':m .+1<CR>==', { desc           = 'Move line down', noremap = true      })

vim.o.showmode = false
