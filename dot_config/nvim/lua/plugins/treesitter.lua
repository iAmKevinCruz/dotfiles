-- nvim-treesitter on the `main` branch (the rewrite). Differences vs the old
-- master API: no `nvim-treesitter.configs`, no highlight/indent modules. Instead:
--   * parsers installed via require('nvim-treesitter').install()
--   * highlighting started per-buffer with vim.treesitter.start() in a FileType
--     autocmd
--   * indentation is the experimental indentexpr
-- Requires the tree-sitter CLI (>=0.26.1, at ~/.local/bin) + a C compiler.

-- Parsers to keep installed. templ + markdown are built-in on main now, so the
-- old custom-parser registration block is gone.
local ensure = {
  "vimdoc", "javascript", "typescript", "c", "lua", "rust",
  "jsdoc", "bash", "liquid", "templ", "markdown", "markdown_inline",
}

return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    lazy = false,
    config = function()
      require('treesitter-context').setup {
        enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
        multiwindow = false, -- Enable multiwindow support.
        max_lines = 3, -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
        separator = nil,
        zindex = 20, -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
      }
    end
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      -- ensure_installed equivalent: async install, skips already-present parsers.
      require("nvim-treesitter").install(ensure)

      -- Skip treesitter for very large files and specific minified VBT assets
      -- (parity with the old `highlight.disable` function).
      local function should_skip(buf)
        local name = vim.api.nvim_buf_get_name(buf)
        local ok, stats = pcall(vim.uv.fs_stat, name)
        if ok and stats and stats.size > 100 * 1024 then -- 100 KB
          return true
        end
        for _, pat in ipairs({ "assets/global%.vbt%.js", "assets/global%.vbt%.css" }) do
          if name:match(pat) then
            return true
          end
        end
        return false
      end

      -- main has no highlight module: start TS highlighting per buffer on FileType.
      vim.api.nvim_create_autocmd("FileType", {
        desc = "Start treesitter highlighting + indent",
        callback = function(args)
          local buf = args.buf
          if should_skip(buf) then
            return
          end
          -- No parser for this filetype -> start() errors; guard so it's a no-op.
          if not pcall(vim.treesitter.start, buf) then
            return
          end
          -- Experimental TS-based indentation.
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          -- Keep legacy vim-regex highlighting alongside TS for markdown
          -- (parity with old additional_vim_regex_highlighting = { "markdown" }).
          if vim.bo[buf].filetype == "markdown" then
            vim.bo[buf].syntax = "on"
          end
        end,
      })
    end
  }
}
