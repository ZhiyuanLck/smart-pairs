local M = {}
local fmt = string.format

-- delete lines of [idx1, idx2), idx1 and idx2 is 0-based index
-- @param idx1 number
-- @param idx2 number, if nil delete line idx1
function M.del_lines(idx1, idx2)
  if idx2 == nil then
    vim.cmd(fmt('silent %dd', idx1 + 1))
  else
    vim.cmd(fmt('silent %d,%dd', idx1 + 1, idx2))
  end
end

-- get line whose index is idx (0-based)
-- @return string: line
function M.get_line(idx)
  return vim.api.nvim_buf_get_lines(0, idx, idx + 1, true)[1]
end

-- set line whose index is idx (0-based)
function M.set_line(idx, line)
  vim.api.nvim_buf_set_lines(0, idx, idx + 1, true, {line})
end

function M.feedkeys(keys)
  keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(keys, 'n', true)
end

-- get the indent level of str in vim
-- @param str string
-- @return number: indent level
function M.get_indent_level(str)
  -- wrong value in py, may need manually calculate
  local indent = vim.api.nvim_strwidth('\\t')
  local pre_space = str:match('^%s*'):gsub('\t', '\\t')
  local cur_indent = vim.api.nvim_strwidth(pre_space)
  return (cur_indent - cur_indent % indent) / indent
end

-- @param line number, line number
-- @param col number or string
--   number: column number
--   string: set the cursor column at the end of string
function M.set_cursor(line, col)
  line = line == 0 and vim.fn.line('.') or line
  if type(col) == 'string' then col = vim.fn.strlen(col) end
  vim.api.nvim_win_set_cursor(0, {line, col})
end

-- merge two opts table
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

-- @return left part of line separated by cursor
function M.get_cursor_l()
  local col = vim.fn.col('.') - 1
  local line = vim.api.nvim_get_current_line()
  return vim.fn.strpart(line, 0, col)
end

-- @return left and right part of line separated by cursor
function M.get_cursor_lr()
  local col = vim.fn.col('.') - 1
  local line = vim.api.nvim_get_current_line()
  local left_line = vim.fn.strpart(line, 0, col)
  local right_line = vim.fn.strpart(line, col)
  return left_line, right_line
end

-- escape lua patterns
function M.escape(str)
  local e = {'%', '(', ')', '[', '.', '*', '+', '-', '?', '^', '$'}
  for _, ch in ipairs(e) do
    str = str:gsub('%' .. ch, '%%%' .. ch)
  end
  return str
end

-- count the number of left brackets with remove of corresponding pairs
-- @param str string
-- @param left string: left bracket
-- @param right string: right bracket
function M.count(str, left, right)
  local cur = 1
  local n = 0
  local ln, rn, sn = #left, #right, #str
  repeat
    if str:sub(cur, cur + ln - 1) == left then
      n = n + 1
      cur = cur + #left
    elseif str:sub(cur, cur + rn - 1) == right then
      n = n > 0 and n - 1 or n
      cur = cur + #right
    else
      cur = cur + 1
    end
  until (cur > sn)
  return n
end

local warn = function(msg)
  vim.cmd(fmt([[
    echohl WarningMsg
    echom "smart-pair warning: %s"
    echohl None
  ]], msg))
end

-- warn outdated options
function M.check_outdated(opts)
  if opts.delete.empty_line.bracket then
    warn("option delete.empty_line.bracket is outdated")
  end
  if opts.delete.empty_line.enable_end then
    warn("option delete.empty_line.enable_end is outdated")
  end
end

return M
