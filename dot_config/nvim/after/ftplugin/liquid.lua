-- Prettier format current liquid buffer
-- vim.keymap.set('n', '<leader>ll', ':%!npx prettier --stdin-filepath %<cr>', { desc = 'Shopify Prettier current buffer. Needs prettier and Shopify prettier installed first.', silent = false})
vim.keymap.set('n', '<leader>ll', '<cmd>ALEFix prettier<cr>', { desc = 'Shopify Prettier current buffer. Needs prettier and Shopify prettier installed first.', silent = false})
