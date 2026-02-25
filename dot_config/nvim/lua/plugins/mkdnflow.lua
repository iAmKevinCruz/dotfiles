
return {
  {
    'jakewvincent/mkdnflow.nvim',
    config = function()
      require('mkdnflow').setup({
        modules = {
          bib = true,
          buffers = true,
          conceal = true,
          cursor = true,
          folds = true,
          foldtext = true,
          links = true,
          lists = true,
          maps = true,
          paths = true,
          tables = true,
          to_do = true,
          yaml = false,
          cmp = false,
        }
      })
    end
  }
}
