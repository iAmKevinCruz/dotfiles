return {
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event= "VeryLazy",
    config = function()
      local highlight = {
        "RainbowDark",
        "RainbowBrown",
        "RainbowPeach",
        "RainbowLightGreen",
        -- "RainbowOrange"
      }

      local hooks = require "ibl.hooks"
      -- create the highlight groups in the highlight setup hook, so they are reset
      -- every time the colorscheme changes
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        -- vim.api.nvim_set_hl(0, "RainbowDark", { fg = "#393646" })
        -- vim.api.nvim_set_hl(0, "RainbowBrown", { fg = "#6D5D6E" })
        -- vim.api.nvim_set_hl(0, "RainbowPeach", { fg = "#f5e0dc" })
        -- vim.api.nvim_set_hl(0, "RainbowLightGreen", { fg = "#DFFFD8" })
        -- changed to lighter color and bg to mimic vscode catpuccin indent lines. 

        -- vim.api.nvim_set_hl(0, "RainbowDark", { fg = "#2E2E31" })
        -- vim.api.nvim_set_hl(0, "RainbowBrown", { fg = "#272E34" })
        -- vim.api.nvim_set_hl(0, "RainbowPeach", { fg = "#2D253C" })
        -- vim.api.nvim_set_hl(0, "RainbowLightGreen", { fg = "#252C3B" })
      end)
      require('ibl').setup {
        scope = {
          enabled = true,
          char = "▏"
        },
        exclude = {
          filetypes = {
            'neogit'
          }
        },
        indent = {
          highlight = highlight,
          char = "▎"
        },
        -- changed to lighter color and bg to mimic vscode catpuccin indent lines. 
        -- whitespace = {
        --   highlight = highlight,
        --   remove_blankline_trail = false,
        -- },
      }
    end
  },
}
