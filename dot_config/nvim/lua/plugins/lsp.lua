-- Keymaps

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/nvim-cmp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "j-hui/fidget.nvim",
    },

    config = function()
      -- local cmp = require('cmp')
      local lspconfig = require("lspconfig")
      local cmp_lsp = require("cmp_nvim_lsp")
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        cmp_lsp.default_capabilities())

      require("fidget").setup({})
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          -- "rust_analyzer",
          "ts_ls",
          "emmet_ls",
          "tailwindcss",
          "gopls",
          -- "prettierd",
          -- "prettier",
          "shopify_theme_ls",
        },
        handlers = {
          function(server_name) -- default handler (optional)

            require("lspconfig")[server_name].setup {
              capabilities = capabilities,
            }
          end,

          ['rust_analyzer'] = function() end,

          ["lua_ls"] = function()
            lspconfig.lua_ls.setup {
              capabilities = capabilities,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "vim", "it", "describe", "before_each", "after_each" },
                  }
                }
              }
            }
          end,
          ["emmet_ls"] = function()
            lspconfig.emmet_ls.setup {
              capabilities = capabilities,
              filetypes = { 'html', 'typescriptreact', 'javascriptreact', 'css', 'sass', 'scss', 'liquid' },
              init_options = {
                html = {
                  options = {
                    -- for possible options, see: https://github.com/emmetio/emmet/blob/master/src/config.ts#l79-l267
                    ["bem.enabled"] = true,
                  },
                },
              },
            }
          end,
          --[[ ["rust_analyzer"] = function()
            lspconfig.emmet_ls.setup({
              capabilities = capabilities,
              filetypes = {"rust"},
              root_dir = 
            })
          end, ]]
        }
      })


      -- local cmp_select = { behavior = cmp.SelectBehavior.Select }
      --
      -- cmp.setup({
      --   snippet = {
      --     expand = function(args)
      --       require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      --     end,
      --   },
      --   mapping = cmp.mapping.preset.insert({
      --     ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
      --     ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
      --     ['<C-y>'] = cmp.mapping.confirm({ select = true }),
      --     ["<C-Space>"] = cmp.mapping.complete(),
      --   }),
      --   sources = cmp.config.sources({
      --     { name = 'nvim_lsp' },
      --     { name = 'luasnip' }, -- For luasnip users.
      --   }, {
      --       { name = 'buffer' },
      --     })
      -- })

      vim.diagnostic.config({
        -- update_in_insert = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
        virtual_text = false,
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          vim.keymap.set('n', '<leader>ra', vim.lsp.buf.rename, { buffer = args.buf })
          vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, { buffer = args.buf })
          -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = args.buf })
          -- this is a key map to taggle virtual_text. Needs to read if it is currently true or false
          -- vim.keymap.set('n', 'ltd', function ()
          --
          -- end, { buffer = args.buf })

          -- prevent loading LSP for minified VBT files
          local buf_info = vim.fn.getbufinfo(args.buf)
          local buf_name = buf_info[1].name
          local exclude_pattern = {
            "assets/global.vbt.js",
            "assets/global.vbt.css"
          }
          for _,name in ipairs(exclude_pattern) do
            if string.match(buf_name, name) then
              vim.cmd "LspStop"
            end
          end
        end,
      })
    end
  },

  {
    'dense-analysis/ale',
    config = function()
      -- Configuration goes here.
      local g = vim.g

      g.ale_ruby_rubocop_auto_correct_all = 1

      g.ale_linters = {
        ruby = {'rubocop', 'ruby'},
        lua = {'lua_language_server'},
        liquid = 'all'
      }
    end
  }
}
