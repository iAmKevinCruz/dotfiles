-- toggle cmp completion
-- vim.g.cmp_toggle_flag = false -- initialize
-- local normal_buftype = function()
--   return vim.api.nvim_buf_get_option(0, "buftype") ~= "prompt"
-- end
-- local toggle_completion = function()
--   local ok, cmp = pcall(require, "cmp")
--   if ok then
--     local next_cmp_toggle_flag = not vim.g.cmp_toggle_flag
--     if next_cmp_toggle_flag then
--       print("completion on")
--     else
--       print("completion off")
--     end
--     cmp.setup({
--       enabled = function()
--         vim.g.cmp_toggle_flag = next_cmp_toggle_flag
--         if next_cmp_toggle_flag then
--           return normal_buftype
--         else
--           return next_cmp_toggle_flag
--         end
--       end,
--     })
--   else
--     print("completion not available")
--   end
-- end

-- Keymaps
vim.keymap.set('n', '<leader>tc', function()
  toggle_completion()
end, { desc = '[T]oggle [C]ompletion', silent = true })

return {
  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = "InsertEnter",
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',

      -- cmp sources plugins
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function ()
      -- [[ Configure nvim-cmp ]]
      -- See `:help cmp`
      -- local suggestion = require('supermaven-nvim.completion_preview')
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      require('luasnip.loaders.from_vscode').lazy_load()
      luasnip.config.setup {}

      local function border(hl_name)
        return {
          { "╭", hl_name },
          { "─", hl_name },
          { "╮", hl_name },
          { "│", hl_name },
          { "╯", hl_name },
          { "─", hl_name },
          { "╰", hl_name },
          { "│", hl_name },
        }
      end

      cmp.setup ({
        enabled = function ()
          local disabled = false
          disabled = disabled or (vim.bo.filetype == "org-roam-select")
          disabled = disabled or (vim.bo.filetype == "snacks_picker_input")
          return not disabled
        end,
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(),
          ['<C-p>'] = cmp.mapping.select_prev_item(),
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete {},
          -- ['<CR>'] = cmp.mapping.confirm {
          --   behavior = cmp.ConfirmBehavior.Replace,
          --   select = true,
          -- },
          ["<C-y>"] = cmp.mapping({
            i = function(fallback)
              if cmp.visible() then
                cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                -- toggle_completion()
              else
                fallback()
              end
            end,
          }),
          -- ['<Tab>'] = cmp.mapping(function(fallback)
          --   if suggestion.has_suggestion() then
          --     suggestion.on_accept_suggestion()
          --     cmp.close()
          --   else
          --     fallback()
          --   end
          -- end, { 'i', 's' }),
          -- ["<C-k>"] = cmp.mapping({
          --   i = function()
          --     if cmp.visible() then
          --       cmp.abort()
          --       toggle_completion()
          --     else
          --       cmp.complete()
          --       toggle_completion()
          --     end
          --   end,
          -- }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          -- ['<S-Tab>'] = cmp.mapping(function(fallback)
          --   if luasnip.locally_jumpable(-1) then
          --     luasnip.jump(-1)
          --   else
          --     fallback()
          --   end
          -- end, { 'i', 's' }),
        },
        sources = {
          { name = "orgmode" },
          { name = "nvim_lsp" },
          { name = "path" },
          { name = "buffer",
            option = {
              get_bufnrs = function()
                return vim.api.nvim_list_bufs()
              end
            }
          },
          { name = "luasnip" },
          { name = "nvim_lua" },
          -- { name = "supermaven" },
          { name = "codeium" },
          -- { name = "orgmode" },
        },
        formatting = {
          format = function(entry, vim_item)
            -- this wiil remove duplicated completion items
            vim_item.dup = ({
              buffer = 0,
              nvim_lsp = 0,
              nvim_lua = 0,
              luasnip = 0,
              -- supermaven = 0,
            })[entry.source.name] or 0
            return vim_item
          end,
        },
        completion = {
          completeopt = "menu,menuone",
        },
        window = {
          completion = {
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None,PmenuSel:PmenuSel",
            side_padding = 1,
            scrollbar = false,
            border = border "CmpBorder",
          },
          documentation = {
            border = border "CmpDocBorder",
            winhighlight = "Normal:CmpDoc",
          },
        },
      })
    end
  },
}
