local opt = vim.opt
local g = vim.g

-- Set highlight on search
vim.o.hlsearch = true
-- vim.o.incsearch = false
vim.o.inccommand = "split"

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Set where splits go
opt.splitbelow = true
opt.splitright = true

-- START Custom Vim Settings
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.relativenumber = true
opt.iskeyword:append("-")
opt.cursorline = true
opt.colorcolumn = '80'
opt.scrolloff = 8
opt.fillchars:append { diff = "╱" }
-- END Custom Vim Settings

vim.opt.list = false
vim.opt.listchars:append "space:⋅"
vim.opt.listchars:append "eol:↴"

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl"

if vim.g.neovide then
  opt.colorcolumn = '100'
  -- Helper function for transparency formatting
  local alpha = function()
    return string.format("%x", math.floor((255 * vim.g.transparency) or 0.8))
  end

  vim.o.guifont = "FiraCode Nerd Font:h12" -- text below applies for VimScript
  -- vim.g.neovide_transparency = 0.6
  -- vim.g.transparency = 0.6
  vim.g.neovide_window_blurred = false
  -- vim.g.neovide_background_color = "#1e1e2e" .. alpha()
  -- vim.g.neovide_hide_mouse_when_typing = true
  -- vim.g.neovide_input_macos_option_is_meta = "right"
  -- vim.g.neovide_floating_blur_amount_x = 3.0
  -- vim.g.neovide_floating_blur_amount_y = 3.0
  vim.keymap.set('n', '<D-v>', '"+P') -- Paste normal mode
  vim.keymap.set('v', '<D-v>', '"+P') -- Paste visual mode
  vim.keymap.set('c', '<D-v>', '<C-R>+') -- Paste command mode
  vim.keymap.set('i', '<D-v>', '<ESC>l"+Pli') -- Paste insert mode
  vim.keymap.set('n', '<leader>y', '"+y', { desc = 'Yank to system clipboard', silent = true })

  vim.keymap.set({ 'n', 'v' }, '<C-+>', '<cmd>lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>', { desc = "Increase Font Size (Neovide only)" })
  vim.keymap.set({ 'n', 'v' }, '<C-->', '<cmd>lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>', { desc = "Decrease Font Size (Neovide only)" })
  vim.keymap.set({ 'n', 'v' }, '<C-0>', '<cmd>lua vim.g.neovide_scale_factor = 1<CR>', { desc = "Reset Font Size (Neovide only)" })
end

-- START LSP Settings
vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' } }
)
-- END LSP Settings

-- sync buffers automatically
opt.autoread = true
-- disable neovim generation a sswapfile and showing error
opt.swapfile = false
