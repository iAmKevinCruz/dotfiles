-- mostly used in Neovide
vim.api.nvim_create_user_command('CdOrg', function() vim.cmd("cd ~/org/") end, {})

-- this is to allow to create new heading/list item when I press opt + enter
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'org',
  callback = function()
    vim.keymap.set('i', '<M-CR>', '<cmd>lua require("orgmode").action("org_mappings.meta_return")<CR>', {
      silent = true,
      buffer = true,
    })
  end,
})

return {
  {
    'nvim-orgmode/orgmode',
    event = 'VeryLazy',
    ft = { 'org' },
    config = function()
      -- Setup orgmode
      require('orgmode').setup({
        org_agenda_files = '~/org/**/*',
        org_default_notes_file = '~/org/inbox.org',
        -- org_agenda_files = '~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/**/*',
        -- org_default_notes_file = '~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/inbox.org',
        org_capture_templates = {
          t = {
            description = 'Todos',
            template = '** TODO %?\n %u\n',
            -- target = '~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/inbox.org',
            target = '~/inbox.org',
            headline = 'Inbox',
          },
          m = {
            description = 'Meetings',
            template = '** MEETING %? :meeting:\n SCHEDULED: %T\n *** Attendees: \n*** Notes: \n %u\n',
            -- target = '~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/Timestamps/Meetings/meetings.org',
            target = '~/org/Timestamps/Meetings/meetings.org',
            headline = 'Meetings',
          },
          n = {
            description = 'Notes',
            template = '** %? \n %u\n',
            -- target = '~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/inbox.org',
            target = '~/org/inbox.org',
            headline = 'Inbox',
          },
          p = {
            description = 'Notes',
            template = '** %? \n %u\n',
            -- target = '~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/inbox.org',
            target = '~/org/inbox.org',
            headline = 'Inbox',
          },
        },
        org_todo_keywords = {'TODO(t)', 'PROGRESS(p)', 'AWAP(a)', '|', 'DONE(d)', 'CANCELLED(c)', 'HOLD(h)', 'MEETING(m)'},
        org_todo_keyword_faces = {
          TODO = ':foreground #BF616A :weight bold', -- overrides builtin color for `TODO` keyword
          PROGRESS = ':foreground #B48EAD :weight bold',
          AWAP = ':foreground #81A1C1 :weight bold', -- AwaitingApproval
          DONE = ':foreground #A3BE8C :weight bold :slant italic',
          HOLD = ':foreground #D08770 :weight bold :slant italic',
          CANCELLED = ':foreground #C7CFF2 :weight bold :slant italic',
          MEETING = ':foreground #89dceb :weight bold',
        },
        org_startup_indented = true,
        org_indent_mode_turns_off_org_adapt_indentation = true,
        org_hide_leading_stars = true,
        org_indent_mode_turns_on_hiding_stars = true,
        org_id_ts_format = "%Y%m%d%H%M%S",
        org_id_method = "ts", -- uses timestamp as the id
        org_blank_before_new_entry = {
          heading = true,
          plain_list_item = false,
        },
      })
    end,
  },

  {
    "chipsenkbeil/org-roam.nvim",
    -- tag = "0.1.1",
    dependencies = {
      {
        "nvim-orgmode/orgmode",
        -- tag = "0.3.7",
        -- tag = "0.5.3",
      },
    },
    config = function()
      require("org-roam").setup({
        directory = "~/org",
        -- directory = "~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos",
        -- optional
        -- org_files = {
        --   "~/another_org_dir",
        --   "~/some/folder/*.org",
        --   "~/a/single/org_file.org",
        -- }
        extensions = {
          dailies = {
            directory = "Timestamps/Journal",
            templates = {
              d = {
                description = "default",
                template = "%?",
                target = "%<%Y-%m-%d-%a>.org",
              },
              -- m = {
              --   description = "meeting",
              --   template = "%?",
              --   target = "../Meetings/%<%Y-%m-%d> %[slug].org",
              -- },
            },
          },
        },
        templates = {
          d = {
            description = "default",
            template = "%?\n",
            target = "0 Inbox/%[title].org",
          },
          p = {
            description = "people",
            template = "%?",
            target = "Extras/People/%[title].org",
          },
          P = {
            description = "project",
            template = "%?",
            target = "1 Projects/%[title].org",
          },
          m = {
            description = "meeting",
            template = "%?",
            target = "Timestamps/Meetings/%<%Y-%m-%d> %[title].org",
          },
        },
        bindings = {
          goto_next_node = "",
        },
      })
    end
  },

  {
    'akinsho/org-bullets.nvim',
    config = function()
      require('org-bullets').setup()
    end
  },

  {
    'andreadev-it/orgmode-multi-key',
    event = "VeryLazy",
    config = function()
      require('orgmode-multi-key').setup()
    end
  }
}
