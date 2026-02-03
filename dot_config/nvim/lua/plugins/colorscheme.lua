return {
  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = { -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = false, -- disables setting the background color.
      integrations = {
        dropbar = {
          enabled = true,
          color_mode = true, -- enable color for kind's texts, not just kind's icons
        },
        flash = true,
        harpoon = true,
        indent_blankline = {
          enabled = true,
          -- scope_color = "", -- catppuccin color (eg. `lavender`) Default: text
          colored_indent_levels = true,
        },
        mason = true,
        mini = {
          enabled = true,
          -- indentscope_color = "", -- catppuccin color (eg. `lavender`) Default: textlist
        },
        neogit = true,
        diffview = true,
        cmp = true,
        neotree = true,
        lsp_trouble = true,
        nvimtree = {
          enabled = true,
          show_root = true, -- makes the root folder not transparent
        },
        ufo = true,
        symbols_outline = true,
        rainbow_delimiters = true,
        telescope = {
          enabled = true,
          -- style = "nvchad"
        },
        custom_highlights = function(colors)
          return {
            MiniDiffSignDelete = { fg = colors.red },
            MiniDiffSignChange = { fg = colors.yellow },
            MiniDiffSignAdd = { fg = colors.green },
            RainbowDark = {
              fg = "#2E2E31"
            },
            RainbowBrown = {
              fg = "#272E34"
            },
            RainbowPeach = {
              fg = "#2D253C"
            },
            RainbowLightGreen = {
              fg = "#252C3B"
            },
          }
        end,
      }
    },
    config = function (_,opts)
      require("catppuccin").setup(opts)
      -- vim.cmd.colorscheme "catppuccin-mocha"
    end
  },

  {
    "dgox16/oldworld.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      terminal_colors = true, -- enable terminal colors
      variant = "oled", -- default, oled, cooler
      styles = { -- You can pass the style using the format: style = true
        comments = {}, -- style for comments
        keywords = {}, -- style for keywords
        identifiers = {}, -- style for identifiers
        functions = {}, -- style for functions
        variables = {}, -- style for variables
        booleans = {}, -- style for booleans
      },
      integrations = { -- You can disable/enable integrations
        alpha = true,
        cmp = true,
        flash = true,
        gitsigns = true,
        hop = false,
        indent_blankline = true,
        lazy = true,
        lsp = true,
        markdown = true,
        mason = true,
        navic = false,
        neo_tree = false,
        neorg = false,
        noice = true,
        notify = true,
        rainbow_delimiters = true,
        telescope = true,
        treesitter = true,
      },
      highlight_overrides = {
        DiffAdd = {
          bg = "#364143"
        },
        DiffChange = {
          bg = "#25293C"
        },
        DiffDelete = {
          bg = "#443244"
        },
        DiffText = {
          bg = "#3E4B6B"
        },
        RainbowDark = {
          fg = "#2E2E31"
        },
        RainbowBrown = {
          fg = "#272E34"
        },
        RainbowPeach = {
          fg = "#2D253C"
        },
        RainbowLightGreen = {
          fg = "#252C3B"
        },
      }
    },
    config = function (_,opts)
      require("oldworld").setup(opts)
      -- vim.cmd.colorscheme("oldworld")
    end
  },

  {
    "rebelot/kanagawa.nvim",
    lazy = false,
  },

  { 
    "rose-pine/neovim", 
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        variant = "auto", -- auto, main, moon, or dawn
        dark_variant = "main", -- main, moon, or dawn
        dim_inactive_windows = false,
        extend_background_behind_borders = true,

        enable = {
          terminal = true,
          legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
          migrations = true, -- Handle deprecated options automatically
        },

        styles = {
          bold = true,
          italic = true,
          transparency = false,
        },

        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",

          error = "love",
          hint = "iris",
          info = "foam",
          note = "pine",
          todo = "rose",
          warn = "gold",

          git_add = "foam",
          git_change = "rose",
          git_delete = "love",
          -- git_add = "#a6e3a1", -- default: "foam"
          -- git_change = "#f9e2af", -- default: "rose"
          -- git_delete = "#f38ba8", -- default: "love"
          git_dirty = "rose",
          git_ignore = "muted",
          git_merge = "iris",
          git_rename = "pine",
          git_stage = "iris",
          git_text = "rose",
          git_untracked = "subtle",

          h1 = "iris",
          h2 = "foam",
          h3 = "rose",
          h4 = "gold",
          h5 = "pine",
          h6 = "foam",
        },

        palette = {
          -- Override the builtin palette per variant
          -- moon = {
          --     base = '#18191a',
          --     overlay = '#363738',
          -- },
        },

        highlight_groups = {
          -- Comment = { fg = "foam" },
          -- VertSplit = { fg = "muted", bg = "muted" },
        },

        before_highlight = function(group, highlight, palette)
          -- Disable all undercurls
          -- if highlight.undercurl then
          --     highlight.undercurl = false
          -- end
          --
          -- Change palette colour
          -- if highlight.fg == palette.pine then
          --     highlight.fg = palette.foam
          -- end
        end,
      })

      -- vim.cmd("colorscheme rose-pine-main")
      -- vim.cmd("colorscheme rose-pine-moon")
      -- vim.cmd("colorscheme rose-pine-dawn")
      -- vim.cmd("colorscheme rose-pine")
    end
  },

  {
    "shaunsingh/nord.nvim",
    name = "nord",
    config = function()
      -- require("nord").setup()
    end
  },

  {
    'rmehri01/onenord.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local colors = require("onenord.colors").load()

      require('onenord').setup({
        theme = 'dark',
        disable = {
          background = false
        },
        custom_highlights = {
          dark = { -- only applies to the dark theme
            ["Normal"] = { bg = "#1E1F2E" }, -- the bg for the focused buffer
            ["NormalNC"] = { bg = "#1E1F2E" }, -- the bg for the focused buffer
            -- ["NormalNC"] = { bg = "#000000" }, -- the bg for the unfocused buffer
            ["MiniFilesNormal"] = { bg = "#1E1F2E" }, -- the bg for the focused buffer
            ["MiniDiffSignDelete"] = { fg = colors.red },
            ["MiniDiffSignChange"] = { fg = colors.yellow },
            ["MiniDiffSignAdd"] = { fg = colors.green },
            ["RainbowDark"] = { fg = "#2E2E31" },
            ["RainbowBrown"] = { fg = "#272E34" },
            ["RainbowPeach"] = { fg = "#2D253C" },
            ["RainbowLightGreen"] = { fg = "#252C3B" },
            ["RainbowDelimiterRed"] = { fg = "#d57780" },
          },
          light = { -- only applies to the light theme
            ["MiniDiffSignDelete"] = { fg = colors.red },
            ["MiniDiffSignChange"] = { fg = colors.yellow },
            ["MiniDiffSignAdd"] = { fg = colors.green },
            -- ["RainbowDark"] = { fg = colors.gray },
            -- ["RainbowBrown"] = { fg = colors.light_red },
            -- ["RainbowPeach"] = { fg = colors.orange },
            -- ["RainbowLightGreen"] = { fg = colors.light_green },
            -- Light mode colors (subtle/faded)
            ["RainbowDark"] = { fg = "#B8B8BB" },       -- Light gray with slight blue undertone
            ["RainbowBrown"] = { fg = "#BDC4C9" },      -- Very light grayish blue
            ["RainbowPeach"] = { fg = "#C9BDD2" },      -- Light lilac/lavender
            ["RainbowLightGreen"] = { fg = "#BFC5D0" }, -- Light grayish blue with slight purple
          },
        },
      })
      vim.cmd('colorscheme onenord')
    end,
  },

  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('github-theme').setup({
        options = {
          dim_inactive = true,
          styles = {
            types = "bold"
          },
        }
      })

      -- vim.cmd('colorscheme github_dark_dimmed')
    end,
  }
}
