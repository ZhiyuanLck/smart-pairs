local M = {}
local fmt = string.format
local rep = string.rep
local api = vim.api
local fn = vim.fn

--- delete lines of [idx1, idx2), idx1 and idx2 is 0-based index
---@param idx1 number
---@param idx2 number, if nil delete line idx1
function M.del_lines(idx1, idx2)
  if idx2 == nil then
    vim.cmd(fmt('silent %dd', idx1 + 1))
  else
    vim.cmd(fmt('silent %d,%dd', idx1 + 1, idx2))
  end
end

--- get line whose index is idx (0-based)
---@return string: line
function M.get_line(idx)
  return api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
end

--- set line whose index is idx (0-based)
function M.set_line(idx, line)
  api.nvim_buf_set_lines(0, idx, idx + 1, true, {line})
end

--- get the col index
---@param col number or string
---@return number
local function get_col(col)
  if type(col) == 'string' then
    return fn.strlen(col) - 1
  end
  return col < 0 and fn.col('.') - 1 or col
end

--- get the row index
---@param row number
---@return number
local function get_row(row)
  return row < 0 and fn.line('.') - 1 or row
end

--- get the replace text
---@param text string or table
---@return table
local function get_text(text)
  if type(text) == 'string' then return {text} end
  return text
end

--- wrapper of nvim_buf_set_text
---@param start_row number
---@param start_col number or string
---@param end_row number
---@param end_col number or string
---@param text table or string
function M.set_text(start_row, start_col, end_row, end_col, text)
  api.nvim_buf_set_text(0, get_row(start_row), get_col(start_col), get_row(end_row), get_col(end_col), get_text(text))
end

--- insert text at the given position
---@param row number: 0-based line index
---@param col number or string: 0-based col index or string to count the length
---@param text string
function M.insert(row, col, text)
  row = get_row(row)
  col = get_col(col)
  api.nvim_buf_set_text(0, row, col, row, col, get_text(text))
end

--- Advance current cursor by str
---@param str string
function M.advance_cursor(str)
  local pos = api.nvim_win_get_cursor(0)
  pos[2] = pos[2] + fn.strlen(str)
  api.nvim_win_set_cursor(0, pos)
end

function M.feedkeys(keys, mode)
  mode = mode or 'n'
  keys = api.nvim_replace_termcodes(keys, true, false, true)
  api.nvim_feedkeys(keys, mode, true)
end

--- get the indent level of str in vim
---@param str string
---@return number: indent level
function M.get_indent_level(str)
  local indent = fn.strdisplaywidth("\t")
  local cur_indent = fn.strdisplaywidth(str:match('^%s*'))
  return (cur_indent - cur_indent % indent) / indent
end

---@param line number, line number
---@param col number or string
---  number: column number
---  string: set the cursor column at the end of string
function M.set_cursor(line, col)
  line = line == 0 and fn.line('.') or line
  if type(col) == 'string' then col = fn.strlen(col) end
  api.nvim_win_set_cursor(0, {line, col})
end

--- merge two opts table
function M.merge(opts1, opts2)
  if not opts2 then return end
  for k, v in pairs(opts2) do
    if type(v) == 'table' and opts1[k] then
      M.merge(opts1[k], opts2[k])
    else
      opts1[k] = v
    end
  end
end

---@return left part of line separated by cursor
function M.get_cursor_l()
  local col = fn.col('.') - 1
  local line = api.nvim_get_current_line()
  return fn.strpart(line, 0, col)
end

---@return right part of line separated by cursor
function M.get_cursor_r()
  local col = fn.col('.') - 1
  local line = api.nvim_get_current_line()
  return fn.strpart(line, col)
end

---@return left and right part of line separated by cursor
function M.get_cursor_lr()
  local col = fn.col('.') - 1
  local line = api.nvim_get_current_line()
  local left_line = fn.strpart(line, 0, col)
  local right_line = fn.strpart(line, col)
  return left_line, right_line
end

--- escape lua patterns
function M.escape(str)
  local e = {'%', '(', ')', '[', '.', '*', '+', '-', '?', '^', '$'}
  for _, ch in ipairs(e) do
    str = str:gsub('%' .. ch, '%%%' .. ch)
  end
  return str
end

