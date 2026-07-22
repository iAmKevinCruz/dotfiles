-- obsidian.nvim — community-maintained fork (epwalsh's original is unmaintained).
-- Vault = ~/org, shared with emacs obsidian.el + org-node. Loads only for markdown,
-- so .org files stay untouched. Rendering is left to markview.nvim (ui disabled here).
return {
  "obsidian-nvim/obsidian.nvim",
  version = "*", -- latest release, not bleeding-edge main
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "org",
        path = "~/org",
      },
    },

    -- New notes (incl. unfound wikilink targets) land in the inbox,
    -- matching emacs obsidian-create-unfound-files-in-inbox.
    notes_subdir = "0 Inbox",
    new_notes_location = "notes_subdir",

    -- Use [[wikilinks]] everywhere, like the Obsidian app and emacs config.
    preferred_link_style = "wiki",

    daily_notes = {
      folder = "Timestamps/Journal",
      date_format = "%Y-%m-%d",
      alias_format = "%B %-d, %Y",
      default_tags = { "daily-notes" },
      template = "Daily Note Template Nvim",
    },

    templates = {
      folder = "Extras/Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
      substitutions = {
        zettle = function()
          return os.date("%Y%m%d%H%M")
        end,
        daily_title = function()
          return os.date("%A, %B %d, %Y")
        end,
      },
    },

    -- Don't let obsidian.nvim auto-rewrite YAML frontmatter on save —
    -- avoids it munging existing notes across the mixed org/markdown vault.
    disable_frontmatter = true,

    -- Picker + completion: use what's already installed.
    picker = {
      name = "snacks.pick",
    },
    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    -- markview.nvim handles in-buffer markdown rendering; disable obsidian's
    -- own concealment/UI so the two don't fight over the same lines.
    ui = {
      enable = false,
    },

    -- New-style :Obsidian <subcommand> dispatch (legacy :ObsidianFoo off).
    legacy_commands = false,

    -- Footer: note stats as virtual text at buffer end. {{modified}} is a
    -- custom token injected in `config` below — a live mtime swap-in, like a
    -- Dataview `$= dv.current().file.mtime` but actually evaluated here.
    footer = {
      enabled = true,
      format = "{{backlinks}} backlinks  {{properties}} properties  {{words}} words  {{chars}} chars  ·  modified {{modified}}",
    },

    mappings = {
      -- 'gf' follows markdown/wiki links within the vault.
      ["gf"] = {
        action = function()
          return require("obsidian").util.gf_passthrough()
        end,
        opts = { noremap = false, expr = true, buffer = true },
      },
      -- Toggle checkboxes.
      ["<leader>ch"] = {
        action = function()
          return require("obsidian").util.toggle_checkbox()
        end,
        opts = { buffer = true },
      },
      -- <leader><cr>: follow link or toggle checkbox depending on context.
      ["<leader><cr>"] = {
        action = function()
          return require("obsidian").util.smart_action()
        end,
        opts = { buffer = true, expr = true },
      },
    },
  },
  config = function(_, opts)
    require("obsidian").setup(opts)

    -- Extend the footer's status table with a {{modified}} token = file mtime.
    -- The footer substitutes any key returned by Note:status into the format
    -- string, so wrapping it is the only supported way to add custom fields.
    local Note = require("obsidian.note")
    local orig_status = Note.status
    Note.status = function(self, update_backlink, callback)
      local path = tostring(self.path)
      local function decorate(status)
        local stat = vim.uv.fs_stat(path)
        status.modified = stat and os.date("%Y-%m-%d %H:%M", stat.mtime.sec) or "?"
        return status
      end
      if callback then
        return orig_status(self, update_backlink, function(status)
          callback(decorate(status))
        end)
      end
      return decorate(orig_status(self, update_backlink))
    end
  end,
}
