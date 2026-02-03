-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)


-- Initialize the plugin list with plugins that are always loaded
local plugins = {
  { 'folke/which-key.nvim', 
  dependencies = { "nvim-lua/plenary.nvim", "j-morano/buffer_manager.nvim" },
  opts = {
      preset = "helix",
    }
  },
  -- { 'numToStr/Comment.nvim', opts = {} },
  { import = 'plugins' },
}

-- Conditionally add plugins based on certain conditions, like running in Neovide
if vim.g.neovide then
    table.insert(plugins, { import = 'plugins_neovide' })
end

-- Finally, set up all plugins with lazy.nvim
require('lazy').setup(plugins, {})

-- load in the options
require("options")

-- [[ Basic Keymaps ]]
-- load in the keymaps
require("mappings")

require("autocmds")

-- document existing key chains
-- require('which-key').register {
--   ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
--   ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
--   ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
--   ['<leader>h'] = { name = 'More git', _ = 'which_key_ignore' },
--   ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
--   ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
--   ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
-- }

-- Set GIT_EDITOR to use nvr if Neovim and nvr are available
if vim.fn.has('nvim') == 1 and vim.fn.executable('nvr') == 1 then
  vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end

-- Disable neovim-remote use in lazygit.nvim
-- vim.g.lazygit_use_neovim_remote = 0
