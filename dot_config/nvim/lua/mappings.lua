local utils = require('utils.utils')

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- vim.keymap.set('n', '*', '*``', { silent = true, desc = "Highlight word without jumping" })
-- vim.keymap.set('n', '#', '#``', { silent = true, desc = "Highlight word without jumping" })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Select previously pasted lines
vim.keymap.set('n', 'gp', "`[v`]", { silent = true })

-- toggle wrap 
vim.keymap.set('n', 'yow', function()
  local wrap_option = vim.wo.wrap
  vim.wo.wrap = not wrap_option
end, { silent = true, desc = "Toggle wrap/nowrap" })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})


-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>k',function()
    vim.diagnostic.open_float { border = "rounded" }
  end, { desc = 'Open floating diagnostic message' })
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })


-- Normal Mode
-- vim.keymap.set('n', ';', ':', { desc = 'enter command mode', silent = true, nowait = true })
-- vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down and center cursor', silent = true })
-- vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up and center cursor', silent = true })
vim.keymap.set('n', '<leader>q', ':q <CR>', { desc = 'Exit (q) buffer', silent = true })
vim.keymap.set('n', '<Leader>to', '<CMD>tabnew %<CR>', { desc = 'Create new tab', silent = true })
vim.keymap.set('n', '<Leader>tx', '<CMD>tabclose<CR>', { desc = 'Close tab', silent = true })
vim.keymap.set('n', '<A-.>', '<CMD>tabn<CR>', { desc = 'Next tab', silent = true })
vim.keymap.set('n', '<A-,>', '<CMD>tabp<CR>', { desc = 'Prev tab', silent = true })
vim.keymap.set('n', '<leader><A-.>', ':+tabmove<CR>', { desc = 'Move tab to the right', silent = true })
vim.keymap.set('n', '<leader><A-,>', ':-tabmove<CR>', { desc = 'Move tab to the left', silent = true })
vim.keymap.set('n', 'x', '"_x', { desc = 'Delete without yanking', silent = true })
vim.keymap.set('n', '<leader>d', '"_d', { desc = 'Delete without yanking', silent = true })
vim.keymap.set('n', '<leader>p', '"_dP', { desc = 'Delete without yanking', silent = true })
vim.keymap.set('n', '<M-c>', '"+y', { desc = 'Yank to system clipboard', silent = true })
vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Yank to system clipboard', silent = true })
vim.keymap.set('n', '<C-c>', '<ESC>', { desc = 'Escape btn with <C>', silent = true })
-- vim.keymap.set('n', '<M-b>', '<CMD>lua require(\'base46\').toggle_transparency()<CR>', { desc = 'Toggle Transparency', silent = true })
vim.keymap.set('n', '<M-b>', function()
  local colors_name = vim.g.colors_name
  local flavor = string.match(colors_name, "catppuccin%-(%w+)")
  local palette = require("catppuccin.palettes").get_palette(flavor)
  local current_bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Normal")), "bg#")

  if current_bg == "none" or current_bg == "" then
    -- If the current background is "none" or not set, set it to the base color of the current flavor
    vim.api.nvim_set_hl(0, "Normal", { bg = palette.base })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = palette.base })
  else
    -- If the current background is set, set it to "none"
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
  end
end, { desc = 'Toggle Transparency', silent = true })

-- Formatting and linting 
vim.keymap.set('n', '={', '=a{', { desc = 'Format space AROUND curly braces', silent = true })
vim.keymap.set('n', '=}', '=i{', { desc = 'Format space INSIDE curly braces', silent = true })
vim.keymap.set('n', '=(', '=a(', { desc = 'Format space AROUND parentheses', silent = true })
vim.keymap.set('n', '=)', '=i(', { desc = 'Format space INSIDE parentheses', silent = true })
vim.keymap.set('n', '=[', '=a[', { desc = 'Format space AROUND brackets', silent = true })
vim.keymap.set('n', '=]', '=i]', { desc = 'Format space INSIDE brackets', silent = true })
vim.keymap.set('n', '<leader>Q', ':bd<CR>', { desc = 'Buffer delete', silent = true })
vim.keymap.set('n', '<Esc>', ':noh <CR>', { desc = 'Clear highlights', silent = true })
-- vim.keymap.set('n', '<leader>ll', '<cmd>ALEFix prettier<cr>', { desc = 'ALEFix prettier', silent = true })
vim.keymap.set('n', '<leader>ll', '<cmd>lua vim.lsp.buf.format()<cr>', { desc = 'Vim LSP Format Buffer', silent = true })

-- switch between windows
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Window left', silent = true })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Window right', silent = true })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Window down', silent = true })
-- this one is only here to make the c-j work. Idk why this is. Apparently, c-m and c-j are the same in some kind of terminal ascii way
vim.keymap.set('n', '<C-m>', '<C-w>j', { desc = 'Window down', silent = true })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Window up', silent = true })

