

return {
  -- {
  --   "jcdickinson/codeium.nvim",
  --   lazy = false,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "hrsh7th/nvim-cmp",
  --   },
  --   config = function()
  --     require("codeium").setup({
  --     })
  --   end
  -- },

  -- {
  --   "supermaven-inc/supermaven-nvim",
  --   config = function()
  --     require("supermaven-nvim").setup({ disable_inline_completion = true, })
  --
  --     local suggestion = require('supermaven-nvim.completion_preview');
  --
  --     vim.keymap.set('n', '<leader>tia', function()
  --       if suggestion.disable_inline_completion then
  --         suggestion.disable_inline_completion = false
  --         print("Inline AI autocompletion ENABLED")
  --       else
  --         suggestion.disable_inline_completion = true
  --         print("Inline AI autocompletion DISABLED")
  --       end
  --     end, { desc = '[T]oggle [I]nline [A]I autocompletion' });
  --
  --     vim.keymap.set('i', '<C-t>ia', function()
  --       if suggestion.disable_inline_completion then
  --         suggestion.disable_inline_completion = false
  --         print("Inline AI autocompletion ENABLED")
  --       else
  --         suggestion.disable_inline_completion = true
  --         print("Inline AI autocompletion DISABLED")
  --       end
  --     end, { desc = '[T]oggle [I]nline [A]I autocompletion' });
  --
  --   end,
  -- },
}
