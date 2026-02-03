-- Keymaps
vim.keymap.set('n', '<leader>-', '<CMD>Oil<CR>', { desc = '[-] Open Oil directory editor' })

return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    config = function()
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["gv"] = { "actions.select", opts = { vertical = true }, desc = "Open the entry in a vertical split" },
          ["gs"] = { "actions.select", opts = { horizontal = true }, desc = "Open the entry in a horizontal split" },
          ["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open the entry in new tab" },
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["gr"] = "actions.refresh",
          ["-"] = "actions.parent",
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = { "actions.cd", opts = { scope = "tab" }, desc = ":tcd to the current oil directory" },
          ["gcs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["g\\"] = "actions.toggle_trash",
          ["="] = require("oil").save(), -- does not work. Want to get the buffer save to be = like in mini.files
        },
        use_default_keymaps = false,
      })
    end
  },
}
