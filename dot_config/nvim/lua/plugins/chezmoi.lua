return {
  "xvzc/chezmoi.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("chezmoi").setup({
      edit = {
        watch = false,
        force = false,
      },
      events = {
        on_open = {
          notification = { enable = true, msg = "Opened a chezmoi-managed file", opts = {} },
        },
        on_watch = {
          notification = { enable = true, msg = "This file will be automatically applied", opts = {} },
        },
        on_apply = {
          notification = { enable = true, msg = "chezmoi applied", opts = {} },
        },
      },
    })
  end,
  init = function()
    vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
      pattern = { os.getenv("HOME") .. "/.local/share/chezmoi/*" },
      callback = function(ev)
        vim.schedule(function()
          require("chezmoi.commands.__edit").watch(ev.buf)
        end)
      end,
    })
  end,
}
