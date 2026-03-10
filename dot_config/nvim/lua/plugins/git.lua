-- Keymaps
-- Lazygit
vim.keymap.set('n', '<leader>gg', ':LazyGit <CR>', { desc = 'Open floating LazyGit', silent = true })
vim.keymap.set('n', '<leader>gf', ':LazyGitFilter <CR>', { desc = 'Open floating LazyGitFilter to see all commits', silent = true })
vim.keymap.set('n', '<leader>gfc', ':LazyGitFilterCurrentFile <CR>', { desc = 'Open floating LazyGitFilterCurrentFile to see all commits', silent = true })


-- Git Worktree
-- vim.keymap.set('n', '<leader>gw', ':lua require("telescope").extensions.git_worktree.git_worktrees()<CR>', { desc = 'Open [G]it-[W]orktrees via Telescope', silent = true })
-- vim.keymap.set('n', '<leader>gW', ':lua require("telescope").extensions.git_worktree.create_git_worktree()<CR>', { desc = 'Create new Git Worktree via Telescope', silent = true })

-- Git fugitive
-- vim.keymap.set('n', '<leader>gc', '<CMD>Git commit<CR>', { desc = '[G]it [C]ommit via Fugitive', silent = true })
-- vim.keymap.set('n', '<leader>gp', '<CMD>Git push<CR>', { desc = '[G]it [P]ush via Fugitive', silent = true })

