local M = {}
local u = require('pairs.utils')
local P = require('pairs')

-- search up all left brackets or with specified pair
-- @param p table: optional pair
local function search_up(p)
  local cur = vim.fn.line('.') - 1
  local line_idx = cur
  local ctn = {}
  while (cur >= 0 and line_idx - cur <= P.max_search_lines) do
    local line = cur == line_idx and u.get_cursor_l() or u.get_line(cur)
    local pair = P:has_left(line, ctn, p)
    if pair then
      return {indent = u.get_indent(line), has_indent = not pair.opts.triplet, has_left = true, pair = pair}
    end
    cur = cur - 1
  end
end

local function type_aux()
  local left_line, right_line = u.get_cursor_lr()
  -- remove blank spaces
  left_line = left_line:match('(.-)%s*$')
  right_line = right_line:match('^%s*(.-)%s*$')

  local pair = P:has_right_start(right_line)

  local m = search_up(pair) or {}
  if pair then
    m.has_right = true
  elseif m.has_left then
    if m.pair.triplet then
      m.has_right = right_line:match('^' .. u.triplet(m.pair.right)) ~= nil
    else
      m.has_right = right_line:match('^' .. u.escape(m.pair.right)) ~= nil
    end
  end

  local linenr = vim.fn.line('.')

  if m.has_left then
    local cur_indent = m.has_indent and m.indent .. P:get_indent() or m.indent
    right_line = (m.has_right and m.indent or cur_indent) .. right_line
    vim.api.nvim_set_current_line(left_line)
    vim.fn.append(linenr, m.has_right and {cur_indent, right_line} or right_line)
    u.set_cursor(linenr + 1, cur_indent)
  else
    vim.api.nvim_set_current_line(left_line .. right_line)
    u.set_cursor(linenr, left_line)
    u.feedkeys('<cr>')
  end
end

function M.type()
  if not u.enable(P.enter.enable_cond) then
    return P.enter.enable_fallback() or ''
  end

  u.call(P.enter.before_hook)
  type_aux()
  u.call(P.enter.after_hook)
  return ''
end

return M
