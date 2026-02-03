return {
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    requires = {
      "echasnovski/mini.icons", -- or nvim-tree/nvim-web-devicons
      opt = true
    },
    config = function()
      local p = require("oldworld.palette")

      local oldworld_theme = {
        normal = {
          a = { fg = p.bg, bg = p.red, gui = "bold" },
          b = { fg = p.fg, bg = p.gray2 },
          c = { fg = p.fg, bg = p.gray1 },
        },
        command = { a = { fg = p.bg, bg = p.yellow, gui = "bold" } },
        insert = { a = { fg = p.bg, bg = p.purple, gui = "bold" } },
        visual = { a = { fg = p.bg, bg = p.magenta, gui = "bold" } },
        terminal = { a = { fg = p.bg, bg = p.green, gui = "bold" } },
        replace = { a = { fg = p.bg, bg = p.orange, gui = "bold" } },
        inactive = {
          a = { fg = p.gray4, bg = p.bg_dark, gui = "bold" },
          b = { fg = p.gray4, bg = p.bg_dark },
          c = { fg = p.gray4, bg = p.bg_dark },
        },
      }

      local p = require("rose-pine.palette")
      local config = require("rose-pine.config")

      local bg_base = p.base
      if config.options.styles.transparency then
        bg_base = "NONE"
      end

      local rose_pine_theme = {
        normal = {
          a = { bg = p.rose, fg = p.base, gui = "bold" },
          b = { bg = p.overlay, fg = p.rose },
          c = { bg = bg_base, fg = p.text },
        },
        insert = {
          a = { bg = p.foam, fg = p.base, gui = "bold" },
          b = { bg = p.overlay, fg = p.foam },
          c = { bg = bg_base, fg = p.text },
        },
        visual = {
          a = { bg = p.iris, fg = p.base, gui = "bold" },
          b = { bg = p.overlay, fg = p.iris },
          c = { bg = bg_base, fg = p.text },
        },
        replace = {
          a = { bg = p.pine, fg = p.base, gui = "bold" },
          b = { bg = p.overlay, fg = p.pine },
          c = { bg = bg_base, fg = p.text },
        },
        command = {
          a = { bg = p.love, fg = p.base, gui = "bold" },
          b = { bg = p.overlay, fg = p.love },
          c = { bg = bg_base, fg = p.text },
        },
        inactive = {
          a = { bg = bg_base, fg = p.muted, gui = "bold" },
          b = { bg = bg_base, fg = p.muted },
          c = { bg = bg_base, fg = p.muted },
        },
      }

      require('lualine').setup {
        options = {
          -- theme = "catppuccin",
          -- theme = rose_pine_theme,
          -- theme = oldworld_theme,
          -- component_separators = '|',
          -- section_separators = '',
          -- component_separators = { left = '', right = ''},
          -- section_separators = { left = '', right = ''},
          -- component_separators = { left = '', right = ''},
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
          globalstatus = false,
          ignore_focus = {"neo-tree", "trouble", "Avante"},
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {'filename'},
          lualine_x = {'location'},
          lualine_y = {},
          lualine_z = {}
        },
        sections = {
          lualine_c = {
            {
              'filename',
              file_status = true,      -- Displays file status (readonly status, modified status)
              newfile_status = false,  -- Display new file status (new file means no write after created)
              path = 4,                -- 0: Just the filename
              -- 1: Relative path
              -- 2: Absolute path
              -- 3: Absolute path, with tilde as the home directory
              -- 4: Filename and parent dir, with tilde as the home directory

              shorting_target = 40,    -- Shortens path to leave 40 spaces in the window
              -- for other components. (terrible name, any suggestions?)
              symbols = {
                modified = '●',      -- Text to show when the file is modified.
                readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
                unnamed = '[No Name]', -- Text to show for unnamed buffers.
                newfile = '[New]',     -- Text to show for newly created file before first write
              }
            },
          },
          lualine_x = {
            -- {
            --   'fileformat',
            --   symbols = {
            --     unix = '', -- e712
            --     dos = '',  -- e70f
            --     mac = '',  -- e711
            --   },
            -- },
            {
              'filetype',
              colored = true,   -- Displays filetype icon in color if set to true
              icon_only = false, -- Display only an icon for filetype
              icon = { align = 'right' }, -- Display filetype icon on the right hand side
              -- icon =    {'X', align='right'}
              -- Icon string ^ in table is ignored in filetype component
            },
          },
        },
        -- sections = {
        --   lualine_x = {
        --     -- {
        --     --   require("noice").api.status.message.get_hl,
        --     --   cond = require("noice").api.status.message.has,
        --     -- },
        --     -- {
        --     --   require("noice").api.status.command.get,
        --     --   cond = require("noice").api.status.command.has,
        --     --   color = { fg = "#ff9e64" },
        --     -- },
        --     {
        --       require("noice").api.status.mode.get,
        --       cond = require("noice").api.status.mode.has,
        --       color = { fg = "#ff9e64" },
        --     },
        --     {
        --       require("noice").api.status.search.get,
        --       cond = require("noice").api.status.search.has,
        --       color = { fg = "#ff9e64" },
        --     },
        --   },
        -- },
      }
    end
  }
}
