return {
  --[[ {
    'nvim-orgmode/orgmode',
    event="VeryLazy",
    config = function()
      require('orgmode').setup_ts_grammar()

      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = {'org'},
        },
        ensure_installed = {'org'}, -- Or run :TSUpdate org
      }

      local Menu = require('custom.org-modern.menu')

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'org',
        group = vim.api.nvim_create_augroup('orgmode_telescope_nvim', { clear = true }),
        callback = function()
          vim.keymap.set('n', '<leader>or', require('telescope').extensions.orgmode.refile_heading)
        end,
      })

      require('orgmode').setup({
        ui = {
          menu = {
            handler = function(data)
              Menu:new({
                window = {
                  margin = { 1, 0, 1, 0 },
                  padding = { 0, 1, 0, 1 },
                  title_pos = "center",
                  border = "single",
                  zindex = 1000,
                },
                icons = {
                  separator = "➜",
                },
              }):open(data)
            end,
          },
        },
        -- org_agenda_files = {'~/orgmode_nvim/org/*', '~/my-orgs/**/*'},
        -- org_default_notes_file = '~/orgmode_nvim/org/refile.org',
        org_agenda_files = {'~/org/*', '~/my-orgs/**/*'},
        org_default_notes_file = '~/org/refile.org',
        org_capture_templates = {
          t = {
            description = 'Todos',
            template = '** TODO %?\n %u\n',
            target = '~/org/todos.org',
            headline = 'Inbox',
          },
          m = {
            description = 'Meetings',
            template = '** MEETING %? :meeting:\n SCHEDULED: %T\n Meeting with: \n*** Notes: \n %u\n',
            target = '~/org/meetings.org',
            headline = 'Meetings',
          },
          n = {
            description = 'Notes',
            template = '** %? :notes:\n %u',
            target = '~/org/meetings.org'
          },
        },
        org_todo_keywords = {'TODO(t)', 'PROGRESS(p)', '|', 'DONE(d)', 'CANCELLED(c)', 'WAITING(w)', 'MEETING(m)'},
        org_todo_keyword_faces = {
          TODO = ':foreground #DF8C97 :weight bold', -- overrides builtin color for `TODO` keyword
          PROGRESS = ':foreground #C0A1F0 :weight bold',
          DONE = ':foreground #B1D99C :weight bold :slant italic',
          WAITING = ':foreground #EAAC86 :weight bold :slant italic',
          CANCELLED = ':foreground #C7CFF2 :weight bold :slant italic',
          MEETING = ':foreground #89dceb :weight bold',
        },
        mappings = {
          capture = {
            org_capture_refile = 'R',
            org_capture_kill = 'Q'
          },
          org = {
            org_refile = 'R',
          },
        },
        calendar_week_start_day = 0,
        win_split_mode = function(name)
          local bufnr = vim.api.nvim_create_buf(false, true)
          --- Setting buffer name is required
          vim.api.nvim_buf_set_name(bufnr, name)

          local fill = 0.8
          local width = math.floor((vim.o.columns * fill))
          local height = math.floor((vim.o.lines * fill))
          local row = math.floor((((vim.o.lines - height) / 2) - 1))
          local col = math.floor(((vim.o.columns - width) / 2))

          vim.api.nvim_open_win(bufnr, true, {
            relative = "editor",
            width = width,
            height = height,
            row = row,
            col = col,
            style = "minimal",
            border = "rounded"
          })
        end
      })
    end
  },

  {
    'joaomsa/telescope-orgmode.nvim',
    event = "VeryLazy",
    config = function()
      require('telescope').load_extension('orgmode')
    end
  },

  {
    'akinsho/org-bullets.nvim',
    event = 'VeryLazy',
    config = function()
      require('org-bullets').setup()
    end
  },

  {
    {
      'andreadev-it/orgmode-multi-key',
      event = "VeryLazy",
      config = function()
        require('orgmode-multi-key').setup()
      end
    }
  }, ]]
}
