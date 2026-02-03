return {
  --[[ {
    "nvim-neorg/neorg",
    cmd = "Neorg",
    build = ":Neorg sync-parsers",
    opts = {
      load = {
        ["core.defaults"] = {}, -- Loads default behaviour
        ["core.concealer"] = {}, -- Adds pretty icons to your documents
        ["core.esupports.metagen"] = {
          config = {
            type = "auto",
          },
        },
        ["core.journal"] = {
          config = {
            journal_folder = "journal",
            strategy = "flat",
            -- toc_format = function()
            --   return { "yy", "mm", "dd", "link", "title" }
            -- end,
            use_template = false,
            workspace = "personal"
          },
        },
        ["core.summary"] = {
          config = {
            strategy = "metagen",
          },
        },
        ["core.keybinds"] = {
          config = {
            neorg_leader = ",",
            hook = function (keybinds)
              keybinds.unmap("norg", "i", "<TAB>")
              keybinds.remap_event("norg", "i", "<M-a>", "core.itero.next-iteration")

              -- Mapping for the journal module
              keybinds.map("norg", "n", ",ot", "<cmd>Neorg journal today<CR>") -- open journal on today
              keybinds.map("norg", "n", ",oy", "<cmd>Neorg journal yesterday<CR>") -- open journal on yesterday
              keybinds.map("norg", "n", ",om", "<cmd>Neorg journal tomorrow<CR>") -- open journal on tomorrow
              keybinds.map("norg", "n", ",oj", "<cmd>Neorg journal toc open<CR>") -- open journal toc
              keybinds.map("norg", "n", ",uj", "<cmd>Neorg journal toc update<CR>") -- update journal toc

              -- Mapping for Neorg Telescope plugin
              keybinds.map("norg", "n", ",fw", "<cmd>Telescope neorg find_linkable<CR>") -- find linkable items with telescope
              keybinds.map("norg", "n", ",ff", "<cmd>Telescope neorg find_neorg_files<CR>") -- find neorg files with telescope
              keybinds.map("norg", "n", ",ww", "<cmd>Telescope neorg switch_workspace<CR>") -- switch to neorg workspace with telescope
              keybinds.map("norg", "i", "<C-i>", "<cmd>Telescope neorg insert_link<CR>") -- find and insert link with telescope

              local neorg_callbacks = require("neorg.callbacks")

              neorg_callbacks.on_event("core.keybinds.events.enable_keybinds", function(_, keys)
                -- Map all the below keybinds only when the "norg" mode is active
                keys.map_event_to_mode("norg", {
                  n = { -- Bind keys in normal mode
                    -- { "<C-s>", "core.integrations.telescope.find_linkable" },
                  },

                  i = { -- Bind in insert mode
                    -- { "<M-n>", "core.integrations.telescope.insert_link" },
                    { "<TAB>", "" },
                  },
                }, {
                    silent = true,
                    noremap = true,
                  })
              end)
            end,
          },
        }, -- Adds pretty icons to your documents
        ["core.integrations.telescope"] = {},
        ["core.dirman"] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              notes = "~/notes",
              projects = "~/projects",
              personal = "~/personal",
              work_log = "~/work_log"
            },
            default_workspace = 'work_log'
          },
        },
      },
    },
    dependencies = { { "nvim-lua/plenary.nvim" }, { "nvim-neorg/neorg-telescope" }  },
  } ]]
}