return {
  'tpope/vim-fugitive',
  -- 'tpope/vim-rhubarb',

  -- I use gitsigns just for the current line blame
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    ft = { "gitcommit", "diff" },
    init = function()
      -- load gitsigns only when a git file is opened
      vim.api.nvim_create_autocmd({ "BufRead" }, {
        group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
        callback = function()
          local buf_path = vim.fn.expand "%:p:h"
          if buf_path:match("^%w+://") then return end
          vim.fn.system("git -C " .. '"' .. buf_path .. '"' .. " rev-parse")
          if vim.v.shell_error == 0 then
            vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
            vim.schedule(function()
              require("lazy").load { plugins = { "gitsigns.nvim" } }
            end)
          end
        end,
      })
    end,
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "󰍵" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "│" },
      },
      current_line_blame = true,
      signcolumn = false,  -- Toggle with `:Gitsigns toggle_signs`
      numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
      linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
      word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>hp', require('gitsigns').preview_hunk, { buffer = bufnr, desc = 'Preview git hunk' })
        vim.keymap.set('n', '<leader>td', require("gitsigns").toggle_deleted, { desc = 'Toggle deleted', silent = true })

        -- don't override the built-in and fugitive keymaps
        local gs = package.loaded.gitsigns
        vim.keymap.set({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to next hunk' })
        vim.keymap.set({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, buffer = bufnr, desc = 'Jump to previous hunk' })
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },

  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    lazy = false,
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = false,
        file_panel = {
          listing_style = "list"
        }
      })

      -- can use this to replace the `origin/main` so the `main` can be dynamically picked.
      local function get_default_branch_name()
        local res = vim
          .system({ 'git', 'rev-parse', '--verify', 'main' }, { capture_output = true })
          :wait()
        return res.code == 0 and 'main' or 'master'
      end

      vim.keymap.set('n', '<leader>gdd', '<CMD>DiffviewOpen<CR>', { desc = 'Open DiffView working tree' })
      vim.keymap.set('n', '<leader>gdm', '<CMD>DiffviewOpen HEAD..origin/main<CR>', { desc = 'Open DiffView compare main with HEAD' })
      vim.keymap.set('n', '<leader>gdhh', '<CMD>DiffviewFileHistory<CR>', { desc = 'Open DiffView History for Repo' })
      vim.keymap.set('n', '<leader>gdhf', '<CMD>DiffviewFileHistory --follow %<CR>', { desc = 'Open DiffView History for current file' }) -- the `--follow` flag follows any file name change
      vim.keymap.set('v', '<leader>gdhl', "<ESC><CMD>'<,'>DiffviewFileHistory --follow<CR>", { desc = 'Open DiffView History for selection' }) -- the `--follow` flag follows any file name change
      vim.keymap.set('n', '<leader>gdhl', '<CMD>.DiffviewFileHistory --follow<CR>', { desc = 'Open DiffView History for current line' }) -- the `--follow` flag follows any file name change
    end
  },

  {
    "clabby/difftastic.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- optional: only needed for :DifftPick
      "folke/snacks.nvim",
    },
    config = function()
      require("difftastic-nvim").setup({
        download = true, -- Auto-download pre-built binary
        snacks_picker = {
          enabled = true,
        },
      })
    end,
  },

  {
    "NeogitOrg/neogit",
    event = "VeryLazy",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",         -- required
      -- "nvim-telescope/telescope.nvim", -- optional
      "ibhagwan/fzf-lua",
      "sindrets/diffview.nvim",        -- optional
    },
    config = function()
      require('neogit').setup({
        graph_style = "unicode",
      })
      vim.keymap.set('n', '<leader>nn', '<CMD>Neogit<CR>', { desc = 'Open [N]eogit' })
    end
  },

  {
    'kdheepak/lazygit.nvim',
    lazy = false,
  },

  {
    'swaits/lazyjj.nvim',
    dependencies = 'nvim-lua/plenary.nvim',
    -- lazy = false,
    opts = {
      mapping = '<leader>jj'
    },
    -- config = function()
    --   require('lazyjj').setup()
    -- end
  },

  {
    "mrdwarf7/lazyjui.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    keys = {
      {
        -- Default is <Leader>jj
        -- An example of a custom mapping to open the interface
        "<Leader>lj",
        function()
          require("lazyjui").open()
        end,
      },
    },
    -- You can also simply pass `opts = true` or `opts = {}` and the default options will be used
    ---@type lazyjui.Opts
    opts =  {
      -- Optionally (default):
      border = {
        chars = { "", "", "", "", "", "", "", "" }, -- either set all to empty to remove the entire outer border (or nil/{})
        -- Use custom set of border chars (must be 8 long)
        -- border_chars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
        thickness = 0, -- This handles the border of the 'outer' window it's nested inside, generally this is invisible
        -- See `:h nvim_win_set_hl_ns()` and associated docs for more details
        -- previous option was: "FloatBorder:LazyJuiBorder,NormalFloat:LazyJuiFloat", -- up to you how to set
        winhl_str = "",
      },

      -- The below options will now produce a warning advising to use the above syntax instead.
      -- they'll work for a while; but note that the internal mapping will be removed in the future.
      ---@deprecated use 'opts.border.chars' instead
      -- border_chars = {},
      ---@deprecated use 'opts.border.thickness' instead
      -- border_thickness = 0,
      ---@deprecated use 'opts.border.winhl_str' instead
      -- border_winhl_str = "FloatBorder:LazyJuiBorder,NormalFloat:LazyJuiFloat",

      -- Support for custom command pass-through
      -- In this example, we use the revset `all()` command
      --
      -- Will default to just `jjui`
      cmd = { "jjui" },
      height = 0.8, -- default is 0.8,
      width = 0.9, -- default is 0.9,
      winblend = 0, -- default is 0 (fully opaque). Set to 100 for fully transparent (not recommended though).
      -- hide_only = false, -- This is **experimental** and is subject to changing, currently not available
      use_default_keymaps = true, -- setting this to false will result in no default mappings at all
    }
  },

  {
    "yannvanhalewyn/jujutsu.nvim",
  },

  {
    "nicolasgb/jj.nvim",
    dependencies = {
      "folke/snacks.nvim", -- Optional, only needed if you use pickers

      -- One of these two if you want to use them as your diff backend
      "esmuellert/codediff.nvim",
      "sindrets/diffview.nvim",
    },

    config = function()
      local jj = require("jj")
      jj.setup({
        terminal = {
          cursor_render_delay = 10, -- Adjust if cursor position isn't restoring correctly
        },
        diff = {
          backend = "codediff"
        },
        cmd = {
          describe = {
            editor = {
              type = "buffer",
              keymaps = {
                close = { "q", "<Esc>", "<C-c>" }, -- Enable <Esc> in the editor
              }
            }
          },
          bookmark = {
            prefix = "feat/"
          },
          keymaps = {
            log = {
              checkout = "<CR>",
              describe = "d",
              diff = "<S-d>",
              abandon = "<S-a>",
              fetch = "<S-f>",
            },
            status = {
              open_file = "<CR>",
              restore_file = "<S-x>",
            },
            close = { "q", "<Esc>" },
          },
        },
        highlights = {
          -- Customize colors if desired
          modified = { fg = "#89ddff" },
        }
      })



      -- Core commands
      local cmd = require("jj.cmd")
      vim.keymap.set("n", "<leader>jd", cmd.describe, { desc = "JJ describe" })
      vim.keymap.set("n", "<leader>jl", cmd.log, { desc = "JJ log" })
      vim.keymap.set("n", "<leader>je", cmd.edit, { desc = "JJ edit" })
      vim.keymap.set("n", "<leader>jn", cmd.new, { desc = "JJ new" })
      vim.keymap.set("n", "<leader>js", cmd.status, { desc = "JJ status" })
      vim.keymap.set("n", "<leader>sj", cmd.squash, { desc = "JJ squash" })
      vim.keymap.set("n", "<leader>ju", cmd.undo, { desc = "JJ undo" })
      vim.keymap.set("n", "<leader>jy", cmd.redo, { desc = "JJ redo" })
      vim.keymap.set("n", "<leader>jr", cmd.rebase, { desc = "JJ rebase" })
      vim.keymap.set("n", "<leader>jbc", cmd.bookmark_create, { desc = "JJ bookmark create" })
      vim.keymap.set("n", "<leader>jbd", cmd.bookmark_delete, { desc = "JJ bookmark delete" })
      vim.keymap.set("n", "<leader>jbm", cmd.bookmark_move, { desc = "JJ bookmark move" })
      vim.keymap.set("n", "<leader>jts", cmd.tag_set, { desc = "JJ tag set" })
      vim.keymap.set("n", "<leader>jtd", cmd.tag_delete, { desc = "JJ tag delete" })
      vim.keymap.set("n", "<leader>jtp", cmd.tag_push, { desc = "JJ tag push" })
      vim.keymap.set("n", "<leader>ja", cmd.abandon, { desc = "JJ abandon" })
      vim.keymap.set("n", "<leader>jf", cmd.fetch, { desc = "JJ fetch" })
      vim.keymap.set("n", "<leader>jp", cmd.push, { desc = "JJ push" })
      vim.keymap.set("n", "<leader>jpr", cmd.open_pr, { desc = "JJ open PR from bookmark in current revision or parent" })
      vim.keymap.set("n", "<leader>jpl", function()
        cmd.open_pr { list_bookmarks = true }
      end, { desc = "JJ open PR listing available bookmarks" })


      -- Diff commands
      local diff = require("jj.diff")
      vim.keymap.set("n", "<leader>df", function() diff.open_vdiff() end, { desc = "JJ diff current buffer" })
      vim.keymap.set("n", "<leader>dF", function() diff.open_hsplit() end, { desc = "JJ hdiff current buffer" })

      -- Pickers
      local picker = require("jj.picker")
      vim.keymap.set("n", "<leader>gj", function() picker.status() end, { desc = "JJ Picker status" })
      vim.keymap.set("n", "<leader>jgh", function() picker.file_history() end, { desc = "JJ Picker history" })

      -- Some functions like `log` can take parameters
      vim.keymap.set("n", "<leader>jL", function()
        cmd.log {
          revisions = "'all()'", -- equivalent to jj log -r ::
        }
      end, { desc = "JJ log all" })


      -- This is an alias i use for moving bookmarks its so good
      vim.keymap.set("n", "<leader>jt", function()
        cmd.j "tug"
        cmd.log {}
      end, { desc = "JJ tug" })

    end,

  }

}
