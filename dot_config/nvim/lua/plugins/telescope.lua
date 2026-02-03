return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    lazy = false,
    event = "VeryLazy",
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-smart-history.nvim',
      'kkharji/sqlite.lua',
      'folke/trouble.nvim'
    },
    config = function()
      local actions = require('telescope.actions')

      local send_to_qflist_and_open_in_trouble = function(prompt_bufnr)
        actions.send_selected_to_qflist(prompt_bufnr)
        vim.cmd [[Trouble qflist open focus=true]]
      end

      local function flash(prompt_bufnr)
        require("flash").jump({
          pattern = "^",
          label = { after = { 0, 0 } },
          search = {
            mode = "search",
            exclude = {
              function(win)
                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "TelescopeResults"
              end,
            },
          },
          action = function(match)
            local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)
            picker:set_selection(match.pos[1] - 1)
          end,
        })
      end

      require('telescope').setup({
        defaults = {
          history = {
            path = '~/.local/share/nvim/databases/telescope_history.sqlite3',
            limit = 100,
          },
          vimgrep_arguments = {
            "rg",
            "-L",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },
          prompt_prefix = "   ",
          -- selection_caret = "  ",
          -- entry_prefix = "  ",
          initial_mode = "insert",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          file_sorter = require("telescope.sorters").get_fuzzy_file,
          file_ignore_patterns = { "node_modules" },
          generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
          path_display = { "truncate" },
          winblend = 0,
          border = {},
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          color_devicons = true,
          set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
          file_previewer = require("telescope.previewers").vim_buffer_cat.new,
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
          -- Developer configurations: Not meant for general override
          buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
          mappings = {
            n = {
              ["q"] = actions.close,
              s = flash
            },
            i = {
              ["<c-y>"] = actions.select_default,
              ["<c-x>"] = flash,
              ["<c-s>"] = actions.select_horizontal,
              ["<S-down>"] = actions.preview_scrolling_down,
              ["<S-up>"] = actions.preview_scrolling_up,
              ["<S-right>"] = actions.toggle_selection,
              ["<M-a>"] = actions.select_all,
              ["<M-q>"] = send_to_qflist_and_open_in_trouble,
            },
          },
        },

        extensions_list = { "themes", "terms", "fzf" },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      -- Enable telescope fzf native, if installed
      pcall(require('telescope').load_extension, 'fzf')

      -- pcall(require('telescope').load_extension, 'smart_history')
      require('telescope').load_extension('smart_history')

      -- See `:help telescope.builtin`
      -- vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '[F]ind [F]iles' })
      -- vim.keymap.set('n', '<leader>fw', require('telescope.builtin').live_grep, { desc = '[F]ind [W]ord (grep)' })
      -- vim.keymap.set('n', '<leader>fW', function()
      --   local word = vim.fn.expand("<cword>")
      --   require('telescope.builtin').grep_string({ search = word })
      -- end, {desc = '[F]ind [W]ord under cursor'})
      -- vim.keymap.set('n', '<leader>fo', require('telescope.builtin').oldfiles, { desc = '[F]ind [O]ld files' })
      -- vim.keymap.set('n', '<leader>b', ":lua require('telescope.builtin').buffers({sort_mru=true,ignore_current_buffer=true})<CR>", { desc = 'Find existing [B]uffers (sorted)' })
      vim.keymap.set('n', '<leader>gt', require('telescope.builtin').git_status, { desc = 'Search [G]it s[T]atus' })
      -- vim.keymap.set('n', '<leader>fr', require('telescope.builtin').resume, { desc = '[F]ind [R]esume' })
      vim.keymap.set('n', '<leader>fR', require('telescope.actions.history').get_simple_history, { desc = '[F]ind [R]ecent History' })
      -- vim.keymap.set('n', '<leader>fz', require('telescope.builtin').current_buffer_fuzzy_find, { desc = '[F]u[Z]zy Find Current Buffer' })
      -- vim.keymap.set('n', '<leader>/', function()
      --   -- You can pass additional configuration to telescope to change theme, layout, etc.
      --   require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
      --     -- winblend = 10,
      --     previewer = false,
      --   })
      -- end, { desc = '[/] Fuzzily search in current buffer' })
      -- vim.keymap.set('n', '<leader>fqq', '<cmd>Telescope quickfix<cr>', { desc = 'Open Telescope Quickfix' })
      -- vim.keymap.set('n', '<leader>fq', '<cmd>Telescope quickfixhistory<cr>', { desc = 'Open Telescope Quickfix History' })

      -- vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
      -- vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
      -- vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
    end
  },
}
