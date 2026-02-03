-- Keymaps

return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        char = {
          jump_labels = false,
          label = { exclude = "hjkliIaArdcCvpPygSx" }
        },
        search = {
          enabled = false,
          highlight = { backdrop = true },
        }
      }
    },
    keys = {
      {
        "<leader>K",
        mode = { "n" },
        function()
          -- More advanced example that also highlights diagnostics:
          require("flash").jump({
            matcher = function(win)
              ---@param diag Diagnostic
              return vim.tbl_map(function(diag)
                return {
                  pos = { diag.lnum + 1, diag.col },
                  end_pos = { diag.end_lnum + 1, diag.end_col - 1 },
                }
              end, vim.diagnostic.get(vim.api.nvim_win_get_buf(win)))
            end,
            action = function(match, state)
              vim.api.nvim_win_call(match.win, function()
                vim.api.nvim_win_set_cursor(match.win, match.pos)
                vim.diagnostic.open_float()
              end)
              state:restore()
            end,
          })
        end,
        desc = "Flash search diagnostic"
      },
      {
        "R",
        mode = { "o", "x" },
        function() require("flash").treesitter_search() end,
        desc = "Treesitter Search"
      },
      {
        "sw",
        mode = { "n", "x" },
        function()
          -- jump to word under cursor
          require("flash").jump({pattern = vim.fn.expand("<cword>")})
        end,
        desc = "Flash highlight word undor cursor"
      },
      {
        "ss",
        mode = { "n", "x" },
        function()
          -- default options: exact mode, multi window, all directions, with a backdrop
          require("flash").jump()
        end,
        desc = "Flash"
      },
      {
        "ss",
        mode = { "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash"
      },
      {
        "<leader>ss",
        mode = { "o", "x" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash treesitter"
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "<leader>t",
        mode = { "o", "x", "n" },
        function()
          local win = vim.api.nvim_get_current_win()
          local view = vim.fn.winsaveview()
          require("flash").jump({
            action = function(match, state)
              state:hide()
              vim.api.nvim_set_current_win(match.win)
              vim.api.nvim_win_set_cursor(match.win, match.pos)
              require("flash").treesitter()
              vim.schedule(function()
                vim.api.nvim_set_current_win(win)
                vim.fn.winrestview(view)
              end)
            end,
          })
        end,
      },
      {
        "<c-s>",
        mode = { "c" },
        function() require("flash").toggle() end,
        desc = "Toggle Flash Search"
      },
    },
  },
}