--- remove possible trailing spaces
---@param idx number: 0-based line index
function M.remove_trailing_spaces(idx)
  idx = idx or fn.line('.') - 1
  local line = api.nvim_get_current_line()
  local m = line:match('(.-)%s+$')
  if m then
    api.nvim_buf_set_text(0, idx, fn.strlen(m), idx, fn.strlen(line), {''})
  end
end

--- count the number of left brackets with remove of corresponding pairs
---@param str string
---@param left string: left bracket
---@param right string: right bracket
---@param opts table: options
---@return table
---@field m number: absolute counts of left bracket
---@field n number: relative counts of left bracket
function M.count(str, left, right)
  local cur = 1
  local m = 0
  local n = 0
  local ln, rn, sn = #left, #right, #str
  repeat
    if str:sub(cur, cur + ln - 1) == left then
      m = m + 1
      n = n + 1
      cur = cur + #left
    elseif str:sub(cur, cur + rn - 1) == right then
      m = m - 1
      if n > 0 then n = n - 1 end
      cur = cur + #right
    else
      cur = cur + 1
    end
  until (cur > sn)
  return {m = m, n = n}
end

--- count occurrences of str in line, ignore escaped ones
---@param line string: line to be searched
---@param str string: pattern
---@return number
function M.match_count(line, str)
  local n = 0
  for _ in line:gmatch(str) do n = n + 1 end
  return n
end

--- if opt is boolean return opt, then is a function
function M.enable(opt)
  if opt == nil then return false end
  if type(opt) == 'boolean' then return opt end
  if type(opt) == 'function' then return opt() end
  error('enable option should be a boolean or function')
end

function M.call(func, ...)
  if not func then return end
  return func(...)
end

--- get lua escaped triplet pair
function M.triplet(left)
  return rep(M.escape(left), 3)
end

--- get indentation of line or by the level
function M.get_indent(line)
  if type(line) == 'string' then
    return line:match('^%s*')
  end
  if type(line) == 'number' then
    local one = vim.bo.et and string.rep(' ', vim.bo.sw) or '\t'
    return string.rep(one, line)
  end
  error('param #1 should be a string or number')
end

local function warn(msg)
  vim.cmd(fmt([[
    echohl WarningMsg
    echom "smart-pair warning: %s"
    echohl None
  ]], msg))
end

--- warn outdated options
function M.check_opts(opts)

  local get_opt = function(opt)
    local ret = opts
    for key in vim.gsplit(opt, '%.') do
      if not ret then return nil end
      ret = ret[key]
    end
    return ret
  end

  local opt_warn = function(opt, alt)
    if not get_opt(opt) then return end
    if alt then
      warn(fmt("option '%s' has been removed, use '%s' instead", opt, alt))
    else
      warn(fmt("option '%s' has been removed", opt))
    end
  end

  local change_warn = function(opt)
    if not get_opt(opt) then return end
    warn(fmt("option '%s' has been removed and transferred to another new option, please check the document for details", opt))
  end

  --- 2022/2/11
  opt_warn('delete.empty_line.bracket')
  opt_warn('delete.empty_line.enable_end')
  --- 2022/2/12
  opt_warn('delete.empty_line.enable', 'delete.empty_line.enable_mapping')
  opt_warn('enable_space', 'space.enable_mapping')
  opt_warn('enable_enter', 'enter.enable_mapping')
  --- 2022/2/13
  opt_warn('delete.empty_line.trigger_indent_level.text')
  opt_warn('delete.empty_line.trigger_indent_level.bracket', 'delete.empty_line.trigger_indent_level')
  opt_warn('delete.empty_line.enable_start', 'delete.empty_line.enable_sub.start')
  opt_warn('delete.empty_line.enable_bracket', 'delete.empty_line.enable_sub.inside_brackets')
  opt_warn('delete.empty_line.enable_multiline', 'delete.empty_line.enable_sub.text_multi_line')
  opt_warn('delete.empty_line.enable_oneline', 'delete.empty_line.enable_sub.text_delete_to_prev_indent')
  --- 2022/2/18
  opt_warn('delete.autojump_strategy.unbalanced')
  local o = get_opt('delete.autojump_strategy.unbalanced')
  if o == 'loose_right' then
    warn(fmt("value '%s' of option '%s' has been removed", 'loose_right', 'delete.autojump_strategy.unbalanced'))
  end
  --- 2022/2/19
  change_warn('delete.empty_line.enable_sub')
  change_warn('delete.empty_line.trigger_indent_level')
  opt_warn('enter.indent', 'indent')
end

return M
