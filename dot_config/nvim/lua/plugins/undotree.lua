-- Keymaps
vim.keymap.set('n', '<leader>utt', '<CMD>UndotreeToggle<CR>', { desc = 'Open [U]ndo [T]ree [T]oggle' })
vim.keymap.set('n', '<leader>utf', '<CMD>UndotreeFocus<CR>', { desc = 'Open [U]ndo [T]ree [F]ocus' })

return {
  {
    "mbbill/undotree",
    event = "VeryLazy",
  },
}
