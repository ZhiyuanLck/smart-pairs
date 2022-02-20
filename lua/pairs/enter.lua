local M = {}
local u = require('pairs.utils')
local P = require('pairs')

local function type_aux()
  local left_line, right_line = u.get_cursor_lr()
  -- remove blank spaces
  left_line = left_line:match('(.-)%s*$')
  right_line = right_line:match('^%s*(.-)%s*$')

  -- if have a right bracket just after the cursor
  local right = P:has_right_start(right_line)

  -- find the corresponding left bracket
  local linenr = vim.fn.line('.')
  local cur = linenr - 1
  local line_idx = cur
  local min_idx = cur - P.max_search_lines
  min_idx = min_idx < 0 and 0 or min_idx
  local ctn = {}
  local indent
  local left = P:has_left(left_line)
  if right then
    while (cur >= min_idx) do
      local line = cur == line_idx and u.get_cursor_l() or u.get_line(cur)
      local pair = P:has_left(line, ctn, right)
      if pair then
        indent = u.get_indent(line)
        left = pair
        break
      end
      cur = cur - 1
    end
  end
  indent = indent or u.get_indent(left_line)

  if left then
    local cur_indent = right.opts.triplet and indent or indent .. P:get_indent()
    right_line = (right and indent or cur_indent) .. right_line
    vim.api.nvim_set_current_line(left_line)
    vim.fn.append(linenr, right and {cur_indent, right_line} or right_line)
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
