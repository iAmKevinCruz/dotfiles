return {
  -- {
  --   'MeanderingProgrammer/markdown.nvim',
  --   name = 'render-markdown', -- Only needed if you have another plugin named markdown.nvim
  --   dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  --   -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  --   -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  --   config = function()
  --     require('render-markdown').setup({})
  --   end,
  -- },

  {
    "OXY2DEV/markview.nvim",
    lazy = false,      -- Recommended
    ft = { "markdown", "norg", "rmd", "vimwiki", "Avante" },
    dependencies = {
      -- You will not need this if you installed the
      -- parsers manually
      -- Or if the parsers are in your $RUNTIMEPATH
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.icons", -- or nvim-tree/nvim-web-devicons
    },
    opts = {
      preview = {
        filetypes = { "markdown", "norg", "rmd", "org", "vimwiki", "Avante" },
        ignore_buftypes = {},
      },
      max_length = 99999,
      list_items = {
        indent_size = function (buffer)
          if type(buffer) ~= "number" then
            return vim.bo.shiftwidth or 4;
          end

          --- Use 'shiftwidth' value.
          return vim.bo[buffer].shiftwidth or 4;
        end,
        shift_width = 2,

        marker_minus = {
          enable = true,
          add_padding = true
        },
      },
      -- block_quotes = {
      --   enable = true,
      --
      --   default = {
      --     border = "▋",
      --     border_hl = "MarkviewBlockQuoteDefault"
      --   },
      --
      --   -- callouts = {
      --   --   {
      --   --     match_string = "bible",
      --   --     callout_preview = " Bible",
      --   --     callout_preview_hl = "MarkviewBlockQuoteNote",
      --   --
      --   --     custom_title = true,
      --   --     custom_icon = " ",
      --   --
      --   --     border = "▋",
      --   --     border_hl = "MarkviewBlockQuoteDefault"
      --   --   }
      --   -- }
      -- }
    },
    config = function(_, opts)
      require("markview").setup(opts)
      -- Load the checkboxes module.
      require("markview.extras.checkboxes").setup();
      require("markview.extras.editor").setup();
      require("markview.extras.headings").setup();

      vim.keymap.set('n', '<leader>tm', '<cmd>Markview Toggle<cr>', { silent = true, desc = "[T]oggle [M]arkview" })
      -- require("markview").setup({
      --   modes = { "n", "no", "c" }, -- Change these modes
      --   -- to what you need
      --
      --   hybrid_modes = { "i" },     -- Uses this feature on
      --   -- normal mode
      --
      --   -- This is nice to have
      --   callbacks = {
      --     on_enable = function (_, win)
      --       vim.wo[win].conceallevel = 2;
      --       vim.wo[win].conecalcursor = "c";
      --     end
      --   }
      -- })
      -- require("markview").setup({
      --   modes = { "n", "i", "no", "c" },
      --   hybrid_modes = { "i" },
      --
      --   -- This is nice to have
      --   callbacks = {
      --     on_enable = function (_, win)
      --       vim.wo[win].conceallevel = 2;
      --       vim.wo[win].conecalcursor = "nc";
      --     end
      --   }
      -- })
    end,
  }
}
