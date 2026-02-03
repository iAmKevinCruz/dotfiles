-- creates a `:Picker` command to open the picker selector
vim.api.nvim_create_user_command('CdVault', function() vim.cmd("cd /Users/iMakeBabbies/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/") end, {})

return {
  "epwalsh/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/Library/Mobile Documents/com~apple~CloudDocs/Obsidian/Vault of Lykos/",
      },
      -- {
      --   name = "work",
      --   path = "~/vaults/work",
      -- },
    },
    templates = {
      folder = "Extras/Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {
        zettle = function()
          return os.date("%Y%m%d%H%M")
        end,
        daily_title = function()
          return os.date("%A, %B %d, %Y")
        end
      },
    },
    preferred_link_style = "markdown",
    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      folder = "Timestamps/Journal",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%Y-%m-%d-%a",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      alias_format = "%B %-d, %Y",
      -- Optional, default tags to add to each new daily note created.
      default_tags = { "daily-notes" },
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "Daily Note Template Nvim"
    },
    notes_subdir = "0 Inbox",
    new_notes_location = "notes_subdir",

    open_notes_in = "vsplit",
    mappings = {
      -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle check-boxes.
      ["<leader>ch"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- Smart action depending on context, either follow link or toggle checkbox.
      ["<leader><cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
      -- ["<leader>odt"] = {
      --   action = function()
      --     return vim.cmd("ObsidianToday")
      --   end,
      --   opts = { buffer = true, expr = true },
      -- },
      -- ["<leader>ott"] = {
      --   action = function()
      --     return vim.cmd("ObsidianTemplate")
      --   end,
      --   opts = { buffer = true, expr = true },
      -- },
      -- ["<leader>oo"] = {
      --   action = function()
      --     local vault = vim.fn.expand("~/obsidian-vault/")
      --     Snacks.picker.pick("grep", {
      --       cwd = vault,
      --       actions = {
      --         create_note = function(picker, item)
      --           picker:close()
      --           vim.cmd("ObsidianNew " .. picker.finder.filter.search)
      --         end,
      --       },
      --       win = {
      --         input = {
      --           keys = {
      --             ["<c-x>"] = { "create_note", desc = "Create new note", mode = { "i", "n" } },
      --           },
      --         },
      --       },
      --     })
      --   end,
      -- }
      }
    -- see below for full list of options 👇
  },
}
