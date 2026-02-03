local uv = vim.loop
local path_sep = uv.os_uname().version:match("Windows") and "\\" or "/"
local fn, api, cmd, diag, o, g, tbl_contains, bo, keymap =
	vim.fn, vim.api, vim.cmd, vim.diagnostic, vim.o, vim.g, vim.tbl_contains, vim.bo, vim.keymap

local M = {}

--- assert that the given argument is in fact of the correct type.
---
--- Thanks!!
--- https://github.com/lunarmodules/Penlight
---
-- @param n argument index
-- @param val the value
-- @param tp the type
-- @param verify an optional verification function
-- @param msg an optional custom message
-- @param lev optional stack position for trace, default 2
-- @return the validated value
-- @raise if `val` is not the correct type
-- @usage
-- local param1 = assert_arg(1,"hello",'table')  --> error: argument 1 expected a 'table', got a 'string'
-- local param4 = assert_arg(4,'!@#$%^&*','string',path.isdir,'not a directory')
--      --> error: argument 4: '!@#$%^&*' not a directory
function M.assert_arg(n, val, tp, verify, msg, lev)
	if type(val) ~= tp then
		error(("argument %d expected a '%s', got a '%s'"):format(n, tp, type(val)), lev or 2)
	end
	if verify and not verify(val) then
		error(("argument %d: '%s' %s"):format(n, val, msg), lev or 2)
	end
	return val
end

--- Thanks!!
--- https://github.com/lunarmodules/Penlight
local function assert_string(n, s)
	M.assert_arg(n, s, "string")
end

--- Check if a plugin is defined in lazy. Useful with lazy loading when a plugin is not necessarily loaded yet
---@param plugin string # The plugin to search for
---@return boolean available # Whether the plugin is available
function M.is_available(plugin)
	local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
	return lazy_config_avail and lazy_config.plugins[plugin] ~= nil
end

--- Call function if a condition is met
---@param func function # The function to run
---@param condition boolean # Wether to run the function or not
---@return any|nil result # The result of the function running or nil
function M.conditional_func(func, condition, ...)
	if condition and type(func) == "function" then
		return func(...)
	end
end

--- Check if a list of strings has a value
--- @param options string[] # The list of strings to check
--- @param val string # The value to check
function M.has_value(options, val)
	for _, value in ipairs(options) do
		if value == val then
			return true
		end
	end

	return false
end

--- Checks whether a given path exists and is a directory
--- Thanks LunarVim!
--@param path (string) path to check
--@returns (bool)
function M.is_directory(path)
	local stat = uv.fs_stat(path)
	return stat and stat.type == "directory" or false
end

--- Thanks LunarVim!
---Join path segments that were passed as input
---@return string
function M.join_paths(...)
	local result = table.concat({ ... }, path_sep)
	return result
end

local ellipsis = "..."
local n_ellipsis = #ellipsis

--- Return a shortened version of a string.
--- Fits string within w characters. Removed characters are marked with ellipsis.
---
--- Thanks!!
--- https://github.com/lunarmodules/Penlight
---
-- @string s the string
-- @int w the maxinum size allowed
-- @bool tail true if we want to show the end of the string (head otherwise)
-- @usage ('1234567890'):shorten(8) == '12345...'
-- @usage ('1234567890'):shorten(8, true) == '...67890'
-- @usage ('1234567890'):shorten(20) == '1234567890'
function M.shorten(s, w, tail)
	assert_string(1, s)
	if #s > w then
		if w < n_ellipsis then
			return ellipsis:sub(1, w)
		end
		if tail then
			local i = #s - w + 1 + n_ellipsis
			return ellipsis .. s:sub(i)
		else
			return s:sub(1, w - n_ellipsis) .. ellipsis
		end
	end
	return s
end

--- Split a string into a Table using a pattern
--- @param pString string # The string to split
--- @param pPattern string # The pattern to split the string
--- @return table # The table of split strings
function M.split(pString, pPattern)
   local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pPattern
   local last_end = 1
   local s, e, cap = pString:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
     table.insert(Table,cap)
      end
      last_end = e+1
      s, e, cap = pString:find(fpat, last_end)
   end
   if last_end <= #pString then
      cap = pString:sub(last_end)
      table.insert(Table, cap)
   end
   return Table
end

--- Get the branch name with git-dir and worktree support
--- @param worktree table<string, string>|nil # a table specifying the `toplevel` and `gitdir` of a worktree
--- @param as_path string|nil # execute the git command from specific path
--- @return string branch # The branch name
function M.branch_name(worktree, as_path)
	local branch
	if worktree then
		branch = vim.fn.system(
			("git --git-dir=%s --work-tree=%s branch --show-current 2> /dev/null | tr -d '\n'"):format(
				worktree.gitdir,
				worktree.toplevel
			)
		)
	elseif as_path then
		branch = vim.fn.system(("git -C %s branch --show-current 2> /dev/null | tr -d '\n'"):format(as_path))
	else
		branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
	end
	if branch ~= "" then
		return branch
	else
		return ""
	end
end


-- get the the git project root directory of a file or current file
function M.get_git_root_directory(current_file)
    -- Use the directory of the current file if no file is provided
    if not current_file or current_file == "" then
        current_file = vim.fn.expand("%:p")
    end

    local file_dir = vim.fn.fnamemodify(current_file, ":p:h")

    -- Run the git command and trim the output
    local git_command = "git -C " .. vim.fn.escape(file_dir, " ") .. " rev-parse --show-toplevel"
    local git_root = vim.fn.system(git_command)
    git_root = vim.fn.trim(git_root)

    -- Check for error in command execution or empty output
    if vim.v.shell_error ~= 0 or git_root == '' then
        return nil -- or return an appropriate value or message
    end

    return git_root
end

M.export_quickfix_to_markdown = function(filename)
  local qf_list = vim.fn.getqflist()
  local lines = {"# Quickfix List\n"}
  
  for _, item in ipairs(qf_list) do
    local bufnr = item.bufnr
    local filename = vim.fn.bufname(bufnr)
    local lnum = item.lnum
    local col = item.col
    local text = item.text:gsub("|", "\\|"):gsub("\n", " ")
    
    table.insert(lines, string.format("- **%s**:%d:%d - %s", filename, lnum, col, text))
  end
  
  local file = io.open(filename, "w")
  if file then
    file:write(table.concat(lines, "\n"))
    file:close()
    print("Quickfix list exported to " .. filename)
  else
    print("Failed to open file for writing: " .. filename)
  end
  
end

return M

