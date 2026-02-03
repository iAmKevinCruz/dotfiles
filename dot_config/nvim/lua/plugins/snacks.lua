-- creates a `:Picker` command to open the picker selector
vim.api.nvim_create_user_command('Picker', function() Snacks.picker() end, {})

-- LSP rename on mini.files file rename
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesActionRename",
  callback = function(event)
    Snacks.rename.on_rename_file(event.data.from, event.data.to)
  end,
})

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    notifier = {
      enabled = false,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    scroll = {
      animate = {
        duration = { step = 15, total = 100 },
        easing = "linear",
      },
      -- faster animation when repeating scroll after delay
      animate_repeat = {
        delay = 100, -- delay in ms before using the repeat animation
        duration = { step = 5, total = 50 },
        easing = "linear",
      },
      -- what buffers to animate
      filter = function(buf)
        return vim.g.snacks_scroll ~= false and vim.b[buf].snacks_scroll ~= false and vim.bo[buf].buftype ~= "terminal"
      end,
    },
    words = { enabled = true },
    ---@class snacks.animate.Config
    ---@field easing? snacks.animate.easing|snacks.animate.easing.Fn
    animate = {
      ---@type snacks.animate.Duration|number
      duration = 20, -- ms per step
      easing = "linear",
      fps = 60, -- frames per second. Global setting for all animations
    },
    styles = {
      notification = {
        wo = { wrap = true } -- Wrap notifications
      }
    },
    lazygit = {
      -- automatically configure lazygit to use the current colorscheme
      -- and integrate edit with the current neovim instance
      configure = true,
      -- extra configuration for lazygit that will be merged with the default
      -- snacks does NOT have a full yaml parser, so if you need `"test"` to appear with the quotes
      -- you need to double quote it: `"\"test\""`
      config = {
        os = {
          -- editPreset = "nvim-remote"
          -- this  is from my lazygitconfig. It allowws for buffers to be opened in the current vim instance  in a split. The only problem when using the `e` command in the snacks.lazygit is that the LG window does not close. After I close it with `<leader>GG`, then try to open it again, it opens partly off screen. Then after another close/open cycle, it opens properly.
          edit = "nvr -cc vsplit --remote-wait +'set bufhidden=wipe' {{filename}}" 
        },
        gui = { nerdFontsVersion = "3" },
      },
      theme_path = vim.fs.normalize(vim.fn.stdpath("cache") .. "/lazygit-theme.yml"),
      -- Theme for lazygit
      theme = {
        [241]                      = { fg = "Special" },
        activeBorderColor          = { fg = "MatchParen", bold = true },
        cherryPickedCommitBgColor  = { fg = "Identifier" },
        cherryPickedCommitFgColor  = { fg = "Function" },
        defaultFgColor             = { fg = "Normal" },
        inactiveBorderColor        = { fg = "FloatBorder" },
        optionsTextColor           = { fg = "Function" },
        searchingActiveBorderColor = { fg = "MatchParen", bold = true },
        selectedLineBgColor        = { bg = "Visual" }, -- set to `default` to have no background colour
        unstagedChangesColor       = { fg = "DiagnosticError" },
      },
      win = {
        style = "lazygit",
      },
    },
    ---@class snacks.picker.Config
    ---@field source? string source name and config to use
    ---@field pattern? string|fun(picker:snacks.Picker):string pattern used to filter items by the matcher
    ---@field search? string|fun(picker:snacks.Picker):string search string used by finders
    ---@field cwd? string current working directory
    ---@field live? boolean when true, typing will trigger live searches
    ---@field limit? number when set, the finder will stop after finding this number of items. useful for live searches
    ---@field ui_select? boolean set `vim.ui.select` to a snacks picker
    --- Source definition
    ---@field items? snacks.picker.finder.Item[] items to show instead of using a finder
    ---@field format? snacks.picker.format|string format function or preset
    ---@field finder? snacks.picker.finder|string finder function or preset
    ---@field preview? snacks.picker.preview|string preview function or preset
    ---@field matcher? snacks.picker.matcher.Config matcher config
    ---@field sort? snacks.picker.sort|snacks.picker.sort.Config sort function or config
    --- UI
    ---@field win? snacks.picker.win.Config
    ---@field layout? snacks.picker.layout.Config|string|{}|fun(source:string):(snacks.picker.layout.Config|string)
    ---@field icons? snacks.picker.icons
    ---@field prompt? string prompt text / icon
    --- Preset options
    ---@field previewers? snacks.picker.preview.Config
    ---@field sources? snacks.picker.sources.Config|{}
    ---@field layouts? table<string, snacks.picker.layout.Config>
    --- Actions
    ---@field actions? table<string, snacks.picker.Action.spec> actions used by keymaps
    ---@field confirm? snacks.picker.Action.spec shortcut for confirm action
    ---@field auto_confirm? boolean automatically confirm if there is only one item
    ---@field main? snacks.picker.main.Config main editor window config
    ---@field on_change? fun(picker:snacks.Picker, item:snacks.picker.Item) called when the cursor changes
    ---@field on_show? fun(picker:snacks.Picker) called when the picker is shown
    picker = {
      prompt = " ",
      sources = {},
      layout = {
        cycle = true,
        --- Use the default layout or vertical if the window is too narrow
        preset = function()
          return vim.o.columns >= 120 and "default" or "vertical"
        end,
      },
      ui_select = true, -- replace `vim.ui.select` with the snacks picker
      previewers = {
        file = {
          max_size = 1024 * 1024, -- 1MB
          max_line_length = 500,
        },
      },
      win = {
        -- input window
        input = {
          keys = {
            ["<Esc>"] = "close",
            -- to close the picker on ESC instead of going to normal mode,
            -- add the following keymap to your config
            -- ["<Esc>"] = { "close", mode = { "n", "i" } },
            ["<c-c>"] = { "close", mode = { "n", "i" } },
            ["<CR>"] = {"confirm", mode = {"n", "i"}},
            ["G"] = "list_bottom",
            ["gg"] = "list_top",
            ["j"] = "list_down",
            ["k"] = "list_up",
            ["/"] = "toggle_focus",
            ["q"] = "close",
            ["?"] = "toggle_help",
            ["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
            ["<a-P>"] = { "toggle_preview", mode = { "i", "n" } },
            ["<c-b>"] = { "cycle_win", mode = { "i", "n" } },
            ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
            ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
            ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
            ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },
            ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },
            ["<S-Right>"] = { "select_and_next", mode = { "i", "n" } },
            ["<S-Left>"] = { "select_and_prev", mode = { "i", "n" } },
            ["<Down>"] = { "list_down", mode = { "i", "n" } },
            ["<Up>"] = { "list_up", mode = { "i", "n" } },
            ["<c-j>"] = { "list_down", mode = { "i", "n" } },
            ["<c-k>"] = { "list_up", mode = { "i", "n" } },
            ["<c-n>"] = { "list_down", mode = { "i", "n" } },
            ["<c-p>"] = { "list_up", mode = { "i", "n" } },
            ["<S-Up>"] = { "preview_scroll_up", mode = { "i", "n" } },
            ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
            ["<S-Down>"] = { "preview_scroll_down", mode = { "i", "n" } },
            ["<a-I>"] = { "toggle_live", mode = { "i", "n" } },
            ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
            ["<ScrollWheelDown>"] = { "list_scroll_wheel_down", mode = { "i", "n" } },
            ["<ScrollWheelUp>"] = { "list_scroll_wheel_up", mode = { "i", "n" } },
            ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
            ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
            -- ["<c-q>"] = {
            --   function()
            --     print("hi there")
            --   end,
            --   mode = { "i", "n" }
            -- },
            ["<c-q>"] = { "qflist", mode = { "i", "n" } },
            ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
            ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },
          },
          b = {
            minipairs_disable = true,
          },
        },
        -- result list window
        list = {
          keys = {
            ["<CR>"] = "confirm",
            ["<C-c>"] = "close",
            ["gg"] = "list_top",
            ["G"] = "list_bottom",
            ["i"] = "focus_input",
            ["j"] = "list_down",
            ["k"] = "list_up",
            ["q"] = "close",
            ["<Tab>"] = "select_and_next",
            ["<S-Tab>"] = "select_and_prev",
            ["<S-Right>"] = "select_and_next",
            ["<S-Left>"] = "select_and_prev",
            ["<Down>"] = "list_down",
            ["<Up>"] = "list_up",
            ["<c-d>"] = "list_scroll_down",
            ["<c-u>"] = "list_scroll_up",
            ["zt"] = "list_scroll_top",
            ["zb"] = "list_scroll_bottom",
            ["zz"] = "list_scroll_center",
            ["/"] = "toggle_focus",
            ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
            ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
            ["<S-Down>"] = "preview_scroll_down",
            ["<S-Up>"] = "preview_scroll_up",
            ["<c-v>"] = "edit_vsplit",
            ["<c-s>"] = "edit_split",
            ["<c-j>"] = "list_down",
            ["<c-k>"] = "list_up",
            ["<c-n>"] = "list_down",
            ["<c-p>"] = "list_up",
            ["<c-b>"] = "cycle_win",
            ["<Esc>"] = "close",
          },
        },
        -- preview window
        preview = {
          minimal = false,
          wo = {
            cursorline = false,
            colorcolumn = "",
          },
          keys = {
            ["<Esc>"] = "close",
            ["<c-c>"] = "close",
            ["q"] = "close",
            ["i"] = "focus_input",
            ["<ScrollWheelDown>"] = "list_scroll_wheel_down",
            ["<ScrollWheelUp>"] = "list_scroll_wheel_up",
            ["<c-b>"] = "cycle_win",
            ["<a-m>"] = "toggle_maximize",
          },
        },
      },
      ---@class snacks.picker.icons
      icons = {
        indent = {
          vertical    = "│ ",
          middle = "├╴",
          last   = "└╴",
        },
        ui = {
          live        = "󰐰 ",
          selected    = "● ",
          -- selected = " ",
        },
        git = {
          commit = "󰜘 ",
        },
        diagnostics = {
          Error = " ",
          Warn  = " ",
          Hint  = " ",
          Info  = " ",
        },
        kinds = {
          Array         = " ",
          Boolean       = "󰨙 ",
          Class         = " ",
          Color         = " ",
          Control       = " ",
          Collapsed     = " ",
          Constant      = "󰏿 ",
          Constructor   = " ",
          Copilot       = " ",
          Enum          = " ",
          EnumMember    = " ",
          Event         = " ",
          Field         = " ",
          File          = " ",
          Folder        = " ",
          Function      = "󰊕 ",
          Interface     = " ",
          Key           = " ",
          Keyword       = " ",
          Method        = "󰊕 ",
          Module        = " ",
          Namespace     = "󰦮 ",
          Null          = " ",
          Number        = "󰎠 ",
          Object        = " ",
          Operator      = " ",
          Package       = " ",
          Property      = " ",
          Reference     = " ",
          Snippet       = "󱄽 ",
          String        = " ",
          Struct        = "󰆼 ",
          Text          = " ",
          TypeParameter = " ",
          Unit          = " ",
          Uknown        = " ",
          Value         = " ",
          Variable      = "󰀫 ",
        },
      },
    },
  },
  keys = {
    -- START picker keys
    { "<leader>b", function() Snacks.picker.buffers({
      ---@class snacks.picker.buffers.Config: snacks.picker.Config
      ---@field hidden? boolean show hidden buffers (unlisted)
      ---@field unloaded? boolean show loaded buffers
      ---@field current? boolean show current buffer
      ---@field nofile? boolean show `buftype=nofile` buffers
      ---@field sort_lastused? boolean sort by last used
      ---@field filter? snacks.picker.filter.Config
      finder = "buffers",
      format = "buffer",
      hidden = false,
      unloaded = true,
      current = false,
      sort_lastused = true,
    }) end, desc = "Buffers" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
    { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git Log" },
    -- { "<leader>/", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    { "<leader>/", function() Snacks.picker.lines({
      finder = "lines",
      format = "lines",
      layout = {
        preview = "main",
        preset = "ivy",
      },
      jump = { match = true },
      main = { current = true },
      on_show = function(picker)
        local cursor = vim.api.nvim_win_get_cursor(picker.main)
        local info = vim.api.nvim_win_call(picker.main, vim.fn.winsaveview)
        picker.list:view(cursor[1], info.topline)
        picker:show_preview()
      end,
      sort = { fields = { "score:desc", "idx" } }
    }) end, desc = "Buffer Lines" },
    { "<leader>fw", function() Snacks.picker.grep() end, desc = "Grep" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Visual selection", mode = { "x" } },
    { "<leader>fW", function() Snacks.picker.grep_word() end, desc = "Word under cursor", mode = { "n" } },
    { "<leader>fj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<leader>fm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>fr", function() Snacks.picker.resume() end, desc = "Resume" },
    { "<leader>fq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Quickfix List" },
    { "<leader>fM", function() Snacks.picker.man() end, desc = "Quickfix List" },
    { "<leader>fd", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
    { "<leader>fn", function() Snacks.picker.notifications() end, desc = "View notifications" },
    { "<leader>fo", function() Snacks.picker.lsp_symbols() end, desc = "Find LSP Symbols" },
    { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition" },
    { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
    -- END picker keys
     { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<leader>Bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>GG", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
    { "<leader>GF", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
    { "<leader>GL", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
    { "<leader>cR", function() Snacks.rename() end, desc = "Rename File" },
    { "<c-/>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
    { "<c-_>",      function() Snacks.terminal() end, desc = "which_key_ignore" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference" },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference" },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
      end,
    })
  end,
}
