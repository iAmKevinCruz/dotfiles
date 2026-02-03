
return {
  --[[
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      settings = {
        save_on_toggle = true,
        sync_on_ui_close = true,
      },
    },
    config = function(_, opts)
      local harpoon = require("harpoon")
      harpoon:setup()

      -- vim.keymap.set("n", "<leader>A", function() harpoon:list():add() end)
      -- vim.keymap.set("n", "<leader>a", function() 
      --   harpoon.ui:toggle_quick_menu(harpoon:list()) 
      -- end, { desc = "Open Harpoon list" })

      for i=0,9 do
        vim.keymap.set("n", '<M-'..i ..'>', function ()
          harpoon:list():select(i)
        end, { desc = "Open Harpoon item: " .. i })
      end

      -- Toggle previous & next buffers stored within Harpoon list
      -- vim.keymap.set("n", "g<", function() harpoon:list():prev() end)
      -- vim.keymap.set("n", "g>", function() harpoon:list():next() end)

      harpoon:extend({
        UI_CREATE = function(cx)
          vim.keymap.set("n", "gv", function()
            harpoon.ui:select_menu_item({ vsplit = true })
          end, { buffer = cx.bufnr })

          vim.keymap.set("n", "gs", function()
            harpoon.ui:select_menu_item({ split = true })
          end, { buffer = cx.bufnr })

          vim.keymap.set("n", "gt", function()
            harpoon.ui:select_menu_item({ tabedit = true })
          end, { buffer = cx.bufnr })
        end,
      })

      -- basic telescope configuration
      local conf = require("telescope.config").values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require("telescope.pickers").new({}, {
          prompt_title = "Harpoon",
          finder = require("telescope.finders").new_table({
            results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        }):find()
      end

      vim.keymap.set("n", "<leader>ta", function()
        toggle_telescope(harpoon:list()) end, { desc = "Open harpoon telescope" })
    end
  }
  ]]
}
