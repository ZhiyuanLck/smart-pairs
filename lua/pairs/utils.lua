local M = {}
local fn = vim.fn
local api = vim.api
local fmt = string.format

--- vim warning
---@param msg string @message
function M.warn(msg)
  vim.cmd(fmt([[
    echohl WarningMsg
    echom "smart-pairs warning: %s"
    echohl None
  ]], msg:gsub('"', '\\"')))
end

--- get the type of the variable, add the extra type list
---@param var any
---@return string
local function get_type(var)
  if type(var) ~= 'table' then return type(var) end
  local i = 0
  for _ in pairs(var) do
      i = i + 1
      if var[i] == nil then return 'table' end
  end
  return 'list'
end

--- check the type of variable
---@param var any @variable of any type
---@param expect_type string @expected type of the variable
---@param allow_nil boolean @allow the variable to be nil, default false
function M.check_type(var, expect_type, allow_nil)
  local var_type = get_type(var)
  if (not allow_nil or var ~= nil) and var_type ~= expect_type then
    error(fmt('expect type %s, but get type %s', expect_type, var_type))
  end
end

--- get (0, 0) based (line, col) cursor position
---@return number[]
function M.get_cursor()
  local cursor = api.nvim_win_get_cursor(0)
  cursor[1] = cursor[1] - 1
  return cursor
end

--- set the cursor position
---@param line number @0-based line index, -1 denotes the current line
---@param col number | string @0-based column index or the text from which the column index is caculated
function M.set_cursor(line, col)
  line = line == -1 and fn.line('.') - 1 or line
  if type(col) == 'string' then col = fn.strlen(col) end
  api.nvim_win_set_cursor(0, {line + 1, col})
end

--- set the default value of key of tbl if the value is nil
---@param tbl table
---@param key string
---@param default any
function M.set_default_val(tbl, key, default)
  if tbl[key] == nil then tbl[key] = default end
end

--- return a default value if a is nil
---@param a any
---@param b any
---@return any
function M.if_nil(a, b)
  if a == nil then return b end
  return a
end

--- escape special lua chars
---@param str string
---@return string
function M.escape(str)
  local e = {'%', '(', ')', '[', '.', '*', '+', '-', '?', '^', '$'}
  for _, ch in ipairs(e) do
    str = str:gsub('%' .. ch, '%%%' .. ch)
  end
  return str
end

return M
