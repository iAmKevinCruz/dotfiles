--[[ local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set(
  "n", 
  "<leader>a", 
  function()
    vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
    -- or vim.lsp.buf.codeAction() if you don't want grouping.
  end,
  { silent = true, buffer = bufnr }
) ]]

-- Rustaceanvim manages rust-analyzer directly (not through lspconfig/mason).
-- The empty handler in lsp.lua ['rust_analyzer'] = function() end prevents
-- mason-lspconfig from also starting rust-analyzer (which causes duplicates).
vim.g.rustaceanvim = {
  server = {
    settings = {
      ['rust-analyzer'] = {
        -- Use clippy instead of cargo check for richer diagnostics.
        check = {
          command = 'clippy',
        },
      },
    },
  },
}

return {
  {
    'mrcjkb/rustaceanvim',
    version = '^6', -- Recommended
    ft = { 'rust' },
    lazy = false
  }
}
