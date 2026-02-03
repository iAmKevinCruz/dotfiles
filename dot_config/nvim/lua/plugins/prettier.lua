-- Keymaps

return {
  {
    "MunifTanjim/prettier.nvim",
    event = "VeryLazy",
    config = function()
      require("prettier").setup({
        bin = 'prettierd',
        filetypes = {
          "liquid",
          "css",
          "graphql",
          "html",
          "javascript",
          "javascriptreact",
          "json",
          "less",
          "markdown",
          "scss",
          "typescript",
          "typescriptreact",
          "yaml",
        },
      })
    end
  },
}
