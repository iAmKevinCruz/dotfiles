-- Keymaps
vim.keymap.set('n', '<leader>zz', '<CMD>ZenMode<CR>', { desc = '[Z]en [M]ode', silent = true })
vim.keymap.set('n', '<leader>zt', '<CMD>Twilight<CR>', { desc = '[T]wilight toggle', silent = true })

return {
  {
    "folke/zen-mode.nvim",
    dependencies = {
      {
        "folke/twilight.nvim",
        opts = {
          dimming = {
            alpha = 0.25, -- amount of dimming
            -- we try to get the foreground from the highlight groups or fallback color
            color = { "Normal", "#ffffff" },
            term_bg = "#000000", -- if guibg=NONE, this will be used to calculate text color
            inactive = false, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
          },
          context = 10, -- amount of lines we will try to show around the current line
          treesitter = true, -- use treesitter when available for the filetype
          -- treesitter is used to automatically expand the visible text,
          -- but you can further control the types of nodes that should always be fully expanded
          expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
            "function",
            "method",
            "table",
            "if_statement",
            "constructor",
            "jsx_self_closing_element",
            "jsx_expression",
          },
          exclude = {}, -- exclude these filetypes
        }
      }
    },
    opts = {
      window = {
        backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
        -- height and width can be:
        -- * an absolute number of cells when > 1
        -- * a percentage of the width / height of the editor when <= 1
        -- * a function that returns the width or the height
        width = 120, -- width of the Zen window
        height = 1, -- height of the Zen window
        -- by default, no options are changed for the Zen window
        -- uncomment any of the options below, or add other vim.wo options you want to apply
        options = {
          -- signcolumn = "no", -- disable signcolumn
          number = true, -- disable number column
          relativenumber = true, -- disable relative numbers
          -- cursorline = false, -- disable cursorline
          -- cursorcolumn = false, -- disable cursor column
          -- foldcolumn = "0", -- disable fold column
          -- list = false, -- disable whitespace characters
        },
      },
      plugins = {
        twilight = { enabled = false },
      },
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      -- callback where you can add custom code when the Zen window opens
      on_open = function(win)
        -- vim.opt.list = false
      end,
      -- callback where you can add custom code when the Zen window closes
      on_close = function()
        -- vim.opt.list = true
      end,
    },
  }

}