-- window sizing
vim.keymap.set('n', '<C-]>', '<C-w>5>', { desc = 'Window wider', silent = true })
vim.keymap.set('n', '<C-[>', '<C-w>5<', { desc = 'Window narrower', silent = true })
vim.keymap.set('n', '<A-]>', '<C-w>5+',{ desc = 'Window taller', silent = true })
vim.keymap.set('n', '<A-[>', '<C-w>5-',{ desc = 'Window shorter', silent = true })

-- save
vim.keymap.set('n', '<C-s>', '<cmd>silent! update | redraw<CR>', { desc = 'Save', silent = true })
vim.keymap.set({'i','x'}, '<C-s>', '<Esc><cmd>silent! update | redraw<CR>', { desc = 'Save and go to normal mode', silent = true })

-- Visual  Mode
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line down', silent = true })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move line up', silent = true })
vim.keymap.set('v', '<M-c>', '"+y', { desc = 'Yank to system clipboard', silent = true })
vim.keymap.set('v', 'x', '"_x', { desc = 'Delete without yanking', silent = true })
vim.keymap.set('v', '<leader>U', ':s/\\%V\\w\\+/\\u&/g<CR>', { desc = 'Capitalize words in selection', silent = true })
vim.keymap.set('v', '<', '<gv', { desc = 'Indent line and reselect', silent = true })
vim.keymap.set('v', '>', '>gv', { desc = 'Outdent line and reselect', silent = true })
vim.keymap.set('v', '<C-a>', '<C-a>gv', { desc = 'Increase number in selection and reselect', silent = true })
vim.keymap.set('v', '<C-x>', '<C-x>gv', { desc = 'Decrease number in selection and reselect', silent = true })
vim.keymap.set('x', 'j', 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', { expr = true, silent = true, desc = 'Move down' })
vim.keymap.set('x', 'k', 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', { expr = true, silent = true, desc = 'Move up' })
vim.keymap.set('x', 'p', 'p:let @+=@0<CR>:let @"=@0<CR>', { silent = true, desc = "Don't copy replaced text" })


-- Insert Mode
vim.keymap.set('i', '<M-BS>', '<ESC>vbc', { desc = 'Delete word', silent = true })
vim.keymap.set('i', '<M-Left>', '<ESC>bi', { desc = 'Move left 1 word', silent = true })
vim.keymap.set('i', '<M-Right>', '<ESC>ea', { desc = 'Move right 1 word', silent = true })
-- vim.keymap.set('i', '<C-h>', '<Left>', { desc = 'Move left', silent = true })
-- vim.keymap.set('i', '<C-l>', '<Right>', { desc = 'Move right', silent = true })
-- vim.keymap.set('i', '<C-j>', '<Down>', { desc = 'Move down', silent = true })
-- vim.keymap.set('i', '<C-k>', '<Up>', { desc = 'Move up', silent = true })

-- Terminal Mode
vim.keymap.set('t', '<C-x>', vim.api.nvim_replace_termcodes('<C-\\><C-N>', true, true, true), { desc = 'Escape terminal mode', silent = true })

-- Toggle the . spaces and eol arrows
vim.keymap.set('n', '<leader>zc', function()
  vim.opt.list = not vim.opt.list:get()
end, {desc = "Toggle listchars"})

-- Zellij 
vim.keymap.set('n', '<leader>pw', function()
  local Job = require("plenary.job")

  local current_file = vim.fn.resolve(vim.fn.expand("%"))
  local project_root_directory = utils.get_git_root_directory(current_file)
  local file_directory = vim.fn.fnamemodify(current_file, ":p:h")
  local branch_name = utils.branch_name(nil, file_directory)

  Job:new({
    command = "zellij",
    args = {
      "run",
      "-f",
      "--",
      "zsh",
    },
    cwd = project_root_directory,
    on_exit = function()
      Job:new({
        command = "zellij",
        args = {
          "action",
          "rename-pane",
          branch_name,
        },
      }):start()
    end,
  }):start()
end, {desc = "Open Zellij floating pane at cwd of the git root directory"})

vim.keymap.set('n', '<leader>pt', function()
  local Job = require("plenary.job")

  local current_file = vim.fn.resolve(vim.fn.expand("%"))
  local file_directory = vim.fn.fnamemodify(current_file, ":p:h")
  local branch_name = utils.branch_name(nil, file_directory)
  local branch_name_short = utils.split(branch_name, "/")

  Job:new({
    command = "zellij",
    args = {
      "action",
      "rename-tab",
      branch_name_short[#branch_name_short],
    },
  }):start()
end, {desc = "Change current Zellij tab name to current branch"})
